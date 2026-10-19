// Adapted from miounet11/life-kline, commit 7abf184df370452ee8279d72c8b45bc09e19913b.
// Copyright 2024-2025 Life-Kline Team. Apache-2.0; see bundled LICENSE and NOTICE.
// Changes: remove module import/export and TypeScript annotations to run with bundled lunar.js in JavaScriptCore.

// Types for Bazi and Fortune calculations
                    
                                          
                                          
                                          
                                          
                            
 

                        
               
                                        
                        
                        
                              
                        
                          
                         
                   
                             
                     
 

                          
               
                
                        
                
                        
                        
                              
                        
              
                 
                  
                                                
      
                           
                         
                          
 

                         
               
                           
                        
                           
                               
                               
             
                         
                         
                               
                         
    
                                            
                             
                               
                          
 

                         
                                   
                      
                                  
                 
 

                     
                
                
                            
                                                      
 

                        
                      
                    
                                      
                      
                            
 

                       
                
                 
                                       
                          
 

                        
                
                        
                               
                 
 

                               
                      
                    
                        
 

                                                                

class FortuneCalculator {
                   elements = ['木', '火', '土', '金', '水'];
                   heavenlyStems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
                   earthlyBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
                   zodiacAnimals = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];

  constructor() {}

  /**
   * Calculate daily fortune based on Bazi and current date
   */
  calculateDaily(bazi          , date      )               {
    const solar = Solar.fromDate(date);
    const lunar = solar.getLunar();

    // Get current day's pillars
    const dayGanZhi = `${lunar.getDayGan()}${lunar.getDayZhi()}`;
    const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;
    const yearGanZhi = `${lunar.getYearGan()}${lunar.getYearZhi()}`;

    // Calculate elemental strengths
    const dayElement = this.getElementFromStem(lunar.getDayGan());
    const baziElements = this.extractBaziElements(bazi);
    const elementalBalance = this.calculateElementalBalance(baziElements, dayElement);

    // Calculate scores
    const baseScore = this.calculateBaseScore(bazi, dayGanZhi);
    const modifiers = this.calculateDailyModifiers(bazi, dayGanZhi, monthGanZhi, yearGanZhi);

    const overallScore = Math.max(1, Math.min(100, baseScore + modifiers.overall));

    return {
      date: this.formatDate(date),
      overall_score: overallScore,
      career: this.calculateAspectScore(baseScore + modifiers.career, 'career', bazi, dayGanZhi),
      wealth: this.calculateAspectScore(baseScore + modifiers.wealth, 'wealth', bazi, dayGanZhi),
      relationship: this.calculateAspectScore(baseScore + modifiers.relationship, 'relationship', bazi, dayGanZhi),
      health: this.calculateAspectScore(baseScore + modifiers.health, 'health', bazi, dayGanZhi),
      lucky_numbers: this.getLuckyNumbers(bazi, date),
      lucky_colors: this.getLuckyColors(bazi, dayElement),
      advice: this.generateDailyAdvice(bazi, dayGanZhi, overallScore),
      auspicious_hours: this.getAuspiciousHours(bazi, lunar.getDayGan()),
      warnings: this.generateDailyWarnings(bazi, dayGanZhi, elementalBalance)
    };
  }

  /**
   * Calculate monthly fortune
   */
  calculateMonthly(bazi          , year        , month        )                 {
    const solar = Solar.fromYmd(year, month, 1);
    const lunar = solar.getLunar();
    const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;
    const yearGanZhi = `${lunar.getYearGan()}${lunar.getYearZhi()}`;

    // Calculate monthly theme based on interactions
    const theme = this.determineMonthlyTheme(bazi, monthGanZhi, yearGanZhi);

    // Base calculations
    const baseScore = this.calculateBaseScore(bazi, monthGanZhi);
    const modifiers = this.calculateMonthlyModifiers(bazi, monthGanZhi, yearGanZhi);
    const overallScore = Math.max(1, Math.min(100, baseScore + modifiers.overall));

    // Generate key dates
    const keyDates = this.generateKeyDates(bazi, year, month, yearGanZhi, monthGanZhi);

    return {
      year,
      month,
      overall_score: overallScore,
      theme,
      career: this.calculateAspectScore(baseScore + modifiers.career, 'career', bazi, monthGanZhi),
      wealth: this.calculateAspectScore(baseScore + modifiers.wealth, 'wealth', bazi, monthGanZhi),
      relationship: this.calculateAspectScore(baseScore + modifiers.relationship, 'relationship', bazi, monthGanZhi),
      health: this.calculateAspectScore(baseScore + modifiers.health, 'health', bazi, monthGanZhi),
      key_dates: keyDates,
      monthly_advice: this.generateMonthlyAdvice(bazi, monthGanZhi, theme),
      lucky_colors: this.getLuckyColors(bazi, this.getElementFromStem(lunar.getMonthGan())),
      lucky_numbers: this.getLuckyNumbers(bazi, new Date(year, month - 1, 1))
    };
  }

  /**
   * Calculate yearly fortune
   */
  calculateYearly(bazi          , year        )                {
    const solar = Solar.fromYmd(year, 1, 1);
    const lunar = solar.getLunar();
    const yearGanZhi = `${lunar.getYearGan()}${lunar.getYearZhi()}`;

    // Determine overall trend
    const overallTrend = this.calculateYearlyTrend(bazi, yearGanZhi);

    // Base score for the year
    const baseScore = this.calculateBaseScore(bazi, yearGanZhi);
    const yearlyModifiers = this.calculateYearlyModifiers(bazi, yearGanZhi);
    const overallScore = Math.max(1, Math.min(100, baseScore + yearlyModifiers.overall));

    // Generate detailed predictions
    const keyMoments = this.generateKeyMoments(bazi, year, yearGanZhi);
    const crisisPeriods = this.identifyCrisisPeriods(bazi, year, yearGanZhi);
    const opportunities = this.identifyOpportunities(bazi, year, yearGanZhi);

    return {
      year,
      overall_trend: overallTrend,
      overall_score: overallScore,
      key_moments: keyMoments,
      crisis_times: crisisPeriods,
      opportunities: opportunities,
      analysis: {
        career: this.calculateYearlyAspect(bazi, year, 'career', yearGanZhi),
        wealth: this.calculateYearlyAspect(bazi, year, 'wealth', yearGanZhi),
        relationship: this.calculateYearlyAspect(bazi, year, 'relationship', yearGanZhi),
        health: this.calculateYearlyAspect(bazi, year, 'health', yearGanZhi)
      },
      zodiac_compatibility: this.calculateZodiacCompatibility(bazi, year),
      favorable_months: this.identifyFavorableMonths(bazi, year, yearGanZhi),
      challenging_months: this.identifyChallengingMonths(bazi, year, yearGanZhi),
      yearly_advice: this.generateYearlyAdvice(bazi, yearGanZhi, overallTrend)
    };
  }

  // Helper functions

          getElementFromStem(stem        )         {
    const stemElements                            = {
      '甲': '木', '乙': '木',
      '丙': '火', '丁': '火',
      '戊': '土', '己': '土',
      '庚': '金', '辛': '金',
      '壬': '水', '癸': '水'
    };
    return stemElements[stem] || '土';
  }

          extractBaziElements(bazi          )                                {
    const elements                                = {
      '木': 0, '火': 0, '土': 0, '金': 0, '水': 0
    };

    const pillars = [bazi.yearPillar, bazi.monthPillar, bazi.dayPillar, bazi.hourPillar];

    pillars.forEach(pillar => {
      const stem = pillar[0];
      const branch = pillar[1];

      elements[this.getElementFromStem(stem)]++;

      // Add branch elements
      const branchElement = this.getBranchElement(branch);
      elements[branchElement] += 0.5;
    });

    return elements;
  }

          getBranchElement(branch        )         {
    const branchElements                            = {
      '子': '水', '丑': '土', '寅': '木', '卯': '木',
      '辰': '土', '巳': '火', '午': '火', '未': '土',
      '申': '金', '酉': '金', '戌': '土', '亥': '水'
    };
    return branchElements[branch] || '土';
  }

          calculateElementalBalance(baziElements                               , dayElement        )         {
    const total = Object.values(baziElements).reduce((sum, count) => sum + count, 0);
    const dayElementStrength = baziElements[dayElement] || 0;

    // Calculate balance score
    const balance = 1 - Math.abs(dayElementStrength - total / 5) / (total / 5);
    return Math.round(balance * 100);
  }

          calculateBaseScore(bazi          , currentGanZhi        )         {
    const dayMaster = bazi.dayPillar[0];
    const currentStem = currentGanZhi[0];
    const currentBranch = currentGanZhi[1];

    let score = 50; // Base score

    // Stem relationship
    const stemRelationship = this.getStemRelationship(dayMaster, currentStem);
    score += this.getRelationshipScore(stemRelationship);

    // Branch relationship
    const dayBranch = bazi.dayPillar[1];
    const branchRelationship = this.getBranchRelationship(dayBranch, currentBranch);
    score += this.getRelationshipScore(branchRelationship) * 0.8;

    return Math.round(score);
  }

          getStemRelationship(stem1        , stem2        )         {
    const stemIndex1 = this.heavenlyStems.indexOf(stem1);
    const stemIndex2 = this.heavenlyStems.indexOf(stem2);

    if (stemIndex1 === stemIndex2) return 'identical';
    if ((stemIndex1 - stemIndex2 + 10) % 10 === 5) return 'opposite';
    if ((stemIndex1 - stemIndex2 + 10) % 2 === 0) return 'same_yin_yang';
    return 'different_yin_yang';
  }

          getBranchRelationship(branch1        , branch2        )         {
    const branchIndex1 = this.earthlyBranches.indexOf(branch1);
    const branchIndex2 = this.earthlyBranches.indexOf(branch2);

    if (branchIndex1 === branchIndex2) return 'identical';

    // Check for combinations
    const combinations = [
      ['子', '丑'], ['寅', '亥'], ['卯', '戌'],
      ['辰', '酉'], ['巳', '申'], ['午', '未']
    ];

    for (const combo of combinations) {
      if (combo.includes(branch1) && combo.includes(branch2)) {
        return 'combination';
      }
    }

    // Check for clashes
    const clashes = [
      ['子', '午'], ['丑', '未'], ['寅', '申'],
      ['卯', '酉'], ['辰', '戌'], ['巳', '亥']
    ];

    for (const clash of clashes) {
      if (clash.includes(branch1) && clash.includes(branch2)) {
        return 'clash';
      }
    }

    return 'neutral';
  }

          getRelationshipScore(relationship        )         {
    const scores                            = {
      'identical': 5,
      'combination': 10,
      'same_yin_yang': 3,
      'different_yin_yang': 2,
      'opposite': -10,
      'clash': -15,
      'neutral': 0
    };
    return scores[relationship] || 0;
  }

          calculateDailyModifiers(bazi          , dayGanZhi        , monthGanZhi        , yearGanZhi        ) {
    const dayMaster = bazi.dayPillar[0];
    const modifiers = {
      overall: 0,
      career: 0,
      wealth: 0,
      relationship: 0,
      health: 0
    };

    // Career modifier (related to output star)
    if (this.isOutputElement(dayMaster, dayGanZhi[0])) {
      modifiers.career += 15;
    }

    // Wealth modifier (related to wealth star)
    if (this.isWealthElement(dayMaster, dayGanZhi[0])) {
      modifiers.wealth += 20;
    }

    // Relationship modifier (related to power star)
    if (this.isPowerElement(dayMaster, dayGanZhi[0])) {
      modifiers.relationship += 10;
    }

    // Health modifier (related to resource star)
    if (this.isResourceElement(dayMaster, dayGanZhi[0])) {
      modifiers.health += 10;
    }

    // Seasonal adjustments
    const monthElement = this.getElementFromStem(monthGanZhi[0]);
    const dayElement = this.getElementFromStem(dayGanZhi[0]);
    modifiers.overall += this.getSeasonalAdjustment(monthElement, dayElement);

    return modifiers;
  }

          calculateMonthlyModifiers(bazi          , monthGanZhi        , yearGanZhi        ) {
    // Similar to daily but with monthly focus
    return this.calculateDailyModifiers(bazi, monthGanZhi, monthGanZhi, yearGanZhi);
  }

          calculateYearlyModifiers(bazi          , yearGanZhi        ) {
    const modifiers = {
      overall: 0,
      career: 0,
      wealth: 0,
      relationship: 0,
      health: 0
    };

    // Major annual influences
    const yearStem = yearGanZhi[0];
    const dayMaster = bazi.dayPillar[0];

    // Check for major fortunes
    if (this.isMajorFortuneYear(dayMaster, yearStem)) {
      modifiers.overall += 25;
    }

    // Check for challenging years
    if (this.isChallengingYear(dayMaster, yearStem)) {
      modifiers.overall -= 20;
    }

    return modifiers;
  }

          isOutputElement(dayMaster        , currentStem        )          {
    const dayMasterElement = this.getElementFromStem(dayMaster);
    const currentElement = this.getElementFromStem(currentStem);

    // Wood produces Fire, Fire produces Earth, etc.
    const productionCycle                            = {
      '木': '火',
      '火': '土',
      '土': '金',
      '金': '水',
      '水': '木'
    };

    return productionCycle[dayMasterElement] === currentElement;
  }

          isWealthElement(dayMaster        , currentStem        )          {
    const dayMasterElement = this.getElementFromStem(dayMaster);
    const currentElement = this.getElementFromStem(currentStem);

    // What dayMaster controls
    const controlCycle                            = {
      '木': '土',
      '火': '金',
      '土': '水',
      '金': '木',
      '水': '火'
    };

    return controlCycle[dayMasterElement] === currentElement;
  }

          isPowerElement(dayMaster        , currentStem        )          {
    const dayMasterElement = this.getElementFromStem(dayMaster);
    const currentElement = this.getElementFromStem(currentStem);

    // What controls dayMaster
    const beControlled                            = {
      '木': '金',
      '火': '水',
      '土': '木',
      '金': '火',
      '水': '土'
    };

    return beControlled[dayMasterElement] === currentElement;
  }

          isResourceElement(dayMaster        , currentStem        )          {
    const dayMasterElement = this.getElementFromStem(dayMaster);
    const currentElement = this.getElementFromStem(currentStem);

    // What produces dayMaster
    const producers                            = {
      '木': '水',
      '火': '木',
      '土': '火',
      '金': '土',
      '水': '金'
    };

    return producers[dayMasterElement] === currentElement;
  }

          getSeasonalAdjustment(monthElement        , dayElement        )         {
    // Favorable combinations
    if (monthElement === dayElement) return 5;

    // Seasonal harmony
    const favorableCombinations                              = {
      '春': ['木', '火'],
      '夏': ['火', '土'],
      '秋': ['金', '水'],
      '冬': ['水', '木']
    };

    const season = this.getSeason(monthElement);
    if (favorableCombinations[season]?.includes(dayElement)) {
      return 3;
    }

    return 0;
  }

          getSeason(element        )         {
    const seasons                            = {
      '木': '春',
      '火': '夏',
      '土': '夏',
      '金': '秋',
      '水': '冬'
    };
    return seasons[element] || '春';
  }

          isMajorFortuneYear(dayMaster        , yearStem        )          {
    // Check for auspicious combinations
    const dayMasterIndex = this.heavenlyStems.indexOf(dayMaster);
    const yearStemIndex = this.heavenlyStems.indexOf(yearStem);

    // Same element or favorable combination
    if (dayMasterIndex % 2 === yearStemIndex % 2) return true;

    // Check for specific fortune patterns
    return this.isWealthElement(dayMaster, yearStem) || this.isOutputElement(dayMaster, yearStem);
  }

          isChallengingYear(dayMaster        , yearStem        )          {
    // Check for clashes and unfavorable combinations
    const dayMasterElement = this.getElementFromStem(dayMaster);
    const yearElement = this.getElementFromStem(yearStem);

    // Opposite elements
    const opposites                            = {
      '木': '金',
      '火': '水',
      '土': '木',
      '金': '火',
      '水': '土'
    };

    return opposites[dayMasterElement] === yearElement;
  }

          calculateAspectScore(score        , aspect        , bazi          , ganZhi        )                {
    const adjustedScore = Math.max(1, Math.min(100, score));

    let trend                           = 'stable';
    if (adjustedScore > 70) trend = 'up';
    else if (adjustedScore < 40) trend = 'down';

    const descriptions = this.getAspectDescriptions(aspect, adjustedScore);

    return {
      score: adjustedScore,
      description: descriptions.description,
      trend,
      advice: descriptions.advice
    };
  }

          getAspectDescriptions(aspect        , score        )                                          {
    const templates = {
      career: {
        high: {
          description: "事业运势极佳，贵人相助，晋升机会多",
          advice: "把握机会，积极表现，主动承担责任"
        },
        medium: {
          description: "事业运势平稳，稳步发展",
          advice: "保持专业，提升技能，耐心等待时机"
        },
        low: {
          description: "事业面临挑战，需要谨慎应对",
          advice: "保持低调，避免冲突，提升自身能力"
        }
      },
      wealth: {
        high: {
          description: "财运亨通，正财偏财俱佳",
          advice: "可适当投资，但也要理性规划"
        },
        medium: {
          description: "财运平稳，收支平衡",
          advice: "稳健理财，避免冲动消费"
        },
        low: {
          description: "财运较弱，易有破财风险",
          advice: "保守理财，避免高风险投资"
        }
      },
      relationship: {
        high: {
          description: "人际关系和谐，感情运势良好",
          advice: "多参与社交，维系重要关系"
        },
        medium: {
          description: "感情平稳，需要用心经营",
          advice: "加强沟通，增进理解"
        },
        low: {
          description: "感情易有波折，需要包容理解",
          advice: "冷静处理矛盾，避免冲动决定"
        }
      },
      health: {
        high: {
          description: "身体健康，精力充沛",
          advice: "保持良好作息，适度运动"
        },
        medium: {
          description: "健康基本平稳，需要注意细节",
          advice: "规律饮食，预防小病"
        },
        low: {
          description: "健康需要注意，易有小病痛",
          advice: "注意休息，及时就医"
        }
      }
    };

    const level = score > 70 ? 'high' : score < 40 ? 'low' : 'medium';
    return templates[aspect][level];
  }

          determineMonthlyTheme(bazi          , monthGanZhi        , yearGanZhi        )         {
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    if (this.isWealthElement(dayMaster, monthStem)) {
      return "财运月 - 把握投资机遇";
    } else if (this.isOutputElement(dayMaster, monthStem)) {
      return "事业月 - 展现才华的时机";
    } else if (this.isPowerElement(dayMaster, monthStem)) {
      return "权威月 - 提升影响力";
    } else if (this.isResourceElement(dayMaster, monthStem)) {
      return "学习月 - 充实自我";
    } else {
      return "平稳月 - 稳中求进";
    }
  }

          generateKeyDates(bazi          , year        , month        , yearGanZhi        , monthGanZhi        ) {
    const keyDates = [];
    const daysInMonth = new Date(year, month, 0).getDate();

    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month - 1, day);
      const solar = Solar.fromDate(date);
      const lunar = solar.getLunar();
      const dayGanZhi = `${lunar.getDayGan()}${lunar.getDayZhi()}`;

      // Check for significant days
      const significance = this.getDaySignificance(bazi, dayGanZhi, monthGanZhi, yearGanZhi);

      if (significance.impact !== 'neutral') {
        keyDates.push({
          date: day,
          event: significance.event,
          impact: significance.impact                                       
        });
      }
    }

    return keyDates;
  }

          getDaySignificance(bazi          , dayGanZhi        , monthGanZhi        , yearGanZhi        ) {
    const dayMaster = bazi.dayPillar[0];
    const dayStem = dayGanZhi[0];

    // Special day patterns
    if (dayStem === dayMaster) {
      return {
        event: "日主当值 - 个人运势最强",
        impact: 'positive'
      };
    }

    // Check for clashes
    if (this.hasDayClash(bazi, dayGanZhi)) {
      return {
        event: "冲煞日 - 诸事不宜",
        impact: 'negative'
      };
    }

    // Check for combinations
    if (this.hasDayCombination(bazi, dayGanZhi)) {
      return {
        event: "合吉日 - 适合重要决定",
        impact: 'positive'
      };
    }

    return { event: "", impact: 'neutral' };
  }

          hasDayClash(bazi          , dayGanZhi        )          {
    const dayBranch = bazi.dayPillar[1];
    const currentBranch = dayGanZhi[1];

    const clashes = [
      ['子', '午'], ['丑', '未'], ['寅', '申'],
      ['卯', '酉'], ['辰', '戌'], ['巳', '亥']
    ];

    return clashes.some(clash =>
      clash.includes(dayBranch) && clash.includes(currentBranch)
    );
  }

          hasDayCombination(bazi          , dayGanZhi        )          {
    const dayBranch = bazi.dayPillar[1];
    const currentBranch = dayGanZhi[1];

    const combinations = [
      ['子', '丑'], ['寅', '亥'], ['卯', '戌'],
      ['辰', '酉'], ['巳', '申'], ['午', '未']
    ];

    return combinations.some(combo =>
      combo.includes(dayBranch) && combo.includes(currentBranch)
    );
  }

          generateDailyAdvice(bazi          , dayGanZhi        , score        )           {
    const advice = [];

    if (score > 80) {
      advice.push("今日运势极佳，适合重要决策和行动");
      advice.push("把握机会，积极进取");
    } else if (score > 60) {
      advice.push("今日运势良好，可以按计划行事");
      advice.push("保持积极心态");
    } else if (score > 40) {
      advice.push("今日运势平稳，宜稳中求进");
      advice.push("避免冒险，谨慎行事");
    } else {
      advice.push("今日运势较弱，宜静不宜动");
      advice.push("重要事务推迟，注意安全");
    }

    // Specific elemental advice
    const dayElement = this.getElementFromStem(dayGanZhi[0]);
    advice.push(this.getElementalAdvice(dayElement));

    return advice;
  }

          getElementalAdvice(element        )         {
    const adviceMap                            = {
      '木': "宜戴绿色饰品，利东方出行",
      '火': "宜穿红色衣物，利南方发展",
      '土': "宜着黄色服饰，利中央稳定",
      '金': "宜用白色物品，利西方机遇",
      '水': "宜佩黑色饰品，利北方行事"
    };
    return adviceMap[element] || "保持平常心";
  }

          generateDailyWarnings(bazi          , dayGanZhi        , elementalBalance        )           {
    const warnings = [];

    if (elementalBalance < 30) {
      warnings.push("五行失衡严重，注意情绪管理");
    }

    if (this.hasDayClash(bazi, dayGanZhi)) {
      warnings.push("日柱相冲，避免重要决策和签约");
      warnings.push("注意人际关系，避免争吵");
    }

    if (this.getStemRelationship(bazi.dayPillar[0], dayGanZhi[0]) === 'opposite') {
      warnings.push("天干相冲，凡事三思而后行");
    }

    return warnings;
  }

          getAuspiciousHours(bazi          , dayStem        )           {
    const auspiciousHours = [];
    const dayElement = this.getElementFromStem(dayStem);

    // Simple logic for auspicious hours based on element
    const hourElements                                                = {
      '木': { 7: '辰', 11: '午', 15: '申' },
      '火': { 9: '巳', 13: '未', 17: '酉' },
      '土': { 9: '巳', 15: '申', 21: '亥' },
      '金': { 5: '卯', 13: '未', 19: '戌' },
      '水': { 7: '辰', 11: '午', 21: '亥' }
    };

    const dayHours = hourElements[dayElement] || {};

    Object.entries(dayHours).forEach(([hour, branch]) => {
      auspiciousHours.push(`${parseInt(hour)}:00-${parseInt(hour)+1}:00 (${branch}时)`);
    });

    return auspiciousHours;
  }

          getLuckyNumbers(bazi          , date      )           {
    const dayMaster = bazi.dayPillar[0];
    const dayElement = this.getElementFromStem(dayMaster);

    // Base numbers based on element
    const elementNumbers                              = {
      '木': [3, 8, 21, 26, 39],
      '火': [2, 7, 14, 27, 34],
      '土': [5, 10, 15, 20, 30],
      '金': [4, 9, 18, 22, 31],
      '水': [1, 6, 13, 24, 36]
    };

    // Add date-based numbers
    const dateNumbers = [
      date.getDate(),
      date.getMonth() + 1,
      date.getFullYear() % 100
    ];

    return [...elementNumbers[dayElement], ...dateNumbers].slice(0, 5);
  }

          getLuckyColors(bazi          , dayElement        )           {
    const elementColors                              = {
      '木': ['绿色', '青色', '翠绿色'],
      '火': ['红色', '紫色', '橙色'],
      '土': ['黄色', '棕色', '米色'],
      '金': ['白色', '金色', '银色'],
      '水': ['黑色', '蓝色', '灰色']
    };

    return elementColors[dayElement] || ['白色'];
  }

          generateMonthlyAdvice(bazi          , monthGanZhi        , theme        )           {
    const advice = [];

    // Theme-based advice
    if (theme.includes("财运")) {
      advice.push("把握投资机会，但也要控制风险");
      advice.push("可考虑多元化投资组合");
    } else if (theme.includes("事业")) {
      advice.push("积极主动展现能力");
      advice.push("与上司同事保持良好沟通");
    } else if (theme.includes("权威")) {
      advice.push("树立权威形象但要避免专断");
      advice.push("承担更多责任展示领导力");
    } else if (theme.includes("学习")) {
      advice.push("投资学习和自我提升");
      advice.push("考取证书或学习新技能");
    } else {
      advice.push("保持日常工作的稳定性");
      advice.push("为未来机会做准备");
    }

    return advice;
  }

          calculateYearlyTrend(bazi          , yearGanZhi        )            {
    const dayMaster = bazi.dayPillar[0];
    const yearStem = yearGanZhi[0];
    const yearBranch = yearGanZhi[1];

    // Calculate trend based on multiple factors
    let trendScore = 0;

    // Stem relationship
    if (this.isWealthElement(dayMaster, yearStem)) trendScore += 30;
    if (this.isOutputElement(dayMaster, yearStem)) trendScore += 20;
    if (this.isPowerElement(dayMaster, yearStem)) trendScore += 10;
    if (this.isResourceElement(dayMaster, yearStem)) trendScore += 15;

    // Branch relationship with day branch
    const branchRel = this.getBranchRelationship(bazi.dayPillar[1], yearBranch);
    if (branchRel === 'combination') trendScore += 20;
    if (branchRel === 'clash') trendScore -= 30;

    if (trendScore > 40) return 'rising';
    if (trendScore > 10) return 'stable';
    if (trendScore > -10) return 'volatile';
    return 'declining';
  }

          generateKeyMoments(bazi          , year        , yearGanZhi        )              {
    const keyMoments              = [];

    // Analyze each month for significant events
    for (let month = 1; month <= 12; month++) {
      const solar = Solar.fromYmd(year, month, 1);
      const lunar = solar.getLunar();
      const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

      const significance = this.getMonthSignificance(bazi, monthGanZhi, yearGanZhi);

      if (significance.type !== 'neutral') {
        keyMoments.push({
          month,
          event: significance.event,
          impact: significance.impact,
          type: significance.type
        });
      }
    }

    return keyMoments;
  }

          getMonthSignificance(bazi          , monthGanZhi        , yearGanZhi        ) {
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    // Check for major fortune patterns
    if (this.isWealthElement(dayMaster, monthStem)) {
      return {
        event: "财运亨通，把握投资机会",
        impact: 'major',
        type: 'opportunity'
      };
    }

    if (this.isPowerElement(dayMaster, monthStem)) {
      return {
        event: "权职提升或增加责任",
        impact: 'major',
        type: 'opportunity'
      };
    }

    if (this.hasMonthClash(bazi, monthGanZhi)) {
      return {
        event: "月柱相冲，需要谨慎应对",
        impact: 'major',
        type: 'challenge'
      };
    }

    return { event: "", impact: 'minor', type: 'neutral' };
  }

          hasMonthClash(bazi          , monthGanZhi        )          {
    const monthBranch = bazi.monthPillar[1];
    const currentBranch = monthGanZhi[1];

    const clashes = [
      ['子', '午'], ['丑', '未'], ['寅', '申'],
      ['卯', '酉'], ['辰', '戌'], ['巳', '亥']
    ];

    return clashes.some(clash =>
      clash.includes(monthBranch) && clash.includes(currentBranch)
    );
  }

          identifyCrisisPeriods(bazi          , year        , yearGanZhi        )                 {
    const crisisPeriods                 = [];

    // Identify challenging months
    for (let month = 1; month <= 12; month++) {
      const solar = Solar.fromYmd(year, month, 1);
      const lunar = solar.getLunar();
      const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

      if (this.isChallengingMonth(bazi, monthGanZhi, yearGanZhi)) {
        // Group consecutive challenging months
        const existingPeriod = crisisPeriods.find(p => p.end_month === month - 1);

        if (existingPeriod) {
          existingPeriod.end_month = month;
          if (existingPeriod.severity === 'low') existingPeriod.severity = 'medium';
        } else {
          crisisPeriods.push({
            start_month: month,
            end_month: month,
            severity: 'low',
            description: "运势低迷，需要谨慎行事",
            mitigation_advice: "保持低调，避免重要决定，加强自我保护"
          });
        }
      }
    }

    return crisisPeriods;
  }

          isChallengingMonth(bazi          , monthGanZhi        , yearGanZhi        )          {
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    // Check for challenging combinations
    const stemRel = this.getStemRelationship(dayMaster, monthStem);
    if (stemRel === 'opposite') return true;
    if (stemRel === 'clash') return true;

    return this.hasMonthClash(bazi, monthGanZhi);
  }

          identifyOpportunities(bazi          , year        , yearGanZhi        )                {
    const opportunities                = [];

    for (let month = 1; month <= 12; month++) {
      const solar = Solar.fromYmd(year, month, 1);
      const lunar = solar.getLunar();
      const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

      const opportunity = this.getMonthOpportunity(bazi, month, monthGanZhi);
      if (opportunity) {
        opportunities.push(opportunity);
      }
    }

    return opportunities;
  }

          getMonthOpportunity(bazi          , month        , monthGanZhi        )                     {
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    if (this.isWealthElement(dayMaster, monthStem)) {
      return {
        month,
        sector: "投资理财",
        potential: 'high',
        action_required: "研究投资机会，适时入场"
      };
    }

    if (this.isOutputElement(dayMaster, monthStem)) {
      return {
        month,
        sector: "事业发展",
        potential: 'medium',
        action_required: "展现才能，争取晋升"
      };
    }

    return null;
  }

          calculateYearlyAspect(bazi          , year        , aspect        , yearGanZhi        )               {
    let score = 50;
    const peakMonths           = [];
    const challengingMonths           = [];

    // Calculate monthly scores for the year
    const monthlyScores           = [];
    for (let month = 1; month <= 12; month++) {
      const monthlyScore = this.getMonthlyAspectScore(bazi, year, month, aspect, yearGanZhi);
      monthlyScores.push(monthlyScore);
    }

    // Find peaks and challenges
    monthlyScores.forEach((score, index) => {
      const month = index + 1;
      if (score > 70) peakMonths.push(month);
      if (score < 40) challengingMonths.push(month);
    });

    // Calculate average score
    const averageScore = Math.round(monthlyScores.reduce((a, b) => a + b, 0) / 12);

    const adviceMap                                                 = {
      career: {
        high: "把握晋升机会，展现领导才能",
        medium: "稳扎稳打，持续提升专业能力",
        low: "保持低调，学习新技能为未来做准备"
      },
      wealth: {
        high: "积极理财，可考虑扩大投资",
        medium: "稳健理财，平衡风险与收益",
        low: "保守理财，避免高风险投资"
      },
      relationship: {
        high: "积极社交，维系重要人脉关系",
        medium: "保持沟通，增进理解",
        low: "多包容理解，避免冲突"
      },
      health: {
        high: "保持良好习惯，适度运动",
        medium: "规律作息，注意饮食健康",
        low: "特别注意身体，及时检查"
      }
    };

    const scoreLevel = averageScore > 70 ? 'high' : averageScore < 40 ? 'low' : 'medium';
    const advice = adviceMap[aspect][scoreLevel];

    return {
      score: averageScore,
      peak_months: peakMonths,
      challenging_months: challengingMonths,
      advice
    };
  }

          getMonthlyAspectScore(bazi          , year        , month        , aspect        , yearGanZhi        )         {
    const solar = Solar.fromYmd(year, month, 1);
    const lunar = solar.getLunar();
    const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

    const baseScore = this.calculateBaseScore(bazi, monthGanZhi);

    // Apply aspect-specific modifiers
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    let modifier = 0;

    switch (aspect) {
      case 'career':
        if (this.isOutputElement(dayMaster, monthStem)) modifier += 20;
        if (this.isPowerElement(dayMaster, monthStem)) modifier += 10;
        break;
      case 'wealth':
        if (this.isWealthElement(dayMaster, monthStem)) modifier += 25;
        break;
      case 'relationship':
        if (this.isPowerElement(dayMaster, monthStem)) modifier += 15;
        break;
      case 'health':
        if (this.isResourceElement(dayMaster, monthStem)) modifier += 15;
        break;
    }

    return Math.max(1, Math.min(100, baseScore + modifier));
  }

          calculateZodiacCompatibility(bazi          , year        )                      {
    const yearAnimal = this.zodiacAnimals[(year - 4) % 12];

    const baziAnimal = this.getZodiacFromPillar(bazi.yearPillar);

    const favorable = this.getFavorableZodiacs(baziAnimal);
    const challenging = this.getChallengingZodiacs(baziAnimal);
    const neutral = this.zodiacAnimals.filter(z =>
      !favorable.includes(z) && !challenging.includes(z) && z !== baziAnimal
    );

    return {
      favorable,
      neutral,
      challenging
    };
  }

          getZodiacFromPillar(pillar        )         {
    const branchIndex = this.earthlyBranches.indexOf(pillar[1]);
    return this.zodiacAnimals[branchIndex];
  }

          getFavorableZodiacs(zodiac        )           {
    const favorableMap                              = {
      '鼠': ['龙', '猴', '牛'],
      '牛': ['鼠', '蛇', '鸡'],
      '虎': ['马', '狗', '猪'],
      '兔': ['羊', '狗', '猪'],
      '龙': ['鼠', '猴', '鸡'],
      '蛇': ['牛', '鸡', '猴'],
      '马': ['虎', '羊', '狗'],
      '羊': ['马', '猪', '兔'],
      '猴': ['鼠', '龙', '蛇'],
      '鸡': ['牛', '龙', '蛇'],
      '狗': ['虎', '马', '兔'],
      '猪': ['虎', '兔', '羊']
    };

    return favorableMap[zodiac] || [];
  }

          getChallengingZodiacs(zodiac        )           {
    const challengingMap                              = {
      '鼠': ['马', '兔', '羊'],
      '牛': ['羊', '马', '狗'],
      '虎': ['猴', '蛇', '猪'],
      '兔': ['鼠', '龙', '鸡'],
      '龙': ['狗', '兔', '龙'],
      '蛇': ['虎', '猪', '猴'],
      '马': ['鼠', '牛', '马'],
      '羊': ['牛', '鼠', '狗'],
      '猴': ['虎', '猪', '蛇'],
      '鸡': ['兔', '狗', '鸡'],
      '狗': ['龙', '牛', '羊'],
      '猪': ['蛇', '猴', '虎']
    };

    return challengingMap[zodiac] || [];
  }

          identifyFavorableMonths(bazi          , year        , yearGanZhi        )           {
    const favorableMonths           = [];

    for (let month = 1; month <= 12; month++) {
      const solar = Solar.fromYmd(year, month, 1);
      const lunar = solar.getLunar();
      const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

      if (this.isFavorableMonth(bazi, monthGanZhi)) {
        favorableMonths.push(month);
      }
    }

    return favorableMonths;
  }

          identifyChallengingMonths(bazi          , year        , yearGanZhi        )           {
    const challengingMonths           = [];

    for (let month = 1; month <= 12; month++) {
      const solar = Solar.fromYmd(year, month, 1);
      const lunar = solar.getLunar();
      const monthGanZhi = `${lunar.getMonthGan()}${lunar.getMonthZhi()}`;

      if (this.isChallengingMonth(bazi, monthGanZhi, yearGanZhi)) {
        challengingMonths.push(month);
      }
    }

    return challengingMonths;
  }

          isFavorableMonth(bazi          , monthGanZhi        )          {
    const dayMaster = bazi.dayPillar[0];
    const monthStem = monthGanZhi[0];

    // Check for favorable element relationships
    return this.isWealthElement(dayMaster, monthStem) ||
           this.isOutputElement(dayMaster, monthStem) ||
           this.isResourceElement(dayMaster, monthStem);
  }

          generateYearlyAdvice(bazi          , yearGanZhi        , trend           )           {
    const advice           = [];

    // Trend-based advice
    switch (trend) {
      case 'rising':
        advice.push("运势上升年，把握机会积极进取");
        advice.push("可以扩大投资和事业发展");
        break;
      case 'stable':
        advice.push("运势平稳年，稳中求进");
        advice.push("适合积累和学习，为未来打基础");
        break;
      case 'volatile':
        advice.push("运势波动年，需谨慎应对");
        advice.push("做好风险管理，避免冲动决策");
        break;
      case 'declining':
        advice.push("运势低迷年，宜保守行事");
        advice.push("专注于自我提升，等待时机");
        break;
    }

    // Year-specific advice
    const dayMaster = bazi.dayPillar[0];
    const yearStem = yearGanZhi[0];

    if (this.isWealthElement(dayMaster, yearStem)) {
      advice.push("财运亨通，但也要注意理财规划");
    }

    if (this.isPowerElement(dayMaster, yearStem)) {
      advice.push("权职提升之年，注意人际关系处理");
    }

    advice.push("保持身心健康，这是一切发展的基础");

    return advice;
  }

          formatDate(date      )         {
    return date.toISOString().split('T')[0];
  }
}
var clipminiFortuneCalculator = new FortuneCalculator();

