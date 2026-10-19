import Foundation
import JavaScriptCore

@MainActor
final class Almanac {
    static let shared = Almanac()
    private let context = JSContext()

    private init() {
        let url = Bundle.main.url(forResource: "lunar", withExtension: "js")
            ?? Bundle.module.url(forResource: "lunar", withExtension: "js", subdirectory: "Resources")
        if let url, let script = try? String(contentsOf: url, encoding: .utf8) {
            context?.evaluateScript(script)
        }
    }

    func details(_ date: Date, birth: Bool = false) -> [String: String] {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return [:] }
        // The bundled MIT-licensed lunar-javascript library runs offline in JavaScriptCore.
        let script = "(function(){var l=Solar.fromYmdHms(\(year),\(month),\(day),\(birth ? parts.hour ?? 0 : 12),\(birth ? parts.minute ?? 0 : 0),0).getLunar();var e=l.getEightChar();return {yi:l.getDayYi().join('、'),ji:l.getDayJi().join('、'),bazi:e.getYear()+' '+e.getMonth()+' '+e.getDay()+' '+e.getTime(),wuxing:e.getYearWuXing()+' '+e.getMonthWuXing()+' '+e.getDayWuXing()+' '+e.getTimeWuXing()};})()"
        guard let result = context?.evaluateScript(script), !result.isUndefined,
              let values = result.toDictionary() as? [String: String] else { return [:] }
        return values
    }
}
