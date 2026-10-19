"""ClipMini ephemeral rooms. Run behind HTTPS/WSS for public access."""
import asyncio
from collections import deque
from dataclasses import dataclass, field
import json
import math
import os
import secrets
import time
import uuid

from websockets.asyncio.server import serve
from websockets.exceptions import ConnectionClosed

ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
MAX_ROOMS = 250
MAX_CLIENTS = 1000


@dataclass
class Room:
    created: float = field(default_factory=time.monotonic)
    empty_since: float | None = None
    clients: dict = field(default_factory=dict)


class Relay:
    def __init__(self):
        self.rooms = {}
        self.connections = 0

    async def send(self, socket, packet):
        try:
            await asyncio.wait_for(socket.send(json.dumps(packet, ensure_ascii=False)), 2)
        except (ConnectionClosed, TimeoutError):
            await socket.close(code=1013, reason="Connection too slow")

    async def members(self, room):
        packet = {"type": "members", "members": list(room.clients.values())}
        await asyncio.gather(*(self.send(s, packet) for s in list(room.clients)))

    async def handle(self, socket):
        if self.connections >= MAX_CLIENTS:
            await socket.close(code=1013, reason="Server full")
            return
        self.connections += 1
        room = None
        recent = deque()
        last_seq = 0
        try:
            raw = await asyncio.wait_for(socket.recv(), 10)
            message = json.loads(raw)
            if not isinstance(message, dict) or message.get("version") != 2:
                raise ValueError("版本不兼容，请更新 ClipMini")
            name = message.get("name")
            if not isinstance(name, str) or not 1 <= len(name.strip()) <= 20 or any(ord(c) < 32 for c in name):
                raise ValueError("昵称需为 1～20 个字符")
            action = message.get("type")
            if action == "create":
                if len(self.rooms) >= MAX_ROOMS:
                    raise ValueError("服务房间已满，请稍后重试")
                code = "".join(secrets.choice(ALPHABET) for _ in range(8))
                while code in self.rooms:
                    code = "".join(secrets.choice(ALPHABET) for _ in range(8))
                self.rooms[code] = Room()
            elif action == "join":
                code = message.get("room")
                if not isinstance(code, str) or len(code) != 8 or any(c not in ALPHABET for c in code):
                    raise ValueError("房间码格式不正确")
                if code not in self.rooms:
                    raise ValueError("房间不存在或已过期")
            else:
                raise ValueError("请先创建或加入房间")
            room = self.rooms[code]
            if time.monotonic() - room.created > 86400:
                raise ValueError("房间已过期，请重新创建")
            if len(room.clients) >= 10:
                raise ValueError("房间已满（最多 10 人）")
            member = {"id": str(uuid.uuid4()), "name": name.strip(), "steelCount": 0}
            room.clients[socket] = member
            room.empty_since = None
            await self.send(socket, {"type": "joined", "room": code, "selfID": member["id"]})
            await self.members(room)
            async for raw in socket:
                try:
                    packet = json.loads(raw)
                    if not isinstance(packet, dict) or packet.get("type") != "ping":
                        raise ValueError("只支持桌面信号")
                    index, seq = packet.get("index"), packet.get("seq")
                    if type(index) is not int or not 0 <= index < 9:
                        raise ValueError("信号类型不支持")
                    if type(seq) is not int or seq <= last_seq:
                        raise ValueError("重复或无效信号")
                    position = packet.get("position")
                    if not isinstance(position, dict) or any(type(position.get(k)) not in (int, float) or not math.isfinite(position[k]) or not 0 <= position[k] <= 1 for k in ("x", "y")):
                        raise ValueError("坐标无效")
                    last_seq = seq
                    now = time.monotonic()
                    while recent and now - recent[0] >= 1:
                        recent.popleft()
                    if len(recent) >= 2:
                        raise ValueError("发送太快，请稍后再试")
                    recent.append(now)
                    if index == 8:
                        member["steelCount"] += 1
                        await self.members(room)
                    event = {"type": "ping", "id": str(uuid.uuid4()), "index": index, "name": member["name"], "sender": member["id"], "position": {"x": position["x"], "y": position["y"]}, "steelCount": member["steelCount"]}
                    await asyncio.gather(*(self.send(peer, event) for peer in list(room.clients) if peer is not socket))
                except (ValueError, TypeError, UnicodeDecodeError):
                    await self.send(socket, {"type": "error", "message": "信号无效或过于频繁"})
        except (ValueError, TypeError, UnicodeDecodeError) as error:
            await self.send(socket, {"type": "error", "message": str(error)})
        except (ConnectionClosed, TimeoutError):
            pass
        finally:
            self.connections -= 1
            if room is not None and socket in room.clients:
                del room.clients[socket]
                if not room.clients:
                    room.empty_since = time.monotonic()
                await self.members(room)

    async def cleanup(self):
        while True:
            await asyncio.sleep(15)
            now = time.monotonic()
            for code, room in list(self.rooms.items()):
                if now - room.created > 86400 or (room.empty_since is not None and now - room.empty_since > 120):
                    del self.rooms[code]
                    await asyncio.gather(*(s.close(code=1001, reason="Room expired") for s in list(room.clients)))


async def main():
    relay = Relay()
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8765"))
    async with serve(relay.handle, host, port, origins=[None], max_size=2048, max_queue=8,
                     compression=None, ping_interval=15, ping_timeout=15, close_timeout=2):
        print(f"ClipMini relay listening on {host}:{port}", flush=True)
        await relay.cleanup()


if __name__ == "__main__":
    asyncio.run(main())
