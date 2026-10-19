import Foundation
import JavaScriptCore

@MainActor
final class Fortune {
    static let shared = Fortune()
    private let context = JSContext()

    private init() {
        context?.evaluateScript("var self = this;")
        let url = Bundle.main.url(forResource: "iztro-2.6.0.min", withExtension: "js")
            ?? Bundle.module.url(forResource: "iztro-2.6.0.min", withExtension: "js", subdirectory: "Resources")
        if let url, let script = try? String(contentsOf: url, encoding: .utf8) { context?.evaluateScript(script) }
    }

    func reading(birth: Date, gender: String, date: Date, scope: String) -> [String: String] {
        guard ["男", "女"].contains(gender), ["yearly", "monthly", "daily"].contains(scope), date >= birth else { return [:] }
        let calendar = Calendar.current
        let b = calendar.dateComponents([.year, .month, .day, .hour], from: birth)
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = b.year, let month = b.month, let day = b.day, let hour = b.hour,
              let targetYear = d.year, let targetMonth = d.month, let targetDay = d.day,
              (1900...2100).contains(year), (1900...2100).contains(targetYear) else { return [:] }
        let timeIndex = hour == 23 ? 12 : (hour + 1) / 2
        let script = """
        (function(){
            var a=iztro.astro.bySolar('\(year)-\(month)-\(day)',\(timeIndex),'\(gender)',true,'zh-CN');
            var h=a.horoscope('\(targetYear)-\(targetMonth)-\(targetDay)',6),r={};
            r.profile='命主 '+a.soul+' · 身主 '+a.body+' · '+a.fiveElementsClass;
            r.mutagen=h['\(scope)'].mutagen.map(function(s,i){return s+'化'+['禄','权','科','忌'][i];}).join(' · ');
            ['命宫','官禄','财帛','夫妻'].forEach(function(p){
                var tags=['禄','权','科','忌'].filter(function(m){return h.hasHoroscopeMutagen(p,'\(scope)',m);});
                r[p]=tags.length?tags.map(function(m){return '化'+m;}).join('、'):'未见本期四化，不等于平安或无事';
                var theme={'命宫':'自我与行动','官禄':'工作与责任','财帛':'资源与收支','夫妻':'亲密关系与沟通'}[p];
                r[p+'.note']=tags.length?theme+'：'+tags.map(function(m){return {禄:'传统象征增加与收获',权:'传统象征掌控与责任',科:'传统象征认可与名声',忌:'传统象征关注与阻力'}[m];}).join('；'):'仅凭本期四化无法作吉凶判断';
            });
            return r;
        })()
        """
        guard let value = context?.evaluateScript(script), !value.isUndefined,
              let result = value.toDictionary() as? [String: String] else { return [:] }
        return result
    }
}
