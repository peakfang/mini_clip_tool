# Third Party Notices

This project includes rule ideas adapted from public 六爻纳甲资料 and may load the following third-party library from CDN at runtime:

- lunar-javascript / lunar-typescript ecosystem by 6tail
  - License: MIT
  - Project: https://github.com/6tail/lunar-javascript
  - Docs: https://6tail.cn/calendar/api.html

The app falls back to an internal approximate calendar conversion when the CDN is unavailable.

ClipMini integration pins liuyao-graph commit 6ebc6e67168352c786ecfe924c12c0305c78a10a,
loads the already bundled lunar-javascript copy locally, and blocks non-file navigation.
