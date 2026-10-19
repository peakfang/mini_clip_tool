import AppKit
import SwiftUI

struct CyberFortuneView: View {
    @ObservedObject var aiStore: AIChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var birth = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 12)) ?? Date()
    @State private var gender = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var reading: CyberReading?
    @State private var monthly = false
    @State private var selected: LifeCandle?
    @State private var key = ""
    @State private var settingsVisible = false
    @State private var consentVisible = false
    @State private var report = ""
    @State private var error = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("赛博算命 · 人生 K 线").font(.title2.weight(.semibold))
                    Text("把传统命理变成可探索的图表 · 仅供娱乐").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("AI 设置") { settingsVisible.toggle() }.disabled(aiStore.sending)
                Button("关闭") { aiStore.stop(); dismiss() }.keyboardShortcut(.cancelAction)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        DatePicker("公历出生", selection: $birth, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        Picker("性别", selection: $gender) {
                            Text("请选择").tag("")
                            Text("男").tag("男")
                            Text("女").tag("女")
                        }.frame(width: 135)
                        Button("本地排盘") { calculate() }.disabled(gender.isEmpty || aiStore.sending)
                    }
                    Text("使用系统时区，不校正真太阳时。出生信息不自动保存；改动输入后请重新排盘。")
                        .font(.caption).foregroundStyle(.secondary)
                    if settingsVisible {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SecureField(aiStore.hasKey ? "替换 DeepSeek API Key" : "DeepSeek API Key", text: $key)
                                Button("保存") { aiStore.saveKey(key); key = "" }.disabled(key.isEmpty || aiStore.sending)
                                if aiStore.hasKey { Button("移除") { aiStore.removeKey() }.disabled(aiStore.sending) }
                            }
                            Picker("模型", selection: $aiStore.model) {
                                Text("DeepSeek Flash").tag("deepseek-flash")
                                Text("DeepSeek V4 Pro").tag("deepseek-v4-pro")
                            }.disabled(aiStore.sending)
                            Text("Key 保存在本机钥匙串。AI 解读会调用 DeepSeek 并产生 API 费用。")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(12).background(Color.blue.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if !error.isEmpty { Text(error).font(.caption).foregroundStyle(.red) }
                    if let reading {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("四柱八字").font(.caption).foregroundStyle(.secondary)
                                Text(reading.bazi).font(.title3.weight(.medium))
                                Text(reading.wuxing).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 5) {
                                Text("今日规则分").font(.caption).foregroundStyle(.secondary)
                                Text("\(reading.dailyScore) / 100").font(.title3.weight(.medium))
                                Text("幸运色 · " + reading.colors.joined(separator: "、")).font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(16).background(Color(nsColor: .controlBackgroundColor)).clipShape(RoundedRectangle(cornerRadius: 12))
                        HStack {
                            Picker("视图", selection: $monthly) {
                                Text("一生 · 100 年").tag(false)
                                Text("年度 · 12 月").tag(true)
                            }.pickerStyle(.segmented).frame(width: 230)
                            Spacer()
                            Picker("年份", selection: $year) {
                                ForEach(reading.life) { candle in Text("\(candle.year) 年 · \(candle.age) 岁").tag(candle.year) }
                            }.frame(width: 210).disabled(aiStore.sending)
                        }
                        LifeCandleChart(candles: monthly ? reading.months : reading.life, selected: $selected)
                            .frame(height: 230)
                        Text("蓝色上行，灰色回落；点击 K 线查看。年度蜡烛汇总 12 个月规则分，月度蜡烛展示规则修正前后分数。")
                            .font(.caption).foregroundStyle(.secondary)
                        if let selected {
                            HStack {
                                Text("\(selected.year) 年 · \(selected.age) 岁" + (selected.month > 0 ? " · \(selected.month) 月" : ""))
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("开 \(Int(selected.open))  收 \(Int(selected.close))  高 \(Int(selected.high))  低 \(Int(selected.low))")
                                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                        }
                        DisclosureGroup("大运排盘 · 不计入规则 K 线评分") {
                            Text(reading.dayun.joined(separator: "\n")).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                        }.font(.subheadline)
                        HStack {
                            Text("AI 命理解读").font(.headline)
                            Spacer()
                            if aiStore.sending {
                                ProgressView().controlSize(.small)
                                Button("停止") { aiStore.stop() }
                            } else {
                                Button(report.isEmpty ? "生成解读" : "重新解读") {
                                    if aiStore.hasKey { consentVisible = true } else { settingsVisible = true; aiStore.status = "请先配置 DeepSeek API Key" }
                                }
                            }
                            Button("导出报告") { exportReading(reading) }
                        }
                        if !aiStore.status.isEmpty { Text(aiStore.status).font(.caption).foregroundStyle(.secondary) }
                        if report.isEmpty {
                            Text("本地 K 线无需 Key。AI 可结合八字、大运和选定年份，提供性格、事业、关系与行动提示的文化娱乐解读。")
                                .font(.subheadline).foregroundStyle(.secondary)
                        } else { Text(report).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line").font(.system(size: 36)).foregroundStyle(.blue)
                            Text("先排盘，再探索你的人生 K 线").font(.headline)
                            Text("四柱 / 大运 / 百年走势 / 月度切换 / AI 解读 / 报告导出")
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, 65)
                    }
                    Divider()
                    Text("分数是开源项目的简化规则，不是吉凶概率，也未验证能预测未来。大运仅单独展示，不参与曲线计算。请勿用于投资、医疗或重大人生决策。")
                        .font(.caption).foregroundStyle(.secondary)
                    Link("计算模块来源 · Life-Kline / Apache-2.0", destination: URL(string: "https://github.com/miounet11/life-kline")!)
                        .font(.caption)
                }
            }
        }.padding(24).frame(width: 820, height: 720)
        .onChange(of: year) { _ in if reading != nil && !aiStore.sending { calculate() } }
        .onChange(of: monthly) { _ in selected = nil }
        .onChange(of: selected?.year) { value in if let value, value != year && !aiStore.sending { year = value } }
        .onChange(of: aiStore.messages.count) { _ in
            if let message = aiStore.messages.last, message.role == "assistant" { report = message.content }
        }
        .onDisappear { aiStore.stop(); key = "" }
        .alert("发送给 DeepSeek？", isPresented: $consentVisible) {
            Button("取消", role: .cancel) { }
            Button("同意并生成") {
                guard let reading else { return }
                aiStore.clear()
                let candle = reading.life.first { $0.year == year }
                let prompt = """
                你是理性的传统命理文化娱乐解读助手。以下排盘在本地生成；K线是开源简化规则分，不是真实统计、不代表未来吉凶概率。不得承诺预测成真，不得作寿命、死亡、疾病、灾祸断言，不提供投资交易建议。不要编造具体事件。用中文，800字以内，分为性格倾向、事业学习、关系沟通、选定年份的传统解读、三条实际行动提示。必须指出规则K线并未纳入大运，不能据此判断真实命运。基于输入解释，不捏造未知出生地或真太阳时。
                四柱：\(reading.bazi)。五行：\(reading.wuxing)。大运：\(reading.dayun.joined(separator: "；"))。
                选定年份：\(year)。娱乐规则K线：开\(Int(candle?.open ?? 0))，收\(Int(candle?.close ?? 0))，高\(Int(candle?.high ?? 0))，低\(Int(candle?.low ?? 0))。
                """
                aiStore.send(prompt)
            }
        } message: {
            Text("仅发送本次八字、五行、大运和选定年份的规则分，不发送头像、任务、剪贴板。DeepSeek 会收到这些命盘信息，调用会产生 API 费用。")
        }
    }

    private func calculate() {
        let birthYear = Calendar.current.component(.year, from: birth)
        year = min(max(year, birthYear), birthYear + 99)
        reading = CyberFortune.shared.reading(birth: birth, gender: gender, year: year)
        selected = reading?.life.first { $0.year == year }
        report = ""
        error = reading == nil ? "排盘失败，请检查出生日期和性别（支持 1900–2100 年出生）。" : ""
    }

    private func exportReading(_ reading: CyberReading) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "人生K线-\(year).json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try JSONSerialization.jsonObject(with: encoder.encode(reading))
                let output = try JSONSerialization.data(withJSONObject: ["reading": data, "aiReport": report, "notice": "仅供文化娱乐，规则分不是未来预测。"], options: [.prettyPrinted, .sortedKeys])
                try output.write(to: url, options: .atomic)
                aiStore.status = "报告已保存到所选位置（含命盘信息，请妥善保管）"
            } catch { aiStore.status = "报告保存失败" }
        }
    }
}

