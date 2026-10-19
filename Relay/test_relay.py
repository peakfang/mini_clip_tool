import asyncio
import json
import unittest

from websockets.asyncio.client import connect
from websockets.asyncio.server import serve
from server import Relay


async def receive(socket, kind):
    async with asyncio.timeout(2):
        while True:
            packet = json.loads(await socket.recv())
            if packet["type"] == kind:
                return packet


async def enter(socket, action, name, code=""):
    await socket.send(json.dumps({"type": action, "version": 2, "name": name, "room": code}))
    return await receive(socket, "joined")


class RelayTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.relay = Relay()
        self.server = await serve(self.relay.handle, "127.0.0.1", 0, origins=[None], max_size=2048, close_timeout=1)
        self.url = f"ws://127.0.0.1:{self.server.sockets[0].getsockname()[1]}"
        self.clients = []

    async def asyncTearDown(self):
        for socket in self.clients:
            await socket.close()
        self.server.close()
        await self.server.wait_closed()

    async def client(self):
        socket = await connect(self.url, proxy=None)
        self.clients.append(socket)
        return socket

    async def test_room_signal_isolation_and_sender_identity(self):
        alice, bob, outsider = await self.client(), await self.client(), await self.client()
        room = (await enter(alice, "create", "Alice"))["room"]
        await enter(bob, "join", "Bob", room)
        await enter(outsider, "create", "Other")
        self.assertEqual(len((await receive(bob, "members"))["members"]), 2)
        await alice.send(json.dumps({"type": "ping", "index": 4, "seq": 1, "position": {"x": 0.25, "y": 0.75}, "name": "Spoofed"}))
        event = await receive(bob, "ping")
        self.assertEqual((event["index"], event["name"]), (4, "Alice"))
        self.assertEqual(event["position"], {"x": 0.25, "y": 0.75})
        self.assertNotEqual(event["sender"], "Spoofed")
        async with asyncio.timeout(0.1):
            # Drain membership updates then verify the other room gets no signal.
            await receive(outsider, "members")
        with self.assertRaises(TimeoutError):
            async with asyncio.timeout(0.15):
                await outsider.recv()

    async def test_capacity_validation_rate_limit_and_replay(self):
        host = await self.client()
        room = (await enter(host, "create", "Host"))["room"]
        for i in range(9):
            await enter(await self.client(), "join", f"Guest{i}", room)
        fifth = await self.client()
        await fifth.send(json.dumps({"type": "join", "version": 2, "name": "Fifth", "room": room}))
        self.assertIn("已满", (await receive(fifth, "error"))["message"])
        for index, seq in [(9, 1), (True, 1)]:
            await host.send(json.dumps({"type": "ping", "index": index, "seq": seq, "position": {"x": 0.5, "y": 0.5}}))
            await receive(host, "error")
        await host.send(json.dumps({"type": "ping", "index": 0, "seq": 1, "position": {"x": 0.5, "y": 0.5}}))
        await host.send(json.dumps({"type": "ping", "index": 0, "seq": 1, "position": {"x": 0.5, "y": 0.5}}))
        await receive(host, "error")
        await host.send(json.dumps({"type": "ping", "index": 1, "seq": 2, "position": {"x": 0.5, "y": 0.5}}))
        await host.send(json.dumps({"type": "ping", "index": 2, "seq": 3, "position": {"x": 0.5, "y": 0.5}}))
        await receive(host, "error")

    async def test_disconnect_members_and_rejoin(self):
        host, guest = await self.client(), await self.client()
        room = (await enter(host, "create", "Host"))["room"]
        await enter(guest, "join", "Guest", room)
        await receive(host, "members")
        await receive(host, "members")
        await guest.close()
        self.assertEqual(len((await receive(host, "members"))["members"]), 1)
        await host.close()
        replacement = await self.client()
        self.assertEqual((await enter(replacement, "join", "Back", room))["room"], room)

    async def test_bad_room_and_malformed_packet(self):
        bad = await self.client()
        await bad.send("[]")
        await receive(bad, "error")
        missing = await self.client()
        await missing.send(json.dumps({"type": "join", "version": 2, "name": "Guest", "room": "AAAAAAAA"}))
        self.assertIn("不存在", (await receive(missing, "error"))["message"])


if __name__ == "__main__":
    unittest.main()
