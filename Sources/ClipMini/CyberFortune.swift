import Foundation
import JavaScriptCore

struct LifeCandle: Codable, Identifiable {
    var id: Int { year * 100 + month }
    let year: Int
    let age: Int
    let month: Int
    let open: Double
    let close: Double
    let high: Double
    let low: Double
}

struct CyberReading: Codable {
    let bazi: String
    let wuxing: String
    let dayun: [String]
    let life: [LifeCandle]
    let months: [LifeCandle]
    let colors: [String]
    let numbers: [Int]
    let dailyScore: Int
}

@MainActor
final class CyberFortune {
    static let shared = CyberFortune()
    private let context = JSContext()

    private init() {
        for file in ["lunar", "life-kline-fortune"] {
            let url = Bundle.main.url(forResource: file, withExtension: "js")
                ?? Bundle.module.url(forResource: file, withExtension: "js", subdirectory: "Resources")
            if let url, let script = try? String(contentsOf: url, encoding: .utf8) {
                context?.evaluateScript(script)
            }
        }
    }

    func reading(birth: Date, gender: String, year: Int, today: Date = Date()) -> CyberReading? {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: birth)
        let now = Calendar.current.dateComponents([.year, .month, .day], from: today)
        guard ["男", "女"].contains(gender), let y = parts.year, let m = parts.month, let d = parts.day,
              (1900...2100).contains(y), birth <= today, (y...(y + 99)).contains(year),
              let ny = now.year, let nm = now.month, let nd = now.day else { return nil }
        // Local, deterministic entertainment rules from the Apache-2.0 Life-Kline project.
        // OHLC values aggregate twelve monthly rule scores, not real observations or AI predictions.
        let script = """
        (function(){
          var e=Solar.fromYmdHms(\(y),\(m),\(d),\(parts.hour ?? 0),\(parts.minute ?? 0),0).getLunar().getEightChar();
          var b={yearPillar:e.getYear(),monthPillar:e.getMonth(),dayPillar:e.getDay(),hourPillar:e.getTime(),gender:'\(gender == "男" ? "Male" : "Female")'};
          var c=clipminiFortuneCalculator, life=[], months=[];
          for(var yr=\(y);yr<\(y + 100);yr++){
            var scores=[], all=[];
            for(var mo=1;mo<=12;mo++){
              var l=Solar.fromYmd(yr,mo,1).getLunar(), gz=l.getMonthGan()+l.getMonthZhi();
              var base=c.calculateBaseScore(b,gz), modifier=c.calculateMonthlyModifiers(b,gz,l.getYearGan()+l.getYearZhi());
              scores.push(Math.max(1,Math.min(100,base+modifier.overall)));
              all.push({year:yr,age:yr-\(y)+1,month:mo,open:Math.max(1,Math.min(100,base)),close:scores[mo-1],high:Math.max(Math.max(1,Math.min(100,base)),scores[mo-1]),low:Math.min(Math.max(1,Math.min(100,base)),scores[mo-1])});
            }
            life.push({year:yr,age:yr-\(y)+1,month:0,open:scores[0],close:scores[11],high:Math.max.apply(null,scores),low:Math.min.apply(null,scores)});
            if(yr===\(year))months=all;
          }
          var daily=c.calculateDaily(b,new Date(\(ny),\(nm - 1),\(nd),12));
          var yun=e.getYun(\(gender == "男" ? 1 : 0),2), dayun=[];
          yun.getDaYun(11).forEach(function(v){if(v.getGanZhi())dayun.push(v.getStartAge()+'–'+v.getEndAge()+'岁 · '+v.getGanZhi());});
          return JSON.stringify({bazi:[b.yearPillar,b.monthPillar,b.dayPillar,b.hourPillar].join(' '),wuxing:[e.getYearWuXing(),e.getMonthWuXing(),e.getDayWuXing(),e.getTimeWuXing()].join(' '),dayun:dayun,life:life,months:months,colors:daily.lucky_colors,numbers:daily.lucky_numbers,dailyScore:daily.overall_score});
        })()
        """
        guard let text = context?.evaluateScript(script)?.toString(), let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(CyberReading.self, from: data)
    }
}
