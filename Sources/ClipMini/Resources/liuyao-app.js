(function () {
  const SHEN6 = ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武'];
  const QING6 = ['兄弟', '父母', '官鬼', '妻财', '子孙'];
  const XING5 = ['木', '火', '土', '金', '水'];
  const NAJIA = [
    ['甲子寅辰', '壬午申戌'],
    ['丁巳卯丑', '丁亥酉未'],
    ['己卯丑亥', '己酉未巳'],
    ['庚子寅辰', '庚午申戌'],
    ['辛丑亥酉', '辛未巳卯'],
    ['戊寅辰午', '戊申戌子'],
    ['丙辰午申', '丙戌子寅'],
    ['乙未巳卯', '癸丑亥酉'],
  ];
  const GUA64 = {
    '111111': '乾为天', '011111': '天风姤', '001111': '天山遁', '000111': '天地否', '000011': '风地观', '000001': '山地剥',
    '000101': '火地晋', '111101': '火天大有', '110110': '兑为泽', '010110': '泽水困', '000110': '泽地萃', '001110': '泽山咸',
    '001010': '水山蹇', '001000': '地山谦', '001100': '雷山小过', '110100': '雷泽归妹', '101101': '离为火', '001101': '火山旅',
    '011101': '火风鼎', '010101': '火水未济', '010001': '山水蒙', '010011': '风水涣', '010111': '天水讼', '101111': '天火同人',
    '100100': '震为雷', '000100': '雷地豫', '010100': '雷水解', '011100': '雷风恒', '011000': '地风升', '011010': '水风井',
    '011110': '泽风大过', '100110': '泽雷随', '011011': '巽为风', '111011': '风天小畜', '101011': '风火家人', '100011': '风雷益',
    '100111': '天雷无妄', '100101': '火雷噬嗑', '100001': '山雷颐', '011001': '山风蛊', '010010': '坎为水', '110010': '水泽节',
    '100010': '水雷屯', '101010': '水火既济', '101110': '泽火革', '101100': '雷火丰', '101000': '地火明夷', '010000': '地水师',
    '001001': '艮为山', '101001': '山火贲', '111001': '山天大畜', '110001': '山泽损', '110101': '火泽睽', '110111': '天泽履',
    '110011': '风泽中孚', '001011': '风山渐', '000000': '坤为地', '100000': '地雷复', '110000': '地泽临', '111000': '地天泰',
    '111100': '雷天大壮', '111110': '泽天夬', '111010': '水天需', '000010': '水地比'
  };
  const GUAS = ['乾', '兑', '离', '震', '巽', '坎', '艮', '坤'];
  const GUA5 = [3, 3, 1, 0, 0, 4, 2, 2];
  const YAOS = ['111', '110', '101', '100', '011', '010', '001', '000'];
  const GANS = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  const ZHIS = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  const ZHI5 = [4, 2, 0, 0, 2, 1, 1, 2, 3, 3, 2, 4];
  const KONG = ['子丑', '寅卯', '辰巳', '午未', '申酉', '戌亥'];
  const LIUHE_NAMES = ['否', '困', '旅', '豫', '节', '贲', '复', '泰'];
  const LINE_LABELS = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
  const LINE_SHORT = ['初', '二', '三', '四', '五', '上'];
  const LINE_OPTIONS = [
    { value: 6, label: '6 · 老阴（动）' },
    { value: 7, label: '7 · 少阳' },
    { value: 8, label: '8 · 少阴' },
    { value: 9, label: '9 · 老阳（动）' },
  ];
  const BRANCH_CLASH = { 子: '午', 午: '子', 丑: '未', 未: '丑', 寅: '申', 申: '寅', 卯: '酉', 酉: '卯', 辰: '戌', 戌: '辰', 巳: '亥', 亥: '巳' };
  const BRANCH_COMBINE = { 子: '丑', 丑: '子', 寅: '亥', 亥: '寅', 卯: '戌', 戌: '卯', 辰: '酉', 酉: '辰', 巳: '申', 申: '巳', 午: '未', 未: '午' };
  const ELEMENT_GENERATES = { 木: '火', 火: '土', 土: '金', 金: '水', 水: '木' };
  const ELEMENT_CONTROLS = { 木: '土', 土: '水', 水: '火', 火: '金', 金: '木' };
  const SEXAGENARY = Array.from({ length: 60 }, (_, i) => `${GANS[i % 10]}${ZHIS[i % 12]}`);
  const REFERENCE_DAY = { date: new Date(1984, 1, 2, 12, 0, 0, 0), index: 2 }; // 丙寅日
  const REFERENCE_YEAR = 1984; // 甲子年
  const MONTH_BRANCH_BOUNDARIES = [
    { month: 1, day: 5, branch: '丑' }, { month: 2, day: 4, branch: '寅' }, { month: 3, day: 6, branch: '卯' },
    { month: 4, day: 5, branch: '辰' }, { month: 5, day: 6, branch: '巳' }, { month: 6, day: 6, branch: '午' },
    { month: 7, day: 7, branch: '未' }, { month: 8, day: 8, branch: '申' }, { month: 9, day: 8, branch: '酉' },
    { month: 10, day: 8, branch: '戌' }, { month: 11, day: 8, branch: '亥' }, { month: 12, day: 7, branch: '子' },
  ];
  const MONTH_BRANCH_ORDER = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];
  const HOUR_BRANCH_MAP = [
    { start: 23, end: 24, branch: '子' }, { start: 0, end: 1, branch: '子' },
    { start: 1, end: 3, branch: '丑' }, { start: 3, end: 5, branch: '寅' }, { start: 5, end: 7, branch: '卯' },
    { start: 7, end: 9, branch: '辰' }, { start: 9, end: 11, branch: '巳' }, { start: 11, end: 13, branch: '午' },
    { start: 13, end: 15, branch: '未' }, { start: 15, end: 17, branch: '申' }, { start: 17, end: 19, branch: '酉' },
    { start: 19, end: 21, branch: '戌' }, { start: 21, end: 23, branch: '亥' },
  ];
  const START_MONTH_STEM = { 甲: '丙', 己: '丙', 乙: '戊', 庚: '戊', 丙: '庚', 辛: '庚', 丁: '壬', 壬: '壬', 戊: '甲', 癸: '甲' };
  const START_HOUR_STEM = { 甲: '甲', 己: '甲', 乙: '丙', 庚: '丙', 丙: '戊', 辛: '戊', 丁: '庚', 壬: '庚', 戊: '壬', 癸: '壬' };
  const SHENSHA_BRANCH_GROUPS = {
    驿马: { '申子辰': '寅', '寅午戌': '申', '亥卯未': '巳', '巳酉丑': '亥' },
    桃花: { '申子辰': '酉', '寅午戌': '卯', '亥卯未': '子', '巳酉丑': '午' },
    华盖: { '申子辰': '辰', '寅午戌': '戌', '亥卯未': '未', '巳酉丑': '丑' },
  };
  const SHENSHA_DAY_STEM = {
    禄神: { 甲: ['寅'], 乙: ['卯'], 丙: ['巳'], 丁: ['午'], 戊: ['巳'], 己: ['午'], 庚: ['申'], 辛: ['酉'], 壬: ['亥'], 癸: ['子'] },
    羊刃: { 甲: ['卯'], 乙: ['寅'], 丙: ['午'], 丁: ['巳'], 戊: ['午'], 己: ['巳'], 庚: ['酉'], 辛: ['申'], 壬: ['子'], 癸: ['亥'] },
    文昌: { 甲: ['巳'], 乙: ['午'], 丙: ['申'], 丁: ['酉'], 戊: ['申'], 己: ['酉'], 庚: ['亥'], 辛: ['子'], 壬: ['寅'], 癸: ['卯'] },
    天乙贵人: { 甲: ['丑', '未'], 戊: ['丑', '未'], 庚: ['丑', '未'], 乙: ['子', '申'], 己: ['子', '申'], 丙: ['亥', '酉'], 丁: ['亥', '酉'], 辛: ['寅', '午'], 壬: ['卯', '巳'], 癸: ['卯', '巳'] },
    太极贵人: { 甲: ['子', '午'], 乙: ['子', '午'], 丙: ['卯', '酉'], 丁: ['卯', '酉'], 戊: ['辰', '戌', '丑', '未'], 己: ['辰', '戌', '丑', '未'], 庚: ['寅', '亥'], 辛: ['寅', '亥'], 壬: ['巳', '申'], 癸: ['巳', '申'] },
  };
  const SHENSHA_BRANCH_MORE = {
    将星: { '申子辰': '子', '寅午戌': '午', '亥卯未': '卯', '巳酉丑': '酉' },
    劫煞: { '申子辰': '巳', '寅午戌': '亥', '亥卯未': '申', '巳酉丑': '寅' },
    灾煞: { '申子辰': '午', '寅午戌': '子', '亥卯未': '酉', '巳酉丑': '卯' },
  };
  const SHENSHA_YEAR_BRANCH = {
    红鸾: { 子: '卯', 丑: '寅', 寅: '丑', 卯: '子', 辰: '亥', 巳: '戌', 午: '酉', 未: '申', 申: '未', 酉: '午', 戌: '巳', 亥: '辰' },
    天喜: { 子: '酉', 丑: '申', 寅: '未', 卯: '午', 辰: '巳', 巳: '辰', 午: '卯', 未: '寅', 申: '丑', 酉: '子', 戌: '亥', 亥: '戌' },
  };
  const SHENSHA_META = {
    驿马: '主奔波、迁动、出行、变化',
    桃花: '主人缘、情感、应酬、外缘',
    华盖: '主孤高、技术、艺术、玄思',
    将星: '主主导、掌控、执行、担当',
    劫煞: '主突发、耗散、冲击、失衡',
    灾煞: '主阻滞、惊扰、损耗、波折',
    禄神: '主俸禄、资源、得益、回报',
    羊刃: '主刚烈、竞争、冲劲、风险',
    文昌: '主文书、表达、考试、思路',
    天乙贵人: '主贵人、解厄、转机、帮扶',
    太极贵人: '主悟性、研究、灵感、玄学',
    红鸾: '主缘分、婚恋、喜庆、和合',
    天喜: '主喜事、喜信、和合、欢庆',
  };

  const state = {
    chart: null,
    selectedNodeId: null,
    useGodId: null,
    inputMode: 'manual',
    autoLines: [],
    autoDetail: null,
  };

  const els = {
    divinationTime: document.getElementById('divinationTime'),
    nowBtn: document.getElementById('nowBtn'),
    autoDerive: document.getElementById('autoDerive'),
    monthBranch: document.getElementById('monthBranch'),
    dayStem: document.getElementById('dayStem'),
    dayBranch: document.getElementById('dayBranch'),
    derivedInfo: document.getElementById('derivedInfo'),
    lineInputs: document.getElementById('lineInputs'),
    manualInputPanel: document.getElementById('manualInputPanel'),
    autoInputPanel: document.getElementById('autoInputPanel'),
    autoCaption: document.getElementById('autoCaption'),
    autoPreview: document.getElementById('autoPreview'),
    autoMeta: document.getElementById('autoMeta'),
    autoRefreshBtn: document.getElementById('autoRefreshBtn'),
    sampleBtn: document.getElementById('sampleBtn'),
    renderBtn: document.getElementById('renderBtn'),
    copyChartBtn: document.getElementById('copyChartBtn'),
    copyFeedback: document.getElementById('copyFeedback'),
    useGodChooser: document.getElementById('useGodChooser'),
    summary: document.getElementById('summary'),
    primaryColumn: document.getElementById('primaryColumn'),
    changedColumn: document.getElementById('changedColumn'),
    detailDrawer: document.getElementById('detailDrawer'),
    methodRadios: document.querySelectorAll('input[name="inputMode"]'),
    methodItems: document.querySelectorAll('.method-item'),
  };

  init();

  function init() {
    fillSelect(els.monthBranch, ZHIS);
    fillSelect(els.dayStem, GANS);
    fillSelect(els.dayBranch, ZHIS);
    buildLineInputs();
    setTimeInputToNow();
    bindEvents();
    syncDerivedFromTime();
    regenerateAutoLines({ mode: 'time', syncTimeToNow: false });
  }

  function bindEvents() {
    els.nowBtn.addEventListener('click', () => {
      setTimeInputToNow();
      syncDerivedFromTime();
      if (state.inputMode === 'time') {
        regenerateAutoLines({ mode: 'time', syncTimeToNow: false });
      } else {
        renderAutoPreview();
      }
    });
    els.autoDerive.addEventListener('change', () => {
      syncDerivedFromTime();
      renderAutoPreview();
    });
    els.divinationTime.addEventListener('change', () => {
      syncDerivedFromTime();
      if (state.inputMode === 'time') {
        regenerateAutoLines({ mode: 'time', syncTimeToNow: false });
      } else {
        renderAutoPreview();
      }
    });
    els.monthBranch.addEventListener('change', renderAutoPreview);
    els.dayStem.addEventListener('change', renderAutoPreview);
    els.dayBranch.addEventListener('change', renderAutoPreview);
    els.sampleBtn.addEventListener('click', fillSample);
    els.renderBtn.addEventListener('click', onRender);
    els.copyChartBtn.addEventListener('click', onCopyChart);
    els.autoRefreshBtn.addEventListener('click', onAutoRefresh);
    els.methodRadios.forEach((radio) => {
      radio.addEventListener('change', () => {
        if (!radio.checked) return;
        state.inputMode = radio.value;
        els.methodItems.forEach((item) => {
          const control = item.querySelector('input[name="inputMode"]');
          item.classList.toggle('active', !!control?.checked);
        });
        const isManual = state.inputMode === 'manual';
        els.manualInputPanel.classList.toggle('hidden', !isManual);
        els.autoInputPanel.classList.toggle('hidden', isManual);
        if (!isManual) regenerateAutoLines({ mode: state.inputMode, syncTimeToNow: state.inputMode === 'time' });
        else renderAutoPreview();
      });
    });
    window.addEventListener('resize', () => renderDrawer());
  }

  function fillSelect(select, values) {
    select.innerHTML = values.map((v) => `<option value="${v}">${v}</option>`).join('');
  }

  function buildLineInputs() {
    els.lineInputs.innerHTML = '';
    for (let i = 0; i < 6; i += 1) {
      const row = document.createElement('div');
      row.className = 'line-row';
      row.innerHTML = `
        <div class="line-index">${LINE_LABELS[i]}</div>
        <select data-line-input="${i + 1}">
          ${LINE_OPTIONS.map((opt) => `<option value="${opt.value}">${opt.label}</option>`).join('')}
        </select>
      `;
      els.lineInputs.appendChild(row);
    }
  }

  function fillSample() {
    const sample = [7, 8, 7, 9, 8, 7];
    setTimeInputToNow();
    syncDerivedFromTime();
    [...els.lineInputs.querySelectorAll('select')].forEach((select, idx) => { select.value = String(sample[idx]); });
  }

  function setTimeInputToNow() {
    els.divinationTime.value = toDateTimeLocalString(new Date());
  }

  function getInputDateOrNow() {
    if (!els.divinationTime.value) setTimeInputToNow();
    const raw = els.divinationTime.value;
    const date = raw ? new Date(raw) : new Date();
    if (Number.isNaN(date.getTime())) {
      const now = new Date();
      els.divinationTime.value = toDateTimeLocalString(now);
      return now;
    }
    return date;
  }

  function syncDerivedFromTime() {
    const date = getInputDateOrNow();
    const calendar = deriveCalendarMarkers(date);
    const auto = els.autoDerive.checked;

    els.monthBranch.disabled = auto;
    els.dayStem.disabled = auto;
    els.dayBranch.disabled = auto;

    if (auto) {
      els.monthBranch.value = calendar.monthBranch;
      els.dayStem.value = calendar.dayGanzhi[0];
      els.dayBranch.value = calendar.dayGanzhi[1];
    }

    const sourceLabel = auto ? '自动换算' : '手工覆盖';
    els.derivedInfo.innerHTML = `
      <div class="derived-badges">
        <span class="pill">${sourceLabel}</span>
        <span class="pill">${calendar.sourceLabel}</span>
        <span class="pill">年柱 ${calendar.yearGanzhi}</span>
        <span class="pill">月柱 ${calendar.monthGanzhi}</span>
        <span class="pill">日柱 ${calendar.dayGanzhi}</span>
        <span class="pill">时柱 ${calendar.hourGanzhi}</span>
        <span class="pill">年空 ${calendar.yearXunkong}</span>
        <span class="pill">月空 ${calendar.monthXunkong}</span>
        <span class="pill">日空 ${calendar.dayXunkong}</span>
        <span class="pill">时空 ${calendar.hourXunkong}</span>
        <span class="pill">节气 ${calendar.jieQi || '—'}</span>
        <span class="pill">月建 ${els.monthBranch.value}</span>
        <span class="pill">日辰 ${els.dayStem.value}${els.dayBranch.value}</span>
      </div>
    `;
  }

  function renderAutoPreview() {
    const lines = state.autoLines.length ? state.autoLines : (state.inputMode === 'coin' ? generateCoinLines().lines : generateTimeLines(getInputDateOrNow()));
    const mode = state.inputMode === 'coin' ? 'coin' : 'time';
    const meta = state.autoDetail || buildAutoDetail(mode, { lines, date: getInputDateOrNow() });
    if (els.autoCaption) els.autoCaption.textContent = getAutoCaption(mode);
    if (els.autoRefreshBtn) els.autoRefreshBtn.textContent = mode === 'coin' ? '再摇一次铜钱' : '取当前时刻并重算';
    els.autoPreview.innerHTML = lines.map((value, idx) => `<div class="auto-chip"><strong>${LINE_SHORT[idx]}</strong><span>${value}</span></div>`).join('');
    if (els.autoMeta) {
      els.autoMeta.innerHTML = (meta.pills || []).map((pill) => `<span class="pill muted-pill">${pill}</span>`).join('');
    }
  }

  function onAutoRefresh() {
    if (state.inputMode === 'coin') {
      regenerateAutoLines({ mode: 'coin' });
      return;
    }
    regenerateAutoLines({ mode: 'time', syncTimeToNow: true });
  }

  function regenerateAutoLines({ mode = state.inputMode === 'coin' ? 'coin' : 'time', syncTimeToNow = false } = {}) {
    if (mode === 'time' && syncTimeToNow) {
      setTimeInputToNow();
      syncDerivedFromTime();
    }
    const date = getInputDateOrNow();
    const result = mode === 'coin' ? generateCoinLines() : { lines: generateTimeLines(date) };
    state.autoLines = result.lines.slice();
    state.autoDetail = buildAutoDetail(mode, { ...result, date });
    renderAutoPreview();
    return state.autoLines;
  }

  function getAutoCaption(mode) {
    return mode === 'coin'
      ? '模拟三枚铜钱起卦；少阴/少阳概率更高，老阴/老阳概率更低。'
      : '按占测时间映射 6 个爻值；同一时刻会得到同一结果，便于复盘。';
  }

  function buildAutoDetail(mode, payload = {}) {
    if (mode === 'coin') {
      return {
        mode,
        pills: [
          '三枚铜钱模拟',
          '6/9 各 12.5%',
          '7/8 各 37.5%',
          `本次结果 ${payload.lines.join(' / ')}`,
        ],
      };
    }
    return {
      mode,
      pills: [
        '时间映射（可复现）',
        `占测时刻 ${formatDateTimeDisplay(payload.date || getInputDateOrNow())}`,
        '同一时刻结果固定',
        `本次结果 ${(payload.lines || []).join(' / ')}`,
      ],
    };
  }

  function getInputModeLabel(mode) {
    if (mode === 'time') return '时间起卦（按时刻映射）';
    if (mode === 'coin') return '铜钱起卦（三枚铜钱）';
    return '手工输入六爻';
  }

  async function onCopyChart() {
    if (!state.chart) onRender();
    if (!state.chart) {
      setCopyFeedback('当前没有可复制的排盘内容。', true);
      return;
    }
    const text = buildChartExportText(state.chart);
    try {
      await copyText(text);
      setCopyFeedback(`已复制 ${text.length} 字到剪切板，可直接贴给大模型解卦。`);
    } catch (error) {
      console.error(error);
      setCopyFeedback('复制失败，请检查浏览器剪切板权限。', true);
    }
  }

  function setCopyFeedback(message, isError = false) {
    if (!els.copyFeedback) return;
    els.copyFeedback.textContent = message;
    els.copyFeedback.classList.toggle('error-text', !!isError);
    els.copyFeedback.classList.toggle('success-text', !isError);
    window.clearTimeout(setCopyFeedback._timer);
    setCopyFeedback._timer = window.setTimeout(() => {
      els.copyFeedback.textContent = '会复制成适合直接贴给大模型解卦的纯文本。';
      els.copyFeedback.classList.remove('error-text', 'success-text');
    }, 3200);
  }

  async function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.setAttribute('readonly', 'readonly');
    textarea.style.position = 'fixed';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();
    const ok = document.execCommand('copy');
    document.body.removeChild(textarea);
    if (!ok) throw new Error('copy failed');
  }

  function buildChartExportText(chart) {
    const roleNodes = getRoleNodeSummary(chart);
    const rawValues = chart.rawValues || [...els.lineInputs.querySelectorAll('select')].map((s) => Number(s.value));
    const nodeSection = (title, nodes) => [title, ...nodes.slice().reverse().map((node) => formatNodeExport(node, chart))].join('\n');
    const edgeSection = chart.allNodes.slice().reverse().map((node) => {
      const incomingEdges = chart.edges.filter((e) => e.target === node.id).sort((a, b) => Math.abs(b.weight) - Math.abs(a.weight));
      const modifiers = chart.modifiers.filter((m) => m.target === node.id).sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta));
      return [
        `【${node.column === 'primary' ? '本卦' : '变卦'}${node.lineLabel} ${node.kinship}${node.branch}${node.element}】`,
        incomingEdges.length ? '流入边：' : '流入边：无',
        ...(incomingEdges.length ? incomingEdges.map((edge) => `- ${edge.sourceLabel} → ${edge.type} → ${edge.targetLabel} = ${signed(edge.weight)}；${edge.reason}`) : []),
        modifiers.length ? '状态修正：' : '状态修正：无',
        ...(modifiers.length ? modifiers.map((modifier) => `- ${modifier.type}/${modifier.dimension} ${signed(modifier.delta)}；${modifier.reason}`) : []),
      ].join('\n');
    }).join('\n\n');

    const lines = [
      '=== 六爻排盘全文（供大模型解卦） ===',
      '',
      '【基础信息】',
      `起卦时间：${chart.noteTime}`,
      `起卦方式：${chart.inputModeLabel || getInputModeLabel(chart.inputMode)}`,
      `六爻输入（自下而上）：${rawValues.join(' / ')}`,
      `本卦：${chart.mainName}${chart.mainType ? `（${chart.mainType}）` : ''}`,
      `变卦：${chart.changedName}${chart.changedType ? `（${chart.changedType}）` : ''}`,
      `卦宫：${chart.gongName}`,
      `本卦世应：${describeShiYing(chart.primaryNodes)}`,
      `变卦世应：${describeShiYing(chart.changedNodes)}`,
      '',
      '【时令环境】',
      `四柱：年柱 ${chart.calendar.yearGanzhi} / 月柱 ${chart.calendar.monthGanzhi} / 日柱 ${chart.calendar.dayGanzhi} / 时柱 ${chart.calendar.hourGanzhi}`,
      `四柱旬空：年空 ${chart.calendar.yearXunkong} / 月空 ${chart.calendar.monthXunkong} / 日空 ${chart.calendar.dayXunkong} / 时空 ${chart.calendar.hourXunkong}`,
      `节气：${chart.calendar.jieQi || '—'}`,
      `月建：${chart.monthBranch}`,
      `日辰：${chart.dayGanzhi}`,
      `本卦旬空参考：${chart.xunkong}`,
      `历法来源：${chart.calendar.sourceLabel}`,
      '',
      '【用神体系】',
      `用神：${chart.useNode ? `${chart.useNode.lineLabel} ${chart.useNode.kinship}${chart.useNode.branch}${chart.useNode.element}` : '未指定'}`,
      `原神：${roleNodes ? (roleNodes.original.join('、') || '无') : '未指定'}`,
      `忌神：${roleNodes ? (roleNodes.ji.join('、') || '无') : '未指定'}`,
      `仇神：${roleNodes ? (roleNodes.chou.join('、') || '无') : '未指定'}`,
      '',
      '【神煞总览】',
      ...(chart.shensha.length ? chart.shensha.map((item) => `- ${item.label}${item.branches && item.branches.length ? `：${item.branches.join('、')}` : ''}（来源：${item.source}）`) : ['- 无']),
      '',
      nodeSection('【本卦六爻】', chart.primaryNodes),
      '',
      nodeSection('【变卦六爻】', chart.changedNodes),
      '',
      '【全部边关系与状态修正】',
      edgeSection,
      '',
      '【提示】',
      '- 这是结构化排盘与关系账单，便于继续让大模型做断卦解释。',
      '- 飞神/伏神已进入节点五维状态与回流关系。',
    ];
    return lines.join('\n');
  }

  function buildNodeCalendarSummary(node, chart) {
    const parts = [];
    if (node.branch === chart.monthBranch) parts.push('临月建');
    if (node.branch === chart.dayGanzhi[1]) parts.push('临日辰');
    if (node.combineWithMonth) parts.push('与月建合');
    if (node.combineWithDay) parts.push('与日辰合');
    if (node.monthBreak) parts.push('受月冲');
    if (node.dayBreak) parts.push('受日冲');
    if (node.isEmpty) parts.push(`落旬空(${chart.xunkong})`);
    return parts.length ? `${parts.join('；')}；` : '—';
  }

  function formatNodeExport(node, chart) {
    const tags = [
      node.spirit,
      node.isShi ? '世' : '',
      node.isYing ? '应' : '',
      node.isUseGod ? '用神' : '',
      node.isOriginalGod ? '原神' : '',
      node.isJiGod ? '忌神' : '',
      node.isChouGod ? '仇神' : '',
      node.moving ? '动爻' : '静爻',
      node.isEmpty ? '旬空' : '',
      node.monthBreak ? '月破' : '',
      node.dayBreak ? '日破/日冲' : '',
    ].filter(Boolean);
    const hiddenText = node.hiddenSpirits.length
      ? node.hiddenSpirits.map((hidden) => `${hidden.kinship}${hidden.branch}${hidden.element}[${hidden.flyRelationLabel}; 潜藏${hidden.hiddenDepth.toFixed(2)}; 显化${hidden.manifest.toFixed(2)}; 暗旺${hidden.hiddenMetrics.strength.toFixed(2)}; 暗动${hidden.hiddenMetrics.active.toFixed(2)}; 暗实${hidden.hiddenMetrics.reality.toFixed(2)}; 回流助${hidden.feedbackSupport.toFixed(2)}/制${hidden.feedbackPressure.toFixed(2)}/旺${signed(hidden.feedbackStrength)}/动${signed(hidden.feedbackActive)}/虚实${signed(hidden.feedbackReality)}]`).join('；')
      : '无';
    const shaText = node.shenSha.length
      ? node.shenSha.map((item) => `${item.label}（${item.source}）`).join('；')
      : '无';
    return [
      `- ${node.lineLabel}｜${node.kinship}${node.branch}${node.element}｜纳甲 ${node.gz}｜${node.displayYinYang}${node.moving ? '动' : '静'}｜标签：${tags.join(' / ') || '无'}`,
      `  五维：旺衰 ${node.metrics.strength.toFixed(2)}｜发动 ${node.metrics.active.toFixed(2)}｜虚实 ${node.metrics.reality.toFixed(2)}｜受助 ${node.metrics.support.toFixed(2)}｜受制 ${node.metrics.pressure.toFixed(2)}`,
      `  月日：${buildNodeCalendarSummary(node, chart)}`,
      `  伏神：${hiddenText}`,
      `  神煞：${shaText}`,
    ].join('\n');
  }

  function getRoleNodeSummary(chart) {
    if (!chart.roleInfo) return null;
    const byElement = (element) => chart.primaryNodes.filter((node) => node.element === element).map((node) => `${node.lineShort}·${node.kinship}${node.branch}${node.element}`);
    return {
      original: chart.roleInfo.originalElement ? byElement(chart.roleInfo.originalElement) : [],
      ji: chart.roleInfo.jiElement ? byElement(chart.roleInfo.jiElement) : [],
      chou: chart.roleInfo.chouElement ? byElement(chart.roleInfo.chouElement) : [],
    };
  }

  function onRender() {
    const date = getInputDateOrNow();
    const calendar = deriveCalendarMarkers(date);
    const effectiveMonthBranch = els.monthBranch.value;
    const effectiveDayGanzhi = `${els.dayStem.value}${els.dayBranch.value}`;
    const rawValues = state.inputMode === 'manual'
      ? [...els.lineInputs.querySelectorAll('select')].map((s) => Number(s.value))
      : (state.autoLines.length ? state.autoLines.slice() : regenerateAutoLines({ mode: state.inputMode, syncTimeToNow: state.inputMode === 'time' }));

    const chart = buildChart({
      rawValues,
      calendar,
      monthBranch: effectiveMonthBranch,
      dayGanzhi: effectiveDayGanzhi,
      noteTime: formatDateTimeDisplay(date),
      inputMode: state.inputMode,
      inputModeLabel: getInputModeLabel(state.inputMode),
    });

    state.chart = chart;
    if (!chart.primaryNodes.some((n) => n.id === state.useGodId)) state.useGodId = null;
    decorateUseGod(chart);
    if (!state.selectedNodeId || !chart.allNodes.some((n) => n.id === state.selectedNodeId)) {
      state.selectedNodeId = chart.primaryNodes.find((n) => n.isShi)?.id || chart.primaryNodes[0]?.id || null;
    }

    renderUseGodChooser(chart);
    renderSummary(chart);
    renderColumns(chart);
    renderDrawer();
  }

  function buildChart({ rawValues, calendar, monthBranch, dayGanzhi, noteTime, inputMode, inputModeLabel }) {
    const mark = rawValues.map((v) => String(v % 2)).join('');
    const changedRawValues = rawValues.map((v) => (v === 6 ? 7 : v === 9 ? 8 : v));
    const changedMark = changedRawValues.map((v) => String(v % 2)).join('');
    const shiy = setShiYao(mark);
    const changedShiy = setShiYao(changedMark);
    const gongIndex = palace(mark, shiy[0]);
    const god6 = getGod6(dayGanzhi);
    const xunkong = getXunkong(dayGanzhi);

    const primaryNodes = buildNodes({ column: 'primary', mark, rawValues, gongIndex, god6, shiy, xunkong, monthBranch, dayGanzhi });
    const changedNodes = buildNodes({ column: 'changed', mark: changedMark, rawValues: changedRawValues, gongIndex, god6, shiy: changedShiy, xunkong, monthBranch, dayGanzhi });

    const hiddenSpirits = getHiddenSpirits(gongIndex, primaryNodes.map((n) => n.kinship));
    hiddenSpirits.forEach((hidden) => {
      const host = primaryNodes[hidden.position - 1];
      if (!host) return;
      host.hiddenSpirits = host.hiddenSpirits || [];
      const interaction = describeHiddenInteraction(host.element, hidden.element);
      const hiddenState = computeHiddenSpiritState({ hidden, host, monthBranch, dayGanzhi, xunkong, interaction });
      host.hiddenSpirits.push({
        ...hidden,
        hostId: host.id,
        hostLabel: labelNode(host),
        flyRelation: interaction.relation,
        flyRelationLabel: interaction.label,
        flyHint: interaction.hint,
        ...hiddenState,
      });
    });

    const shensha = computeShenSha(calendar);
    annotateNodeShenSha(primaryNodes, shensha);
    annotateNodeShenSha(changedNodes, shensha);

    const edges = [];
    const modifiers = [];

    createEnvEdges({ nodes: primaryNodes, monthBranch, dayGanzhi, xunkong, edges, modifiers, stronger: true });
    createEnvEdges({ nodes: changedNodes, monthBranch, dayGanzhi, xunkong, edges, modifiers, stronger: false });
    createHiddenSpiritEffects({ nodes: primaryNodes, edges, modifiers });
    createPairEdges({ nodes: primaryNodes, edges, intensity: 1.0 });
    createPairEdges({ nodes: changedNodes, edges, intensity: 0.84 });
    createTransformEdges({ primaryNodes, changedNodes, rawValues, edges, modifiers });

    const allNodes = [...primaryNodes, ...changedNodes];
    allNodes.forEach((node) => {
      const incomingEdges = edges.filter((edge) => edge.target === node.id);
      const incomingModifiers = modifiers.filter((modifier) => modifier.target === node.id);
      node.metrics = calculateMetrics(node, incomingEdges, incomingModifiers);
    });

    return {
      noteTime,
      monthBranch,
      dayGanzhi,
      xunkong,
      inputMode,
      inputModeLabel,
      rawValues: rawValues.slice(),
      mark,
      changedMark,
      gongName: GUAS[gongIndex],
      mainName: GUA64[mark] || '未知卦',
      changedName: GUA64[changedMark] || '未知卦',
      mainType: getHexagramType(mark),
      changedType: getHexagramType(changedMark),
      calendar,
      shensha,
      hiddenSpirits,
      primaryNodes,
      changedNodes,
      edges,
      modifiers,
      allNodes,
    };
  }

  function buildNodes({ column, mark, rawValues, gongIndex, god6, shiy, xunkong, monthBranch, dayGanzhi }) {
    const najia = getNajia(mark);
    const qin6 = najia.map((gz) => getQin6(XING5[GUA5[gongIndex]], XING5[ZHI5[ZHIS.indexOf(gz[1])]]));
    return rawValues.map((rawValue, idx) => {
      const gz = najia[idx];
      const branch = gz[1];
      const element = XING5[ZHI5[ZHIS.indexOf(branch)]];
      return {
        id: `${column === 'primary' ? 'L' : 'C'}${idx + 1}`,
        column,
        position: idx + 1,
        lineLabel: LINE_LABELS[idx],
        lineShort: LINE_SHORT[idx],
        rawValue,
        moving: rawValue === 6 || rawValue === 9,
        markBit: mark[idx],
        displayYinYang: mark[idx] === '1' ? '阳' : '阴',
        kinship: qin6[idx],
        stem: gz[0],
        branch,
        element,
        spirit: god6[idx],
        gz,
        isShi: shiy[0] === idx + 1,
        isYing: shiy[1] === idx + 1,
        isEmpty: xunkong.includes(branch),
        monthBreak: isClash(branch, monthBranch),
        dayBreak: isClash(branch, dayGanzhi[1]),
        combineWithMonth: isCombine(branch, monthBranch),
        combineWithDay: isCombine(branch, dayGanzhi[1]),
        hiddenSpirits: [],
        shenSha: [],
        isUseGod: false,
        isOriginalGod: false,
        isJiGod: false,
        isChouGod: false,
        metrics: null,
      };
    });
  }

  function getHiddenSpirits(gongIndex, qins) {
    if (new Set(qins).size >= 5) return [];
    const pureMark = YAOS[gongIndex] + YAOS[gongIndex];
    const pureNajia = getNajia(pureMark);
    const pureQin6 = pureNajia.map((gz) => getQin6(XING5[GUA5[gongIndex]], XING5[ZHI5[ZHIS.indexOf(gz[1])]]));
    const missing = [...new Set(pureQin6.filter((qin) => !qins.includes(qin)))];
    return missing.map((qin) => {
      const index = pureQin6.indexOf(qin);
      const gz = pureNajia[index];
      return {
        position: index + 1,
        kinship: qin,
        gz,
        branch: gz[1],
        element: XING5[ZHI5[ZHIS.indexOf(gz[1])]],
      };
    });
  }

  function computeShenSha(calendar) {
    const dayStem = calendar.dayGanzhi[0];
    const dayBranch = calendar.dayGanzhi[1];
    const yearBranch = calendar.yearGanzhi[1];
    const result = [];

    Object.entries(SHENSHA_BRANCH_GROUPS).forEach(([name, mapping]) => {
      const fromDay = resolveByBranchGroup(dayBranch, mapping);
      const fromYear = resolveByBranchGroup(yearBranch, mapping);
      if (fromDay) result.push(makeSha(name, [fromDay], '日支'));
      if (fromYear && fromYear !== fromDay) result.push(makeSha(name, [fromYear], '年支'));
    });

    Object.entries(SHENSHA_BRANCH_MORE).forEach(([name, mapping]) => {
      const fromDay = resolveByBranchGroup(dayBranch, mapping);
      const fromYear = resolveByBranchGroup(yearBranch, mapping);
      if (fromDay) result.push(makeSha(name, [fromDay], '日支'));
      if (fromYear && fromYear !== fromDay) result.push(makeSha(name, [fromYear], '年支'));
    });

    Object.entries(SHENSHA_DAY_STEM).forEach(([name, mapping]) => {
      const branches = mapping[dayStem] || [];
      if (branches.length) result.push(makeSha(name, branches, '日干'));
    });

    Object.entries(SHENSHA_YEAR_BRANCH).forEach(([name, mapping]) => {
      const branch = mapping[yearBranch];
      if (branch) result.push(makeSha(name, [branch], '年支'));
    });

    const extraJi = (calendar.dayJiShen || []).filter((x) => x && x !== '无').map((name) => ({ name, label: `${name}（吉神宜趋）`, branches: [], source: '黄历吉神', summary: '源自当日吉神宜趋。', isGlobal: true }));
    const extraXiong = (calendar.dayXiongSha || []).filter((x) => x && x !== '无').map((name) => ({ name, label: `${name}（凶煞宜忌）`, branches: [], source: '黄历凶煞', summary: '源自当日凶煞宜忌。', isGlobal: true }));

    return uniqueByKey([...result, ...extraJi, ...extraXiong], (item) => `${item.name}:${item.branches.join(',')}:${item.source}`);
  }

  function makeSha(name, branches, source) {
    const summary = SHENSHA_META[name] || '主取象辅助。';
    return { name, branches, source, summary, label: `${name}(主${summary.replace(/^主/, '')})`, isGlobal: false };
  }

  function resolveByBranchGroup(branch, mapping) {
    return Object.entries(mapping).find(([group]) => group.includes(branch))?.[1] || null;
  }

  function annotateNodeShenSha(nodes, shensha) {
    nodes.forEach((node) => {
      node.shenSha = shensha.filter((item) => !item.isGlobal && item.branches.includes(node.branch));
    });
  }

  function decorateUseGod(chart) {
    const useNode = chart.primaryNodes.find((node) => node.id === state.useGodId) || null;
    const roleInfo = useNode ? getUseGodRoles(useNode.element) : null;

    chart.allNodes.forEach((node) => {
      node.isUseGod = useNode ? node.id === useNode.id : false;
      node.isOriginalGod = !!roleInfo && node.element === roleInfo.originalElement;
      node.isJiGod = !!roleInfo && node.element === roleInfo.jiElement;
      node.isChouGod = !!roleInfo && node.element === roleInfo.chouElement;
    });

    chart.roleInfo = roleInfo;
    chart.useNode = useNode;
  }

  function getUseGodRoles(useElement) {
    const originalElement = Object.keys(ELEMENT_GENERATES).find((key) => ELEMENT_GENERATES[key] === useElement);
    const jiElement = Object.keys(ELEMENT_CONTROLS).find((key) => ELEMENT_CONTROLS[key] === useElement);
    const chouElement = originalElement ? Object.keys(ELEMENT_CONTROLS).find((key) => ELEMENT_CONTROLS[key] === originalElement) : null;
    return { originalElement, jiElement, chouElement };
  }

  function renderUseGodChooser(chart) {
    if (!chart.primaryNodes.length) {
      els.useGodChooser.className = 'use-god-chooser empty-state';
      els.useGodChooser.innerHTML = '请先装卦';
      return;
    }
    els.useGodChooser.className = 'use-god-chooser';
    els.useGodChooser.innerHTML = chart.primaryNodes.slice().reverse().map((node) => `
      <label class="use-god-item">
        <input type="radio" name="useGod" value="${node.id}" ${state.useGodId === node.id ? 'checked' : ''} />
        <span>${node.lineLabel} · ${node.kinship}${node.branch}${node.element} · ${node.spirit}${node.isShi ? ' · 世' : ''}${node.isYing ? ' · 应' : ''}</span>
      </label>
    `).join('');

    els.useGodChooser.querySelectorAll('input[name="useGod"]').forEach((radio) => {
      radio.addEventListener('change', () => {
        state.useGodId = radio.value;
        decorateUseGod(chart);
        renderSummary(chart);
        renderColumns(chart);
        renderDrawer();
      });
    });
  }

  function renderSummary(chart) {
    const useNode = chart.useNode;
    const roleInfo = chart.roleInfo;
    const roleNodes = roleInfo ? {
      original: chart.primaryNodes.filter((n) => n.isOriginalGod).map(shortNodeLabel),
      ji: chart.primaryNodes.filter((n) => n.isJiGod).map(shortNodeLabel),
      chou: chart.primaryNodes.filter((n) => n.isChouGod).map(shortNodeLabel),
    } : null;
    const shaNodeHtml = chart.shensha.filter((item) => !item.isGlobal).length
      ? chart.shensha.filter((item) => !item.isGlobal).map((item) => `<span class="role-pill sha" title="${item.summary}">${item.label}：${item.branches.join('、')}（${item.source}）</span>`).join('')
      : '<span class="muted small">未命中节点常用神煞</span>';
    const fullDayShensha = [
      ...(chart.calendar.dayJiShen || []).filter((x) => x && x !== '无').map((name) => ({ tone: 'good', name })),
      ...(chart.calendar.dayXiongSha || []).filter((x) => x && x !== '无').map((name) => ({ tone: 'bad', name })),
    ];

    els.summary.classList.remove('empty-state');
    els.summary.innerHTML = `
      <div class="summary-grid">
        <div class="summary-card">
          <div class="muted small">本卦</div>
          <strong>${chart.mainName}</strong>
          <div class="muted small">卦宫 ${chart.gongName}${chart.mainType ? ` · ${chart.mainType}` : ''}</div>
          <div class="tiny-list">世应：${describeShiYing(chart.primaryNodes)}</div>
        </div>
        <div class="summary-card">
          <div class="muted small">变卦</div>
          <strong>${chart.changedName}</strong>
          <div class="muted small">${chart.changedType || '无特殊标记'}</div>
          <div class="tiny-list">世应：${describeShiYing(chart.changedNodes)}</div>
        </div>
        <div class="summary-card">
          <div class="muted small">四柱 / 旬空 / 节气</div>
          <div class="tiny-list">年柱：${chart.calendar.yearGanzhi} · 旬空 ${chart.calendar.yearXunkong}</div>
          <div class="tiny-list">月柱：${chart.calendar.monthGanzhi} · 旬空 ${chart.calendar.monthXunkong}</div>
          <div class="tiny-list">日柱：${chart.calendar.dayGanzhi} · 旬空 ${chart.calendar.dayXunkong}</div>
          <div class="tiny-list">时柱：${chart.calendar.hourGanzhi} · 旬空 ${chart.calendar.hourXunkong}</div>
          <div class="tiny-list">当前节气：${chart.calendar.jieQi || '—'} · 历法：${chart.calendar.sourceLabel}</div>
          <div class="tiny-list muted">起卦时间：${chart.noteTime}</div>
        </div>
        <div class="summary-card">
          <div class="muted small">时令环境 / 用神</div>
          <strong>${useNode ? `${useNode.lineShort} · ${useNode.kinship}${useNode.branch}${useNode.element}` : '未指定'}</strong>
          <div class="tiny-list">月建：${chart.monthBranch}${XING5[ZHI5[ZHIS.indexOf(chart.monthBranch)]]} · 日辰：${chart.dayGanzhi}</div>
          <div class="tiny-list">起卦方式：${chart.inputModeLabel || getInputModeLabel(chart.inputMode)}</div>
          ${roleNodes ? `
            <div class="role-list">
              <span class="role-pill original">原神：${roleNodes.original.join('、') || '无'}</span>
              <span class="role-pill ji">忌神：${roleNodes.ji.join('、') || '无'}</span>
              <span class="role-pill chou">仇神：${roleNodes.chou.join('、') || '无'}</span>
            </div>
          ` : ''}
        </div>
      </div>
      <div class="section-title summary-subtitle">节点神煞</div>
      <div class="role-list">${shaNodeHtml}</div>
      <div class="section-title summary-subtitle">完整当日吉神 / 凶煞</div>
      <div class="role-list">${fullDayShensha.length ? fullDayShensha.map((item) => `<span class="role-pill ${item.tone === 'good' ? 'original' : 'ji'}">${item.name}</span>`).join('') : '<span class="muted small">无</span>'}</div>
    `;
  }

  function describeShiYing(nodes) {
    const shi = nodes.find((n) => n.isShi);
    const ying = nodes.find((n) => n.isYing);
    return `${shi ? `${shi.lineShort}爻世` : '无'} / ${ying ? `${ying.lineShort}爻应` : '无'}`;
  }

  function renderColumns(chart) {
    els.primaryColumn.innerHTML = chart.primaryNodes.slice().reverse().map(renderNodeCard).join('');
    els.changedColumn.innerHTML = chart.changedNodes.slice().reverse().map(renderNodeCard).join('');
    [...document.querySelectorAll('.line-card')].forEach((card) => {
      card.addEventListener('click', () => {
        state.selectedNodeId = card.dataset.nodeId;
        renderColumns(chart);
        renderDrawer();
      });
    });
  }

  function renderNodeCard(node) {
    const tags = [
      `<span class="tag">${node.spirit}</span>`,
      node.isShi ? '<span class="tag shi">世</span>' : '',
      node.isYing ? '<span class="tag ying">应</span>' : '',
      node.isUseGod ? '<span class="tag use">用神</span>' : '',
      node.isOriginalGod ? '<span class="tag original">原神</span>' : '',
      node.isJiGod ? '<span class="tag ji">忌神</span>' : '',
      node.isChouGod ? '<span class="tag chou">仇神</span>' : '',
      node.moving ? '<span class="tag status">动</span>' : '',
      node.isEmpty ? '<span class="tag status">空</span>' : '',
      node.hiddenSpirits.length ? '<span class="tag status">伏</span>' : '',
      node.hiddenSpirits.some((item) => item.manifest >= 0.5) ? '<span class="tag status">透</span>' : '',
      ...node.shenSha.slice(0, 2).map((item) => `<span class="tag sha" title="${item.summary}">${item.name}</span>`),
    ].filter(Boolean).join('');

    const metrics = [
      ['旺', node.metrics.strength], ['动', node.metrics.active], ['虚', node.metrics.reality], ['助', node.metrics.support], ['制', node.metrics.pressure],
    ];
    const hiddenLine = node.hiddenSpirits.length
      ? `<div class="subline emphasize">伏：${node.hiddenSpirits.map(renderHiddenSummary).join('、')}</div>`
      : '';
    const shaLine = node.shenSha.length
      ? `<div class="subline sha-line">煞：${node.shenSha.slice(0, 2).map((item) => item.label).join('、')}</div>`
      : '';

    return `
      <article class="line-card ${node.column === 'changed' ? 'changed' : ''} ${state.selectedNodeId === node.id ? 'active' : ''}" data-node-id="${node.id}">
        <div class="card-top">
          <div class="card-title">
            <span class="line-pos">${node.lineShort}</span>
            <span class="main-label">${node.kinship}${node.branch}${node.element}</span>
            <span class="sub-label">${node.displayYinYang}${node.moving ? '·动' : ''} · ${node.gz}</span>
          </div>
          <span class="sub-label">${node.column === 'primary' ? '本' : '变'}</span>
        </div>
        <div class="tags">${tags}</div>
        ${hiddenLine}
        ${shaLine}
        <div class="metrics">
          ${metrics.map(([name, value]) => `<div class="metric"><span>${name}</span><strong>${value.toFixed(2)}</strong></div>`).join('')}
        </div>
      </article>
    `;
  }

  function renderDrawer() {
    const chart = state.chart;
    if (!chart || !state.selectedNodeId) {
      els.detailDrawer.classList.add('empty');
      els.detailDrawer.innerHTML = '<div class="drawer-placeholder">点击节点后，这里会显示该节点的局部关系图与完整关系账单。</div>';
      return;
    }

    const node = chart.allNodes.find((n) => n.id === state.selectedNodeId);
    if (!node) return;

    const incomingEdges = chart.edges.filter((e) => e.target === node.id).sort((a, b) => Math.abs(b.weight) - Math.abs(a.weight));
    const nodeModifiers = chart.modifiers.filter((m) => m.target === node.id).sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta));
    const tags = [
      node.spirit,
      node.isShi ? '世' : '',
      node.isYing ? '应' : '',
      node.isUseGod ? '用神' : '',
      node.isOriginalGod ? '原神' : '',
      node.isJiGod ? '忌神' : '',
      node.isChouGod ? '仇神' : '',
      node.moving ? '动爻' : '',
      node.isEmpty ? '旬空' : '',
      ...node.shenSha.map((item) => item.name),
    ].filter(Boolean);

    els.detailDrawer.classList.remove('empty');
    els.detailDrawer.innerHTML = `
      <div class="drawer-header">
        <h3>${node.lineLabel} · ${node.kinship}${node.branch}${node.element}</h3>
        <div class="drawer-subtitle">${node.column === 'primary' ? '本卦节点' : '变卦节点'} · ${tags.join(' / ') || '无额外标签'}</div>
      </div>

      <div class="kv-grid">
        ${renderKV('六神', node.spirit)}
        ${renderKV('纳甲', node.gz)}
        ${renderKV('阴阳', node.displayYinYang)}
        ${renderKV('动静', node.moving ? '动' : '静')}
        ${renderKV('世应', `${node.isShi ? '世' : ''}${node.isYing ? `${node.isShi ? ' / ' : ''}应` : ''}` || '—')}
        ${renderKV('神煞', node.shenSha.map((item) => item.label).join('、') || '—')}
        ${renderKV('伏神', node.hiddenSpirits.map((h) => `${h.kinship}${h.branch}${h.element}（${h.flyRelationLabel}）`).join('、') || '—')}
        ${renderKV('伏显 / 潜藏', node.hiddenSpirits.length ? `${getHiddenAggregate(node).manifest.toFixed(2)} / ${getHiddenAggregate(node).hiddenDepth.toFixed(2)}` : '—')}
        ${renderKV('伏回流', node.hiddenSpirits.length ? `${getHiddenAggregate(node).support.toFixed(2)} / ${getHiddenAggregate(node).pressure.toFixed(2)} / ${signed(getHiddenAggregate(node).strength)}` : '—')}
        ${renderKV('旬空 / 月建', `${node.isEmpty ? '空' : '实'} / ${node.branch === chart.monthBranch ? '临月建' : '—'}`)}
        ${renderKV('旺衰', node.metrics.strength.toFixed(2))}
        ${renderKV('发动', node.metrics.active.toFixed(2))}
        ${renderKV('虚实', node.metrics.reality.toFixed(2))}
        ${renderKV('受助 / 受制', `${node.metrics.support.toFixed(2)} / ${node.metrics.pressure.toFixed(2)}`)}
      </div>

      ${node.column === 'primary' ? `<div class="drawer-action"><button id="setUseGodBtn" type="button" ${node.isUseGod ? 'disabled' : ''}>${node.isUseGod ? '当前已是用神' : '设为用神'}</button></div>` : ''}

      <div class="drawer-graph">
        <div class="graph-caption"><span>局部关系边图</span><span>只显示流向当前节点的关系</span></div>
        <div id="relationGraph" class="relation-graph"></div>
        ${nodeModifiers.length ? `<div class="relation-mods">${nodeModifiers.map(renderModifierPill).join('')}</div>` : ''}
      </div>

      ${node.hiddenSpirits.length ? `<div class="section-title">飞神 / 伏神</div><div class="relation-list">${node.hiddenSpirits.map(renderHiddenSpiritItem).join('')}</div>` : ''}

      <div class="section-title">流向该节点的全部边</div>
      <div class="relation-list">
        ${incomingEdges.length ? incomingEdges.map(renderRelationItem).join('') : '<div class="relation-item neutral"><div class="head"><span>暂无边</span><span>—</span></div></div>'}
      </div>

      <div class="section-title">状态修正项</div>
      <div class="relation-list">
        ${nodeModifiers.length ? nodeModifiers.map(renderModifierItem).join('') : '<div class="relation-item neutral"><div class="head"><span>无</span><span>0.00</span></div></div>'}
      </div>
    `;

    const btn = document.getElementById('setUseGodBtn');
    if (btn && !node.isUseGod) {
      btn.addEventListener('click', () => {
        state.useGodId = node.id;
        decorateUseGod(chart);
        renderUseGodChooser(chart);
        renderSummary(chart);
        renderColumns(chart);
        renderDrawer();
      });
    }

    drawRelationGraph(node, incomingEdges, nodeModifiers);
  }

  function drawRelationGraph(targetNode, incomingEdges, nodeModifiers) {
    const container = document.getElementById('relationGraph');
    if (!container) return;
    container.innerHTML = '';

    const shownEdges = incomingEdges.slice(0, 6);
    const containerWidth = container.clientWidth || 320;
    const targetBox = createRelationNode(targetNode.lineShort, `${targetNode.kinship}${targetNode.branch}${targetNode.element}`, 'target');
    targetBox.style.left = `${containerWidth - 134}px`;
    targetBox.style.top = '90px';
    container.appendChild(targetBox);

    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    container.appendChild(svg);

    const targetAnchor = { x: containerWidth - 138, y: 120 };
    shownEdges.forEach((edge, idx) => {
      const y = 18 + idx * 34;
      const sourceBox = createRelationNode(edge.type, edge.sourceLabel, 'source');
      sourceBox.style.left = '12px';
      sourceBox.style.top = `${y}px`;
      container.appendChild(sourceBox);

      const sx = 122;
      const sy = y + 16;
      const tx = targetAnchor.x;
      const ty = targetAnchor.y;
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('class', `relation-edge-path ${edgeTone(edge.weight, edge.type)}`);
      path.setAttribute('stroke-width', String(Math.max(1.6, Math.abs(edge.weight) * 9)));
      path.setAttribute('d', `M ${sx} ${sy} C ${sx + 72} ${sy}, ${tx - 70} ${ty}, ${tx} ${ty}`);
      svg.appendChild(path);

      const label = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      label.setAttribute('class', 'relation-edge-label');
      const mx = (sx + tx) / 2 + 4;
      label.setAttribute('x', String(mx));
      label.setAttribute('y', String((sy + ty) / 2 - 4));
      const sign = edge.weight >= 0 ? '+' : '';
      label.textContent = `${edge.type} ${sign}${edge.weight.toFixed(2)}`;
      svg.appendChild(label);
    });

    if (!shownEdges.length && nodeModifiers.length) {
      const msg = document.createElement('div');
      msg.className = 'drawer-placeholder';
      msg.style.paddingTop = '88px';
      msg.textContent = '该节点当前没有流入边，只有状态修正项。';
      container.appendChild(msg);
    }
  }

  function createRelationNode(title, body, extraClass) {
    const node = document.createElement('div');
    node.className = `relation-node ${extraClass}`;
    node.innerHTML = `<div class="n1">${title}</div><div class="n2">${body}</div>`;
    return node;
  }

  function renderHiddenSpiritItem(hidden) {
    return `
      <div class="relation-item neutral">
        <div class="head"><span>伏神 ${hidden.kinship}${hidden.branch}${hidden.element}</span><span>${hidden.flyRelationLabel}</span></div>
        <div class="desc">飞神为${hidden.hostLabel}；${hidden.flyHint}</div>
        <div class="desc">潜藏 ${hidden.hiddenDepth.toFixed(2)} · 显化 ${hidden.manifest.toFixed(2)} · 暗旺 ${hidden.hiddenMetrics.strength.toFixed(2)} · 暗动 ${hidden.hiddenMetrics.active.toFixed(2)} · 暗实 ${hidden.hiddenMetrics.reality.toFixed(2)}</div>
        <div class="desc">回流：助 ${hidden.feedbackSupport.toFixed(2)} / 制 ${hidden.feedbackPressure.toFixed(2)} / 旺衰 ${signed(hidden.feedbackStrength)} / 发动 ${signed(hidden.feedbackActive)} / 虚实 ${signed(hidden.feedbackReality)}</div>
        <div class="desc">${hidden.reasons.slice(0, 4).join('；')}</div>
      </div>
    `;
  }

  function renderModifierPill(modifier) {
    const tone = modifier.delta >= 0 ? 'positive' : 'negative';
    const sign = modifier.delta >= 0 ? '+' : '';
    return `<span class="mod-pill ${tone}">${modifier.type} ${sign}${modifier.delta.toFixed(2)}</span>`;
  }

  function renderRelationItem(edge) {
    const tone = edgeTone(edge.weight, edge.type);
    const sign = edge.weight >= 0 ? '+' : '';
    return `
      <div class="relation-item ${tone}">
        <div class="head"><span>${edge.sourceLabel} → ${edge.type}</span><span>${sign}${edge.weight.toFixed(2)}</span></div>
        <div class="desc">${edge.reason}</div>
      </div>
    `;
  }

  function renderModifierItem(modifier) {
    const tone = modifier.delta >= 0 ? 'positive' : 'negative';
    const sign = modifier.delta >= 0 ? '+' : '';
    return `
      <div class="relation-item ${tone}">
        <div class="head"><span>${modifier.type} · ${modifier.dimension}</span><span>${sign}${modifier.delta.toFixed(2)}</span></div>
        <div class="desc">${modifier.reason}</div>
      </div>
    `;
  }

  function renderKV(key, value) {
    return `<div class="kv"><div class="k">${key}</div><div class="v">${value}</div></div>`;
  }

  function createEnvEdges({ nodes, monthBranch, dayGanzhi, xunkong, edges, modifiers, stronger }) {
    const dayBranch = dayGanzhi[1];
    const dayElement = XING5[ZHI5[ZHIS.indexOf(dayBranch)]];
    const monthElement = XING5[ZHI5[ZHIS.indexOf(monthBranch)]];

    nodes.forEach((node) => {
      addEnvRelation('MONTH', '月建', monthBranch, monthElement, node, stronger ? 1.0 : 0.9, edges);
      addEnvRelation('DAY', '日辰', dayBranch, dayElement, node, stronger ? 0.8 : 0.72, edges);

      if (node.moving) {
        modifiers.push(makeModifier(node.id, '动爻', 'active', 0.58, `${node.lineLabel}为动爻，发动值显著提高。`));
        modifiers.push(makeModifier(node.id, '动爻', 'reality', 0.03, '动爻通常比静爻更容易落到具体事件层。'));
      }
      if (node.isEmpty) modifiers.push(makeModifier(node.id, '旬空', 'reality', -0.28, `${node.branch}落入旬空 ${xunkong}，虚实下降。`));
      if (node.monthBreak) {
        modifiers.push(makeModifier(node.id, '月冲', 'strength', -0.08, `月建 ${monthBranch} 与 ${node.branch} 相冲，对旺衰有折损。`));
        modifiers.push(makeModifier(node.id, '月冲', 'active', 0.08, '被月冲也可能带来外部触发。'));
        modifiers.push(makeModifier(node.id, '月冲', 'reality', -0.12, '月冲使状态更不稳定。'));
      }
      if (node.dayBreak) {
        modifiers.push(makeModifier(node.id, '日冲', 'active', 0.12, `日辰 ${dayBranch} 与 ${node.branch} 相冲，容易触发暗动或事件起波。`));
        modifiers.push(makeModifier(node.id, '日冲', 'reality', -0.1, '被日冲时落地性变差。'));
      }
      if (node.isEmpty && node.dayBreak) modifiers.push(makeModifier(node.id, '冲空稍实', 'reality', 0.1, '旬空之爻逢日冲，有一定“冲空变实”的补偿。'));
      if (node.combineWithMonth) modifiers.push(makeModifier(node.id, '月合', 'reality', 0.04, '与月建相合，关系趋于黏合、牵制或趋稳。'));
      if (node.combineWithDay) modifiers.push(makeModifier(node.id, '日合', 'reality', 0.03, '与日辰相合，现实层面略有黏连。'));
    });
  }

  function createHiddenSpiritEffects({ nodes, edges, modifiers }) {
    nodes.forEach((node) => {
      if (!node.hiddenSpirits.length) return;
      node.hiddenSpirits.forEach((hidden, idx) => {
        const sourceId = `FS_${node.id}_${idx}`;
        const net = hidden.feedbackSupport - hidden.feedbackPressure + hidden.feedbackStrength * 0.85;
        const reason = `${hidden.flyHint} 潜藏${hidden.hiddenDepth.toFixed(2)}，显化${hidden.manifest.toFixed(2)}，回流助${hidden.feedbackSupport.toFixed(2)} / 制${hidden.feedbackPressure.toFixed(2)}。`;
        edges.push(makeEdge(sourceId, node.id, `伏神·${hidden.kinship}${hidden.branch}${hidden.element}`, labelNode(node), hidden.flyRelationLabel, net || 0.02, reason, true));
        if (hidden.feedbackSupport) modifiers.push(makeModifier(node.id, '伏神回流', 'support', hidden.feedbackSupport, `${hidden.kinship}${hidden.branch}${hidden.element}以${hidden.manifest.toFixed(2)}的显化度暗中助本爻。`));
        if (hidden.feedbackPressure) modifiers.push(makeModifier(node.id, '伏神回流', 'pressure', hidden.feedbackPressure, `${hidden.kinship}${hidden.branch}${hidden.element}通过飞伏关系对本爻形成暗压。`));
        if (hidden.feedbackStrength) modifiers.push(makeModifier(node.id, '伏神回流', 'strength', hidden.feedbackStrength, `${hidden.kinship}${hidden.branch}${hidden.element}经飞伏链路回流到本爻旺衰。`));
        if (hidden.feedbackActive) modifiers.push(makeModifier(node.id, '伏神回流', 'active', hidden.feedbackActive, `${hidden.kinship}${hidden.branch}${hidden.element}影响本爻的显化与发动节奏。`));
        if (hidden.feedbackReality) modifiers.push(makeModifier(node.id, '伏神回流', 'reality', hidden.feedbackReality, `${hidden.kinship}${hidden.branch}${hidden.element}改变本爻虚实落地程度。`));
        if (hidden.manifest >= 0.56) modifiers.push(makeModifier(node.id, '伏神透出', 'active', 0.04, `${hidden.kinship}${hidden.branch}${hidden.element}显化度较高，有透出迹象。`));
        if (hidden.hiddenDepth >= 0.74) modifiers.push(makeModifier(node.id, '伏神深藏', 'reality', -0.03, `${hidden.kinship}${hidden.branch}${hidden.element}潜藏较深，不易直接落地。`));
      });
    });
  }

  function addEnvRelation(sourceId, sourceLabel, sourceBranch, sourceElement, node, factor, edges) {
    const pair = getElementRelation(sourceElement, node.element);
    if (pair === '生') edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '生', 0.22 * factor, `${sourceLabel}${sourceBranch}${sourceElement}生${labelNode(node)}。`, true));
    else if (pair === '克') edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '克', -0.24 * factor, `${sourceLabel}${sourceBranch}${sourceElement}克${labelNode(node)}。`, true));
    else if (pair === '比和') edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '比和', 0.16 * factor, `${sourceLabel}${sourceBranch}${sourceElement}与${labelNode(node)}同气。`, true));

    if (sourceBranch === node.branch) edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '临', 0.18 * factor, `${labelNode(node)}临${sourceLabel}，当令或得位。`, true));
    if (isClash(sourceBranch, node.branch)) edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '冲', -0.18 * factor, `${sourceLabel}${sourceBranch}冲${node.branch}，引发冲动或破坏。`, true));
    if (isCombine(sourceBranch, node.branch)) edges.push(makeEdge(sourceId, node.id, sourceLabel, labelNode(node), '合', 0.07 * factor, `${sourceLabel}${sourceBranch}与${node.branch}相合，关系趋于黏连。`, true));
  }

  function createPairEdges({ nodes, edges, intensity }) {
    nodes.forEach((source) => {
      nodes.forEach((target) => {
        if (source.id === target.id) return;
        const factor = (source.moving ? 1.18 : 0.92) * intensity;
        const relation = getElementRelation(source.element, target.element);
        if (relation === '生') edges.push(makeEdge(source.id, target.id, labelNode(source), labelNode(target), '生', 0.12 * factor, `${labelNode(source)}生${labelNode(target)}。`, true));
        else if (relation === '克') edges.push(makeEdge(source.id, target.id, labelNode(source), labelNode(target), '克', -0.13 * factor, `${labelNode(source)}克${labelNode(target)}。`, true));
        else if (relation === '比和') edges.push(makeEdge(source.id, target.id, labelNode(source), labelNode(target), '比和', 0.05 * factor, `${labelNode(source)}与${labelNode(target)}五行同气。`, false));
        if (isClash(source.branch, target.branch)) edges.push(makeEdge(source.id, target.id, labelNode(source), labelNode(target), '冲', -0.1 * factor, `${source.branch}与${target.branch}相冲。`, true));
        if (isCombine(source.branch, target.branch)) edges.push(makeEdge(source.id, target.id, labelNode(source), labelNode(target), '合', 0.06 * factor, `${source.branch}与${target.branch}相合。`, true));
      });
    });
  }

  function createTransformEdges({ primaryNodes, changedNodes, rawValues, edges, modifiers }) {
    primaryNodes.forEach((node, idx) => {
      if (!(rawValues[idx] === 6 || rawValues[idx] === 9)) return;
      const changed = changedNodes[idx];
      edges.push(makeEdge(node.id, changed.id, labelNode(node), labelNode(changed), '变', 0.09, `${labelNode(node)}发动后变为${labelNode(changed)}。`, true));
      const relation = getElementRelation(changed.element, node.element);
      if (relation === '生') {
        edges.push(makeEdge(changed.id, node.id, labelNode(changed), labelNode(node), '回头生', 0.18, `${labelNode(changed)}回头生${labelNode(node)}。`, true));
        modifiers.push(makeModifier(node.id, '回头生', 'strength', 0.08, '变爻回头生本爻，后续有补力。'));
      }
      if (relation === '克') {
        edges.push(makeEdge(changed.id, node.id, labelNode(changed), labelNode(node), '回头克', -0.2, `${labelNode(changed)}回头克${labelNode(node)}。`, true));
        modifiers.push(makeModifier(node.id, '回头克', 'pressure', 0.1, '变爻回头克本爻，后续压力加大。'));
      }
      if (isCombine(changed.branch, node.branch)) edges.push(makeEdge(changed.id, node.id, labelNode(changed), labelNode(node), '化合', 0.05, `${changed.branch}与${node.branch}相合。`, false));
      if (isClash(changed.branch, node.branch)) edges.push(makeEdge(changed.id, node.id, labelNode(changed), labelNode(node), '化冲', -0.07, `${changed.branch}与${node.branch}相冲。`, true));
    });
  }

  function calculateMetrics(node, incomingEdges, incomingModifiers) {
    const positive = incomingEdges.filter((e) => e.weight > 0).reduce((sum, e) => sum + e.weight, 0);
    const negative = incomingEdges.filter((e) => e.weight < 0).reduce((sum, e) => sum + Math.abs(e.weight), 0);

    let strength = 0.46 + positive * 0.58 - negative * 0.42;
    let active = 0.06 + (node.moving ? 0.38 : 0);
    let reality = 0.80;
    let support = positive * 1.55;
    let pressure = negative * 1.55;

    incomingModifiers.forEach((m) => {
      if (m.dimension === 'strength') strength += m.delta;
      if (m.dimension === 'active') active += m.delta;
      if (m.dimension === 'reality') reality += m.delta;
      if (m.dimension === 'support') support += m.delta;
      if (m.dimension === 'pressure') pressure += m.delta;
    });

    if (node.combineWithMonth || node.combineWithDay) support += 0.04;
    if (node.monthBreak || node.dayBreak) pressure += 0.06;
    if (node.isEmpty) reality -= 0.02;

    return {
      strength: clamp01(strength),
      active: clamp01(active),
      reality: clamp01(reality),
      support: clamp01(support),
      pressure: clamp01(pressure),
    };
  }

  function deriveCalendarMarkers(date) {
    if (window.Solar && typeof window.Solar.fromYmdHms === 'function') {
      try {
        const solar = window.Solar.fromYmdHms(date.getFullYear(), date.getMonth() + 1, date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
        const lunar = solar.getLunar();
        const yearGanzhi = typeof lunar.getYearInGanZhiExact === 'function' ? lunar.getYearInGanZhiExact() : lunar.getYearInGanZhi();
        const monthGanzhi = typeof lunar.getMonthInGanZhiExact === 'function' ? lunar.getMonthInGanZhiExact() : lunar.getMonthInGanZhi();
        const dayGanzhi = typeof lunar.getDayInGanZhiExact2 === 'function' ? lunar.getDayInGanZhiExact2() : (typeof lunar.getDayInGanZhiExact === 'function' ? lunar.getDayInGanZhiExact() : lunar.getDayInGanZhi());
        const hourGanzhi = typeof lunar.getTimeInGanZhi === 'function' ? lunar.getTimeInGanZhi() : getHourGanzhi(dayGanzhi[0], getHourBranch(date.getHours()));
        const jieQi = typeof lunar.getJieQi === 'function' ? lunar.getJieQi() : '';
        return {
          yearGanzhi,
          monthGanzhi,
          dayGanzhi,
          hourGanzhi,
          monthBranch: monthGanzhi[1],
          yearXunkong: typeof lunar.getYearXunKong === 'function' ? lunar.getYearXunKong() : getXunkong(yearGanzhi),
          monthXunkong: typeof lunar.getMonthXunKong === 'function' ? lunar.getMonthXunKong() : getXunkong(monthGanzhi),
          dayXunkong: typeof lunar.getDayXunKong === 'function' ? lunar.getDayXunKong() : getXunkong(dayGanzhi),
          hourXunkong: typeof lunar.getTimeXunKong === 'function' ? lunar.getTimeXunKong() : getXunkong(hourGanzhi),
          dayJiShen: typeof lunar.getDayJiShen === 'function' ? lunar.getDayJiShen() : [],
          dayXiongSha: typeof lunar.getDayXiongSha === 'function' ? lunar.getDayXiongSha() : [],
          sourceLabel: '严格节气 / lunar-javascript',
          jieQi,
        };
      } catch (err) {
        console.warn('lunar-javascript换算失败，回退近似算法', err);
      }
    }

    const adjustedYear = isBeforeApproxLiChun(date) ? date.getFullYear() - 1 : date.getFullYear();
    const yearGanzhi = SEXAGENARY[mod(adjustedYear - REFERENCE_YEAR, 60)];
    const monthBranch = getMonthBranch(date);
    const monthGanzhi = getMonthGanzhi(yearGanzhi[0], monthBranch);
    const dayGanzhi = getDayGanzhi(date);
    const hourBranch = getHourBranch(date.getHours());
    const hourGanzhi = getHourGanzhi(dayGanzhi[0], hourBranch);
    return {
      yearGanzhi,
      monthGanzhi,
      dayGanzhi,
      hourGanzhi,
      monthBranch,
      dayXunkong: getXunkong(dayGanzhi),
      yearXunkong: getXunkong(yearGanzhi),
      monthXunkong: getXunkong(monthGanzhi),
      hourXunkong: getXunkong(hourGanzhi),
      dayJiShen: [],
      dayXiongSha: [],
      sourceLabel: '近似换算（回退）',
      jieQi: '',
    };
  }

  function isBeforeApproxLiChun(date) {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return month < 2 || (month === 2 && day < 4);
  }

  function getMonthBranch(date) {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    let matched = '子';
    for (const item of MONTH_BRANCH_BOUNDARIES) {
      if (month > item.month || (month === item.month && day >= item.day)) matched = item.branch;
    }
    return matched;
  }

  function getMonthGanzhi(yearStem, monthBranch) {
    const startStem = START_MONTH_STEM[yearStem] || '丙';
    const stemIndex = GANS.indexOf(startStem);
    const branchIndex = MONTH_BRANCH_ORDER.indexOf(monthBranch);
    return `${GANS[mod(stemIndex + branchIndex, 10)]}${monthBranch}`;
  }

  function getDayGanzhi(date) {
    const current = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12, 0, 0, 0);
    const diffDays = Math.round((current.getTime() - REFERENCE_DAY.date.getTime()) / 86400000);
    return SEXAGENARY[mod(REFERENCE_DAY.index + diffDays, 60)];
  }

  function getHourBranch(hour) {
    const item = HOUR_BRANCH_MAP.find((entry) => hour >= entry.start && hour < entry.end);
    return item ? item.branch : '子';
  }

  function getHourGanzhi(dayStem, hourBranch) {
    const startStem = START_HOUR_STEM[dayStem] || '甲';
    const stemIndex = GANS.indexOf(startStem);
    const branchIndex = ZHIS.indexOf(hourBranch);
    return `${GANS[mod(stemIndex + branchIndex, 10)]}${hourBranch}`;
  }

  function generateTimeLines(date) {
    let seed = Math.floor(date.getTime() / 1000) >>> 0;
    const result = [];
    for (let i = 0; i < 6; i += 1) {
      seed = (seed * 1664525 + 1013904223 + i * 97) >>> 0;
      result.push([6, 7, 8, 9][seed % 4]);
    }
    return result;
  }

  function generateCoinLines() {
    const lines = [];
    for (let i = 0; i < 6; i += 1) {
      lines.push(tossThreeCoins());
    }
    return { lines };
  }

  function tossThreeCoins() {
    let heads = 0;
    for (let i = 0; i < 3; i += 1) {
      if (Math.random() >= 0.5) heads += 1;
    }
    if (heads === 0) return 6;
    if (heads === 1) return 8;
    if (heads === 2) return 7;
    return 9;
  }


  function computeHiddenSpiritState({ hidden, host, monthBranch, dayGanzhi, xunkong, interaction }) {
    const dayBranch = dayGanzhi[1];
    const dayElement = XING5[ZHI5[ZHIS.indexOf(dayBranch)]];
    const monthElement = XING5[ZHI5[ZHIS.indexOf(monthBranch)]];
    const hiddenEmpty = xunkong.includes(hidden.branch);
    const hiddenMonthRelation = getElementRelation(monthElement, hidden.element);
    const hiddenDayRelation = getElementRelation(dayElement, hidden.element);
    const hiddenMonthClash = isClash(hidden.branch, monthBranch);
    const hiddenDayClash = isClash(hidden.branch, dayBranch);
    const hiddenMonthCombine = isCombine(hidden.branch, monthBranch);
    const hiddenDayCombine = isCombine(hidden.branch, dayBranch);

    let support = 0;
    let pressure = 0;
    let active = 0.08;
    let reality = 0.72;
    let hiddenDepth = 0.60;
    let manifest = 0.28;
    let strength = 0.38;
    const reasons = [];

    if (interaction.relation === '飞生伏') {
      support += 0.20;
      strength += 0.08;
      hiddenDepth += 0.05;
      manifest -= 0.05;
      reasons.push('飞神生伏神，伏神得气，但多在暗层蓄力。');
    } else if (interaction.relation === '飞克伏') {
      pressure += 0.26;
      strength -= 0.07;
      hiddenDepth += 0.10;
      manifest -= 0.14;
      reality -= 0.05;
      reasons.push('飞神克伏神，伏神受压，难以直接透出。');
    } else if (interaction.relation === '伏生飞') {
      support += 0.14;
      strength += 0.05;
      active += 0.02;
      hiddenDepth -= 0.04;
      manifest += 0.10;
      reasons.push('伏神生飞神，常表现为暗中支持主爻。');
    } else if (interaction.relation === '伏克飞') {
      pressure += 0.18;
      active += 0.04;
      hiddenDepth -= 0.05;
      manifest += 0.14;
      reality -= 0.03;
      reasons.push('伏神克飞神，暗层与显层存在冲突，较容易露头。');
    } else {
      support += 0.10;
      strength += 0.03;
      manifest += 0.04;
      reasons.push('飞伏比和，同气共振。');
    }

    if (hiddenEmpty) {
      reality -= 0.18;
      manifest -= 0.16;
      hiddenDepth += 0.10;
      reasons.push(`伏神 ${hidden.branch} 落旬空 ${xunkong}，潜力未实。`);
    }

    if (hidden.branch === monthBranch) {
      strength += 0.12;
      manifest += 0.10;
      hiddenDepth -= 0.08;
      reasons.push('伏神临月建，当令得气。');
    }
    if (hidden.branch === dayBranch) {
      active += 0.10;
      manifest += 0.10;
      hiddenDepth -= 0.06;
      reasons.push('伏神临日辰，容易被触发。');
    }

    if (hiddenMonthRelation === '生') {
      strength += 0.14;
      support += 0.10;
      manifest += 0.08;
      reasons.push('月建生伏神。');
    } else if (hiddenMonthRelation === '比和') {
      strength += 0.08;
      manifest += 0.04;
      reasons.push('月建与伏神同气。');
    } else if (hiddenMonthRelation === '克') {
      pressure += 0.12;
      strength -= 0.08;
      manifest -= 0.06;
      reasons.push('月建克伏神。');
    }

    if (hiddenDayRelation === '生') {
      strength += 0.10;
      support += 0.06;
      active += 0.06;
      manifest += 0.07;
      reasons.push('日辰生伏神。');
    } else if (hiddenDayRelation === '比和') {
      strength += 0.05;
      manifest += 0.03;
      reasons.push('日辰与伏神同气。');
    } else if (hiddenDayRelation === '克') {
      pressure += 0.10;
      reality -= 0.05;
      manifest -= 0.04;
      reasons.push('日辰克伏神。');
    }

    if (hiddenMonthClash) {
      active += 0.08;
      manifest += 0.08;
      strength -= 0.05;
      pressure += 0.06;
      reasons.push('月冲伏神，易被引动但不稳。');
    }
    if (hiddenDayClash) {
      active += 0.12;
      manifest += 0.14;
      reality -= 0.03;
      pressure += 0.05;
      reasons.push('日冲伏神，透出概率明显上升。');
    }
    if (hiddenMonthCombine) {
      manifest += 0.03;
      reality += 0.03;
      reasons.push('伏神与月建相合。');
    }
    if (hiddenDayCombine) {
      manifest += 0.04;
      reality += 0.02;
      reasons.push('伏神与日辰相合。');
    }

    hiddenDepth = clamp01(hiddenDepth);
    manifest = clamp01(manifest - (hiddenDepth - 0.5) * 0.35 + (support - pressure) * 0.12 + active * 0.08);
    strength = clamp01(strength + support * 0.45 - pressure * 0.42);
    active = clamp01(active);
    reality = clamp01(reality + manifest * 0.05 - hiddenDepth * 0.04);

    const feedbackScale = manifest * 0.45;
    const feedbackSupport = clamp01(support * feedbackScale);
    const feedbackPressure = clamp01(pressure * feedbackScale);
    const feedbackStrength = clampRange((support - pressure) * manifest * 0.18, -0.18, 0.18);
    const feedbackActive = clampRange((active - 0.16) * manifest * 0.16, -0.08, 0.12);
    const feedbackReality = clampRange((manifest - hiddenDepth * 0.55) * 0.16, -0.10, 0.10);

    return {
      hiddenDepth,
      manifest,
      feedbackSupport,
      feedbackPressure,
      feedbackStrength,
      feedbackActive,
      feedbackReality,
      hiddenMetrics: { strength, active, reality, support: clamp01(support), pressure: clamp01(pressure) },
      reasons,
    };
  }

  function renderHiddenSummary(hidden) {
    const flow = hidden.feedbackSupport >= hidden.feedbackPressure ? `助${hidden.feedbackSupport.toFixed(2)}` : `制${hidden.feedbackPressure.toFixed(2)}`;
    return `${hidden.kinship}${hidden.branch}${hidden.element}（${hidden.flyRelationLabel}，显${hidden.manifest.toFixed(2)}，${flow}）`;
  }

  function getHiddenAggregate(node) {
    const items = node.hiddenSpirits || [];
    if (!items.length) return { manifest: 0, hiddenDepth: 0, support: 0, pressure: 0, strength: 0, active: 0, reality: 0 };
    const manifest = Math.max(...items.map((item) => item.manifest));
    const hiddenDepth = Math.max(...items.map((item) => item.hiddenDepth));
    return {
      manifest,
      hiddenDepth,
      support: items.reduce((sum, item) => sum + item.feedbackSupport, 0),
      pressure: items.reduce((sum, item) => sum + item.feedbackPressure, 0),
      strength: items.reduce((sum, item) => sum + item.feedbackStrength, 0),
      active: items.reduce((sum, item) => sum + item.feedbackActive, 0),
      reality: items.reduce((sum, item) => sum + item.feedbackReality, 0),
    };
  }

  function signed(value) {
    return `${value >= 0 ? '+' : ''}${value.toFixed(2)}`;
  }

  function describeHiddenInteraction(hostElement, hiddenElement) {
    if (ELEMENT_GENERATES[hostElement] === hiddenElement) return { relation: '飞生伏', label: '飞生伏', hint: '飞神生伏神，伏神较易得气。' };
    if (ELEMENT_CONTROLS[hostElement] === hiddenElement) return { relation: '飞克伏', label: '飞克伏', hint: '飞神克伏神，伏神受压，不易透出。' };
    if (ELEMENT_GENERATES[hiddenElement] === hostElement) return { relation: '伏生飞', label: '伏生飞', hint: '伏神生飞神，多为暗中支持本爻。' };
    if (ELEMENT_CONTROLS[hiddenElement] === hostElement) return { relation: '伏克飞', label: '伏克飞', hint: '伏神克飞神，暗层与显层有冲突。' };
    return { relation: '飞伏比和', label: '飞伏比和', hint: '飞神与伏神同气，比和共振。' };
  }

  function clampRange(value, min, max) { return Math.max(min, Math.min(max, value)); }

  function uniqueByKey(list, getKey) {
    const seen = new Set();
    return list.filter((item) => {
      const key = getKey(item);
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  function getElementRelation(source, target) {
    if (source === target) return '比和';
    if (ELEMENT_GENERATES[source] === target) return '生';
    if (ELEMENT_CONTROLS[source] === target) return '克';
    return '无';
  }

  function getXunkong(gz) {
    const gm = GANS.indexOf(gz[0]);
    let zm = ZHIS.indexOf(gz[1]);
    if (gm === -1 || zm === -1) return '';
    if (gm === zm || zm < gm) zm += 12;
    const idx = Math.floor((zm - gm) / 2) - 1;
    return KONG[idx] || '';
  }

  function getGod6(gz) {
    const gm = GANS.indexOf(gz[0]);
    let num = Math.ceil((gm + 1) / 2) - 7;
    if (gm === 4) num = -4;
    if (gm === 5) num = -3;
    if (gm > 5) num += 1;
    return SHEN6.slice(num).concat(SHEN6.slice(0, num));
  }

  function setShiYao(symbol) {
    const wai = symbol.slice(3);
    const nei = symbol.slice(0, 3);
    const build = (shi, index) => [shi, shi > 3 ? shi - 3 : shi + 3, index ?? shi];
    if (wai[2] === nei[2]) { if (wai[1] !== nei[1] && wai[0] !== nei[0]) return build(2); }
    else if (wai[1] === nei[1] && wai[0] === nei[0]) return build(5);
    if (wai[1] === nei[1]) { if (wai[0] !== nei[0] && wai[2] !== nei[2]) return build(4, 6); }
    else if (wai[0] === nei[0] && wai[2] === nei[2]) return build(3, 6);
    if (wai[0] === nei[0]) { if (wai[1] !== nei[1] && wai[2] !== nei[2]) return build(4); }
    else if (wai[1] === nei[1] && wai[2] === nei[2]) return build(1);
    if (wai === nei) return build(6);
    return build(3);
  }

  function palace(symbol, index) {
    const wai = symbol.slice(3);
    const nei = symbol.slice(0, 3);
    let hun = '';
    if (wai[1] === nei[1]) { if (wai[0] !== nei[0] && wai[2] !== nei[2]) hun = '游魂'; }
    else if (wai[0] === nei[0] && wai[2] === nei[2]) hun = '归魂';
    if (hun === '归魂') return YAOS.indexOf(nei);
    if ([1, 2, 3, 6].includes(index)) return YAOS.indexOf(wai);
    if ([4, 5].includes(index) || hun === '游魂') return YAOS.indexOf(nei.split('').map((c) => (c === '1' ? '0' : '1')).join(''));
    return YAOS.indexOf(wai);
  }

  function getNajia(symbol) {
    const waiIndex = YAOS.indexOf(symbol.slice(3));
    const neiIndex = YAOS.indexOf(symbol.slice(0, 3));
    return expandNajiaSet(NAJIA[neiIndex][0]).concat(expandNajiaSet(NAJIA[waiIndex][1]));
  }

  function expandNajiaSet(raw) {
    const gan = raw[0];
    return [raw[1], raw[2], raw[3]].map((zhi) => `${gan}${zhi}`);
  }

  function getQin6(selfElement, targetElement) {
    let diff = XING5.indexOf(selfElement) - XING5.indexOf(targetElement);
    if (diff < 0) diff += 5;
    return QING6[diff];
  }

  function getHexagramType(symbol) {
    const soulType = soul(symbol);
    if (soulType) return soulType;
    if (isSixChong(symbol)) return '六冲';
    const name = GUA64[symbol] || '';
    if (LIUHE_NAMES.some((part) => name.includes(part))) return '六合';
    return '';
  }

  function soul(symbol) {
    const wai = symbol.slice(3);
    const nei = symbol.slice(0, 3);
    if (wai[1] === nei[1]) { if (wai[0] !== nei[0] && wai[2] !== nei[2]) return '游魂'; }
    else if (wai[0] === nei[0] && wai[2] === nei[2]) return '归魂';
    return '';
  }

  function isSixChong(symbol) {
    const wai = symbol.slice(3);
    const nei = symbol.slice(0, 3);
    if (wai === nei) return true;
    return [nei, wai].every((item) => item === '100' || item === '111');
  }

  function makeEdge(source, target, sourceLabel, targetLabel, type, weight, reason, visibleByDefault) {
    return { id: `${source}_${target}_${type}_${Math.random().toString(36).slice(2, 8)}`, source, target, sourceLabel, targetLabel, type, weight, reason, visibleByDefault };
  }
  function makeModifier(target, type, dimension, delta, reason) {
    return { id: `${target}_${type}_${dimension}_${Math.random().toString(36).slice(2, 8)}`, target, type, dimension, delta, reason };
  }
  function labelNode(node) { return `${node.lineShort}·${node.kinship}${node.branch}${node.element}`; }
  function shortNodeLabel(node) { return `${node.lineShort}·${node.kinship}${node.branch}`; }
  function edgeTone(weight, type) { return ['变', '伏'].includes(type) ? 'neutral' : (weight >= 0 ? 'positive' : 'negative'); }
  function clamp01(value) { return Math.max(0, Math.min(1, Number(value.toFixed(4)))); }
  function isClash(a, b) { return BRANCH_CLASH[a] === b; }
  function isCombine(a, b) { return BRANCH_COMBINE[a] === b; }
  function mod(n, m) { return ((n % m) + m) % m; }
  function toDateTimeLocalString(date) {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const hh = String(date.getHours()).padStart(2, '0');
    const mi = String(date.getMinutes()).padStart(2, '0');
    const ss = String(date.getSeconds()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}T${hh}:${mi}:${ss}`;
  }
  function formatDateTimeDisplay(date) {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const hh = String(date.getHours()).padStart(2, '0');
    const mi = String(date.getMinutes()).padStart(2, '0');
    const ss = String(date.getSeconds()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}:${ss}`;
  }
})();
