import AppKit
import SwiftUI

struct WorkbenchView: View {
    @ObservedObject var store: WorkbenchStore
    @State private var taskTitle = ""
    @State private var taskEditorVisible = false
    @State private var liuyaoVisible = false
    @State private var settingsVisible = false
    @State private var calendarVisible = false
    @State private var fortuneVisible = false
    @State private var birthday = Date()
    @State private var birthGender = ""
    @State private var fortuneDate = Date()
    @State private var fortuneScope = "yearly"
    @State private var month = Date()
    @State private var calendarDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    Image(nsImage: avatarImage(store.avatar))
                        .resizable().scaledToFit().frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.name).font(.system(size: 24, weight: .semibold))
                        Text(store.motto).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("个人数据仅本地保存").font(.caption).foregroundStyle(.blue)
                        .padding(8).background(Color.blue.opacity(0.07)).clipShape(Capsule())
                    Button { settingsVisible = true } label: { Image(systemName: "gearshape") }
                        .buttonStyle(.plain).help("个人信息设置")
                }
                .padding(.bottom, 4)

                WorkbenchRow {
                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Codex 剩余额度").font(.headline)
                                Spacer()
                                Button { store.refreshQuota() } label: { Image(systemName: "arrow.clockwise") }
                                    .buttonStyle(.plain).foregroundStyle(.blue).help("刷新在线额度")
                            }
                            if store.quotas.isEmpty {
                                Text("—").font(.system(size: 32, weight: .semibold))
                            }
                            ForEach(store.quotas) { quota in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text("\(quota.remaining, specifier: "%.0f")%")
                                            .font(.system(size: 25, weight: .semibold)).monospacedDigit()
                                        Spacer()
                                        Text(quota.title).font(.caption).foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: quota.remaining, total: 100).tint(.blue)
                                    if let reset = quota.reset {
                                        Text("重置：\(reset.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Text(store.quotaStatus).font(.caption2).foregroundStyle(.secondary)
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(store.quotaRefreshCountdown(at: context.date))
                                    .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                            }
                            if let updated = store.quotaUpdatedAt {
                                Text("上次成功：\(updated.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    card {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("万年历").font(.headline)
                            Text(store.now.formatted(.dateTime.day())).font(.system(size: 45, weight: .semibold))
                            Text(store.now.formatted(.dateTime.year().month().weekday(.wide)))
                                .font(.subheadline)
                            Text(lunarDate(store.now)).font(.caption).foregroundStyle(.secondary)
                            Text("宜  " + (Almanac.shared.details(store.now)["yi"] ?? "暂不可用"))
                                .font(.caption).foregroundStyle(.green).lineLimit(2)
                            Text("忌  " + (Almanac.shared.details(store.now)["ji"] ?? "暂不可用"))
                                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            Text("黄历民俗参考").font(.caption2).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Button("查看月历与宜忌 →") { month = store.now; calendarDate = store.now; calendarVisible = true }
                                .buttonStyle(.plain).foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity, minHeight: 165, alignment: .topLeading)
                    }
                }

                WorkbenchRow {
                    card {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("今日任务").font(.headline)
                                Text("\(store.todayTasks.filter(\.completed).count) / \(store.todayTasks.count) 完成")
                                    .font(.caption).foregroundStyle(.blue)
                                Spacer()
                                Button {
                                    taskTitle = ""
                                    taskEditorVisible = true
                                } label: {
                                    Image(systemName: "plus")
                                }.buttonStyle(.plain).foregroundStyle(.blue).help("新增今日任务")
                            }
                            if store.todayTasks.isEmpty {
                                Text("今天想完成什么？添加第一件事。")
                                    .foregroundStyle(.secondary).padding(.vertical, 20)
                            }
                            ForEach(store.todayTasks) { task in
                                HStack {
                                    Button {
                                        if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
                                            store.tasks[index].completed.toggle()
                                        }
                                    } label: {
                                        Image(systemName: task.completed ? "checkmark.square.fill" : "square")
                                            .font(.title3).foregroundStyle(task.completed ? Color.blue : Color.secondary)
                                    }.buttonStyle(.plain)
                                    Text(task.title).strikethrough(task.completed)
                                        .foregroundStyle(task.completed ? Color.secondary : Color.primary)
                                    Spacer()
                                    Button {
                                        store.tasks.removeAll { $0.id == task.id }
                                    } label: { Image(systemName: "xmark").font(.caption).foregroundStyle(.secondary) }
                                        .buttonStyle(.plain).help("删除任务")
                                }
                                Divider().opacity(0.5)
                            }
                        }.frame(maxWidth: .infinity, minHeight: 235, alignment: .topLeading)
                    }.frame(maxWidth: .infinity)
                    Button { liuyaoVisible = true } label: {
                        card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("六爻").font(.headline).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                                }
                                Image(systemName: "lines.measurement.horizontal")
                                    .font(.system(size: 30)).foregroundStyle(.blue)
                                Text("手工、时间与铜钱起卦")
                                    .font(.subheadline).foregroundStyle(.primary)
                                Text("本卦 · 变卦 · 纳甲 · 六亲六神")
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("本地离线计算 · 传统文化娱乐参考")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 235, alignment: .topLeading)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 900, minHeight: 650)
        .sheet(isPresented: $settingsVisible) { settings }
        .sheet(isPresented: $calendarVisible) { calendar }
        .sheet(isPresented: $liuyaoVisible) { LiuyaoView() }
        .sheet(isPresented: $taskEditorVisible) {
            VStack(alignment: .leading, spacing: 18) {
                Text("新增今日任务").font(.title2.weight(.semibold))
                TextField("今天要完成什么？", text: $taskTitle)
                    .textFieldStyle(.roundedBorder).onSubmit { addTask() }
                HStack {
                    Spacer()
                    Button("取消") { taskEditorVisible = false }.keyboardShortcut(.cancelAction)
                    Button("添加", action: addTask)
                        .keyboardShortcut(.defaultAction)
                        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }.padding(24).frame(width: 420)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().frame(maxHeight: .infinity, alignment: .topLeading).padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private func addTask() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        store.tasks.append(WorkbenchTask(title: title, day: store.todayKey))
        taskTitle = ""
        taskEditorVisible = false
    }

    private func lunarDate(_ date: Date) -> String {
        let calendar = Calendar(identifier: .chinese)
        let parts = calendar.dateComponents([.month, .day], from: date)
        let months = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        let digits = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        guard let month = parts.month, let day = parts.day, (1...12).contains(month), (1...30).contains(day) else { return "农历暂不可用" }
        let label = day <= 10 ? "初" + digits[day - 1] : (day < 20 ? "十" + digits[day - 11] : (day == 20 ? "二十" : (day < 30 ? "廿" + digits[day - 21] : "三十")))
        return "农历\(parts.isLeapMonth == true ? "闰" : "")\(months[month - 1])月\(label)"
    }

    func avatarImage(_ id: String) -> NSImage {
        guard ["buu", "goku", "vegeta", "piccolo", "ahri", "jinx", "yasuo", "teemo"].contains(id),
              let url = Bundle.main.url(forResource: "avatar-" + id, withExtension: "png")
                ?? Bundle.module.url(forResource: "avatar-" + id, withExtension: "png", subdirectory: "Resources"),
              let image = NSImage(contentsOf: url) else { return NSApp.applicationIconImage }
        return image
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("工作台设置").font(.title2.weight(.semibold))
            Text("头像").font(.headline)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach([("buu", "布欧"), ("goku", "孙悟空"), ("vegeta", "贝吉塔"), ("piccolo", "比克"),
                             ("ahri", "阿狸"), ("jinx", "金克丝"), ("yasuo", "亚索"), ("teemo", "提莫")], id: \.0) { avatar in
                        Button { store.avatar = avatar.0 } label: {
                            VStack(spacing: 6) {
                                Image(nsImage: avatarImage(avatar.0)).resizable().scaledToFit()
                                    .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(store.avatar == avatar.0 ? Color.blue : Color.clear, lineWidth: 2))
                                Text(avatar.1).font(.caption)
                            }
                        }.buttonStyle(.plain).help("选择" + avatar.1 + "头像")
                    }
                }
            }.frame(height: 240)
            Form {
                TextField("名字", text: $store.name)
                TextField("鼓励语", text: $store.motto)
            }
            Text("黄历与六爻均在本机显示和计算。Codex 使用现有官方登录，每 2 分钟自动查询在线额度；不会上传任务、便签或剪贴板。")
                .font(.caption).foregroundStyle(.secondary)
            HStack { Spacer(); Button("完成") { settingsVisible = false }.keyboardShortcut(.defaultAction) }
        }.padding(24).frame(width: 460)
    }

    private var calendar: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        return VStack(spacing: 18) {
            HStack {
                Button("‹") { month = calendar.date(byAdding: .month, value: -1, to: month) ?? month }
                Spacer()
                Text(month.formatted(.dateTime.year().month(.wide))).font(.title2.weight(.semibold))
                Spacer()
                Button("›") { month = calendar.date(byAdding: .month, value: 1, to: month) ?? month }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { Text($0).foregroundStyle(.secondary) }
                ForEach(0..<(offset + count), id: \.self) { index in
                    if index < offset { Color.clear.frame(height: 42) }
                    else {
                        let date = calendar.date(byAdding: .day, value: index - offset, to: start) ?? start
                        Button { calendarDate = date } label: { VStack(spacing: 4) {
                            Text("\(index - offset + 1)").font(.headline)
                            Text(lunarDate(date).components(separatedBy: "月").last ?? "").font(.caption2).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 42)
                            .background(calendar.isDate(date, inSameDayAs: calendarDate) ? Color.blue.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        }.buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(calendarDate.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                Text("宜  " + (Almanac.shared.details(calendarDate)["yi"] ?? "暂不可用")).foregroundStyle(.green)
                Text("忌  " + (Almanac.shared.details(calendarDate)["ji"] ?? "暂不可用")).foregroundStyle(.secondary)
                Text("黄历民俗参考 · 不同历书可能存在差异").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
            Text("公历与农历本地计算 · 暂不包含法定调休与节气").font(.caption).foregroundStyle(.secondary)
            HStack { Button("回到今天") { month = Date(); calendarDate = month }; Spacer(); Button("关闭") { calendarVisible = false }.keyboardShortcut(.cancelAction) }
        }.padding(24).frame(width: 520)
    }

    private let zodiacs = [
        ("白羊座", "♈", "3月21日 – 4月19日"), ("金牛座", "♉", "4月20日 – 5月20日"),
        ("双子座", "♊", "5月21日 – 6月21日"), ("巨蟹座", "♋", "6月22日 – 7月22日"),
        ("狮子座", "♌", "7月23日 – 8月22日"), ("处女座", "♍", "8月23日 – 9月22日"),
        ("天秤座", "♎", "9月23日 – 10月23日"), ("天蝎座", "♏", "10月24日 – 11月22日"),
        ("射手座", "♐", "11月23日 – 12月21日"), ("摩羯座", "♑", "12月22日 – 1月19日"),
        ("水瓶座", "♒", "1月20日 – 2月18日"), ("双鱼座", "♓", "2月19日 – 3月20日")
    ]

    // Traditional sun-sign descriptions, not measured personality traits or daily predictions.
    private let zodiacInfo = [
        ("火象 · 基本宫 · 守护星：火星", "传统关键词：主动、直接、行动力；也容易急于求成。", "把想法说清楚，给彼此考虑的时间。"),
        ("土象 · 固定宫 · 守护星：金星", "传统关键词：稳定、耐心、重视感官体验；也可能固执。", "循序渐进，尊重彼此的节奏。"),
        ("风象 · 变动宫 · 守护星：水星", "传统关键词：好奇、灵活、表达欲；也可能分散注意力。", "保持交流，也把承诺落到具体行动。"),
        ("水象 · 基本宫 · 守护星：月亮", "传统关键词：体贴、敏感、重视归属；也可能过度担忧。", "表达真实需要，不让对方靠猜。"),
        ("火象 · 固定宫 · 守护星：太阳", "传统关键词：热情、自信、创造力；也可能太在意认可。", "真诚肯定，同时保留平等的边界。"),
        ("土象 · 变动宫 · 守护星：水星", "传统关键词：细致、务实、善于整理；也可能追求完美。", "先理解动机，再讨论具体改进。"),
        ("风象 · 基本宫 · 守护星：金星", "传统关键词：协调、审美、重视公平；也可能犹豫不决。", "把偏好讲出来，不必处处迎合。"),
        ("水象 · 固定宫 · 传统守护星：火星", "传统关键词：专注、深入、重视信任；也可能难以放下。", "坦诚沟通，尊重隐私与独处空间。"),
        ("火象 · 变动宫 · 守护星：木星", "传统关键词：探索、乐观、重视自由；也可能忽略细节。", "给彼此空间，也明确共同约定。"),
        ("土象 · 基本宫 · 守护星：土星", "传统关键词：自律、责任、长期规划；也可能过于严肃。", "认可付出，也留一点放松的时间。"),
        ("风象 · 固定宫 · 传统守护星：土星", "传统关键词：独立、创新、重视理念；也可能显得疏离。", "尊重不同观点，直接表达感受。"),
        ("水象 · 变动宫 · 传统守护星：木星", "传统关键词：共情、想象、直觉；也可能边界不清。", "温和但明确地表达需求和底线。")
    ]

    private var fortune: some View {
        let values = Almanac.shared.details(birthday, birth: true)
        let reading = Fortune.shared.reading(birth: birthday, gender: birthGender, date: fortuneDate, scope: fortuneScope)
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Text("八字与紫微运势").font(.title2.weight(.semibold)); Spacer()
                Button("关闭") { fortuneVisible = false }.keyboardShortcut(.cancelAction)
            }
            ScrollView { VStack(alignment: .leading, spacing: 16) {
            DatePicker("出生日期与时间", selection: $birthday, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
            Picker("传统排盘性别", selection: $birthGender) {
                Text("请选择").tag(""); Text("男").tag("男"); Text("女").tag("女")
            }
            Text("八字").font(.headline)
            Text(values["bazi"] ?? "排盘暂不可用").font(.title2).textSelection(.enabled)
            Text("五行（按四柱顺序）").font(.headline)
            Text(values["wuxing"] ?? "暂不可用").font(.title3).textSelection(.enabled)
            Divider()
            DatePicker("查看日期", selection: $fortuneDate, in: birthday..., displayedComponents: [.date])
            Picker("运势周期", selection: $fortuneScope) {
                Text("流年").tag("yearly"); Text("流月").tag("monthly"); Text("流日").tag("daily")
            }.pickerStyle(.segmented)
            if birthGender.isEmpty {
                Text("选择排盘性别后查看紫微运势，不默认替你选择。").foregroundStyle(.secondary)
            } else if reading.isEmpty {
                Text("暂无法排盘，请检查日期（支持 1900–2100 年）及出生时间。").foregroundStyle(.secondary)
            } else {
                Text(reading["profile"] ?? "").font(.subheadline)
                Text("本期四化：" + (reading["mutagen"] ?? "")).font(.caption).foregroundStyle(.blue)
                ForEach(["命宫", "官禄", "财帛", "夫妻"], id: \.self) { palace in
                    HStack(alignment: .top) {
                        Text(palace).font(.headline).frame(width: 48, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reading[palace] ?? "暂不可用").font(.subheadline)
                            Text(reading[palace + ".note"] ?? "").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Text("传统吉凶意象（非事件预测）").font(.headline)
                Text("禄：增加与收获；权：执行与责任；科：认可与名声。传统称三吉化，但不保证好事发生。忌：执着与阻力，提示关注，不代表灾难。多种四化可同时出现，不能简单相加成运势分数。")
                    .font(.caption).foregroundStyle(.secondary)
                Link("算法与四化解读来源：iztro 2.6.0", destination: URL(string: "https://www.iztro.com/learn/mutagen")!)
                    .font(.caption)
            }
            Text("使用系统当前时区排盘，未校正出生地真太阳时；临近换日或节气时可能存在流派差异。出生信息不保存、不上传。仅供民俗娱乐参考，不作为人生决策依据。")
                .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading) }
        }.padding(24).frame(width: 560, height: 650)
    }
}

// Three equal grid columns; the task card spans the first two columns.
struct WorkbenchRow: Layout {
    var firstSpan = 1
    private let spacing: CGFloat = 14

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 852
        let column = (width - spacing * 2) / 3
        let height = subviews.enumerated().map { index, view in
            view.sizeThatFits(ProposedViewSize(width: index == 0 && firstSpan == 2 ? column * 2 + spacing : column, height: nil)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let column = (bounds.width - spacing * 2) / 3
        var x = bounds.minX
        for (index, view) in subviews.enumerated() {
            let width = index == 0 && firstSpan == 2 ? column * 2 + spacing : column
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }
}
