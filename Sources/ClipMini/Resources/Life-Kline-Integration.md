# Life-Kline integration

Source: https://github.com/miounet11/life-kline
Pinned commit: 7abf184df370452ee8279d72c8b45bc09e19913b
Copyright 2024-2025 Life-Kline Team. Apache-2.0.
See life-kline-LICENSE.txt and life-kline-NOTICE.txt.

ClipMini adapts services/fortuneCalculator.ts: removes import/export and erases TypeScript annotations using Node's built-in stripTypeScriptTypes (no npm). The module executes locally in JavaScriptCore with the existing MIT lunar-javascript library. No upstream website, authentication, database, paid service, encrypted prompts, analytics, celebrity data or backend is included.

Custom native SwiftUI integration: birth input, EightChar/Yun local charting, 100-year OHLC aggregation of the original monthly overall scoring rules, 12-month base-versus-adjusted score view, chart selection, consent-gated DeepSeek cultural interpretation using a new safety-focused prompt, user-directed JSON export. OHLC values are not random: yearly open/close are January/December rule scores; high/low are monthly extrema. Monthly OHLC shows base/adjusted rule scores, not intra-month daily values. DaYun is displayed separately and not incorporated into upstream scores. Rules are simplified, unvalidated entertainment heuristics, not probabilities or real forecasts.

Birth timezone uses the macOS system timezone, without true-solar-time adjustment. Birth and reports stay in memory unless the user chooses export or explicitly consents to a DeepSeek request. Existing keychain storage is reused. No live DeepSeek request is performed during tests.
