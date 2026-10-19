import AppKit
import SwiftUI

enum PanelPlacement: String {
    case bottom
    case menu
}

@MainActor
final class HistoryPickerState: ObservableObject {
    @Published var searchText = ""
    @Published var selectedID: UUID?
    @Published private(set) var placement: PanelPlacement

    init() {
        placement = PanelPlacement(
            rawValue: UserDefaults.standard.string(forKey: "panelPlacement") ?? ""
        ) ?? .bottom
    }

    func visibleItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.previewText.localizedCaseInsensitiveContains(searchText)
        }
    }

    func reset(with items: [ClipboardItem]) {
        searchText = ""
        selectedID = items.first?.id
    }

    func moveSelection(by offset: Int, in items: [ClipboardItem]) {
        let visibleItems = visibleItems(from: items)
        guard !visibleItems.isEmpty else {
            selectedID = nil
            return
        }

        guard let selectedID,
              let index = visibleItems.firstIndex(where: { $0.id == selectedID }) else {
            self.selectedID = visibleItems.first?.id
            return
        }

        let newIndex = min(max(index + offset, 0), visibleItems.count - 1)
        self.selectedID = visibleItems[newIndex].id
    }

    func selectedItem(in items: [ClipboardItem]) -> ClipboardItem? {
        let visibleItems = visibleItems(from: items)
        return visibleItems.first { $0.id == selectedID } ?? visibleItems.first
    }

    func setPlacement(_ placement: PanelPlacement) {
        self.placement = placement
        UserDefaults.standard.set(placement.rawValue, forKey: "panelPlacement")
    }
}

struct HistoryView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var pickerState: HistoryPickerState
    let onPick: (ClipboardItem) -> Void
    let onClear: () -> Void
    @FocusState private var searchIsFocused: Bool

    private var visibleItems: [ClipboardItem] {
        pickerState.visibleItems(from: store.items)
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            if visibleItems.isEmpty {
                emptyState
            } else {
                historyList
            }

            HStack {
                Text("← → 选择")
                Text("↩ 复制")
                Text("单击直接粘贴")
                Text("Esc 关闭")
                Spacer()
                Text("所有记录仅保存在本机")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 14)
        .frame(
            minWidth: pickerState.placement == .bottom ? 720 : 480,
            minHeight: pickerState.placement == .bottom ? 250 : 400
        )
        .background(.ultraThinMaterial)
        .clipShape(PanelShape(placement: pickerState.placement))
        .onChange(of: pickerState.searchText) { _ in
            pickerState.selectedID = visibleItems.first?.id
        }
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            Group {
                if pickerState.placement == .bottom {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            cards(width: 220, height: 150)
                        }
                        .padding(.horizontal, 14)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            cards(width: 380, height: 120)
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
            .onChange(of: pickerState.selectedID) { selectedID in
                guard let selectedID else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func cards(width: CGFloat, height: CGFloat) -> some View {
        ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
            HistoryCard(
                index: index + 1,
                item: item,
                image: store.image(for: item),
                isSelected: pickerState.selectedID == item.id,
                width: width,
                height: height,
                onPick: {
                    onPick(item)
                },
                onDelete: {
                    store.delete(item)
                    pickerState.selectedID = visibleItems.first?.id
                }
            )
            .id(item.id)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "clipboard.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Flipos 剪贴板")
                    .font(.headline)
                Text("共 \(store.items.count) 项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索文字或文件名", text: $pickerState.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchIsFocused)
                    .frame(width: pickerState.placement == .bottom ? 260 : 180)
                if !pickerState.searchText.isEmpty {
                    Button {
                        pickerState.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 9))

            Spacer()

            Button(action: onClear) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("清空历史")
            .disabled(store.items.isEmpty)
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: pickerState.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(pickerState.searchText.isEmpty ? "还没有历史记录" : "没有匹配结果")
                .font(.headline)
            Text(pickerState.searchText.isEmpty ? "复制文字、图片或文件后会自动出现在这里" : "换一个关键词试试")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PanelShape: Shape {
    let placement: PanelPlacement

    func path(in rect: CGRect) -> Path {
        if placement == .menu {
            return Path(roundedRect: rect, cornerRadius: 14)
        }

        let radius: CGFloat = 16
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

private struct HistoryCard: View {
    let index: Int
    let item: ClipboardItem
    let image: NSImage?
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    let onPick: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(index)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                itemIcon
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("删除")
            }

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(item.previewText)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(12)
        .frame(width: width, height: height)
        .background(Color(nsColor: .controlBackgroundColor).opacity(isSelected ? 0.92 : 0.72))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onPick)
    }

    @ViewBuilder
    private var itemIcon: some View {
        if item.kind == .file, let path = item.filePaths?.first {
            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: item.kind == .image ? "photo" : "doc.text")
                .foregroundStyle(.secondary)
        }
    }
}