struct LifeCandleChart: View {
    let candles: [LifeCandle]
    @Binding var selected: LifeCandle?

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = max(1, size.width - 35)
                let height = max(1, size.height - 25)
                for score in [0, 25, 50, 75, 100] {
                    let y = height * (1 - Double(score) / 100)
                    var line = Path()
                    line.move(to: CGPoint(x: 30, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(line, with: .color(.secondary.opacity(0.12)), lineWidth: 1)
                    context.draw(Text("\(score)").font(.system(size: 9)).foregroundColor(.secondary), at: CGPoint(x: 12, y: max(5, y)))
                }
                let step = width / Double(max(1, candles.count))
                for (index, candle) in candles.enumerated() {
                    let x = 30 + step * (Double(index) + 0.5)
                    let color = candle.close >= candle.open ? Color.blue : Color.secondary
                    var wick = Path()
                    wick.move(to: CGPoint(x: x, y: height * (1 - candle.high / 100)))
                    wick.addLine(to: CGPoint(x: x, y: height * (1 - candle.low / 100)))
                    context.stroke(wick, with: .color(color), lineWidth: 1)
                    let rect = CGRect(x: x - step * 0.3, y: height * (1 - max(candle.open, candle.close) / 100), width: max(2, step * 0.6), height: max(2, height * abs(candle.open - candle.close) / 100))
                    context.fill(Path(rect), with: .color(color))
                    if selected?.id == candle.id {
                        var marker = Path()
                        marker.move(to: CGPoint(x: x, y: 0))
                        marker.addLine(to: CGPoint(x: x, y: height))
                        context.stroke(marker, with: .color(.blue.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    if candles.count <= 12 || index % 10 == 0 {
                        context.draw(Text(candle.month > 0 ? "\(candle.month)月" : "\(candle.age)岁").font(.system(size: 9)).foregroundColor(.secondary), at: CGPoint(x: x, y: height + 15))
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard !candles.isEmpty else { return }
                let index = Int(max(0, value.location.x - 30) / max(1, geometry.size.width - 35) * Double(candles.count))
                selected = candles[min(index, candles.count - 1)]
            })
        }
    }
}
