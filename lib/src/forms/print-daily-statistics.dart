import 'dart:math';

import 'package:intl/intl.dart';
import 'package:nightscout_reporter/src/globals.dart';
import 'package:nightscout_reporter/src/jsonData.dart';

import 'base-print.dart';

class PrintDailyStatistics extends BasePrint {
  @override
  String id = "daystats";

  bool showHbA1c, showStdabw, showCount, showPercentile, showVarK, showTDD, showExtendedInsulinStatictics;
  double _maxTDD = 0.0;

  @override
  List<ParamInfo> params = [
    ParamInfo(0, msgParam1, boolValue: true),
    ParamInfo(1, msgParam2, boolValue: true),
    ParamInfo(2, msgParam3, boolValue: true),
    ParamInfo(3, msgParam4, boolValue: true),
    ParamInfo(4, msgParam5, boolValue: false),
    ParamInfo(5, msgParam6, boolValue: false),
    ParamInfo(6, msgParam7, boolValue: false),
  ];

  static String get msgParam1 => Intl.message("Spalte Messwerte");
  static String get msgParam2 => Intl.message("Spalte Standardabweichung");
  static String get msgParam3 => Intl.message("Spalten Perzentile");
  static String get msgParam4 => Intl.message("Spalte HbA1c");
  static String get msgParam5 => Intl.message("Spalte Variationskoeffizient");
  static String get msgParam6 => Intl.message("Spalte TDD");
  static String get msgParam7 => Intl.message("erweiterte Insulinstatistik");

  @override
  extractParams() {
    showCount = params[0].boolValue;
    showStdabw = params[1].boolValue;
    showPercentile = params[2].boolValue;
    showHbA1c = params[3].boolValue;
    showVarK = params[4].boolValue;
    showTDD = false;//params[5].boolValue;
    showExtendedInsulinStatictics = params[6].boolValue;
  }

  @override
  dynamic get estimatePageCount {
    int count = g?.period?.dayCount ?? 0;
    count = (count / 19).ceil();
    return {"count": count, "isEstimated": false};
  }

//  @override
//  String get title => Intl.message("Tagesstatistik");

  @override
  bool get isPortrait => false;

  @override
  double get scale => 1.0;

  SettingsData _settings;

  PrintDailyStatistics() {
    init();
  }

  fillRow(dynamic row, double f, String firstCol, DayData day, String style) {
    addTableRow(true, cm(2.9), row, {"text": msgDate, "style": "total", "alignment": "center"},
        {"text": firstCol, "style": "total", "alignment": "center"});
    addTableRow(true, cm(f * 100), row, {
      "text": msgDistribution,
      "style": "total",
      "alignment": "center"
    }, {
      "style": style,
      "canvas": [
        {"type": "rect", "color": colLow, "x": cm(0), "y": cm(0), "w": cm(day.lowPrz(g) * f), "h": cm(0.5)},
        {
          "type": "rect",
          "color": colNorm,
          "x": cm(day.lowPrz(g) * f),
          "y": cm(0),
          "w": cm(day.normPrz(g) * f),
          "h": cm(0.5)
        },
        {
          "type": "rect",
          "color": colHigh,
          "x": cm((day.lowPrz(g) + day.normPrz(g)) * f),
          "y": cm(0),
          "w": cm(day.highPrz(g) * f),
          "h": cm(0.5)
        }
      ]
    });
    addTableRow(showTDD, cm(f*100), row, {
      "text": msgTDD,
      "style": "total",
      "alignment": "center"
    }, {
      "style": style,
      "canvas": [
        {"type": "rect", "color": colBasalDay, "x": cm(0), "y": cm(0), "w": cm(day.ieBasalSum * f * 100 / _maxTDD), "h": cm(0.5)},
        {
          "type": "rect",
          "color": colBolus,
          "x": cm(day.ieBasalSum * f * 100 / _maxTDD),
          "y": cm(0),
          "w": cm(day.ieBolusSum * f * 100 / _maxTDD),
          "h": cm(0.5)
        },
      ]
    });

    addTableRow(true, "*", row, {
      "text": msgLow(targets(repData)["low"]),
      "style": "total",
      "alignment": "center",
      "fillColor": colLow
    }, {
      "text": "${g.fmtNumber(day.lowPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colLow : null
    });
    addTableRow(true, "*", row, {
      "text": msgNormal,
      "style": "total",
      "alignment": "center",
      "fillColor": colNorm
    }, {
      "text": "${g.fmtNumber(day.normPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colNorm : null
    });
    addTableRow(true, "*", row, {
      "text": msgHigh(targets(repData)["high"]),
      "style": "total",
      "alignment": "center",
      "fillColor": colHigh
    }, {
      "text": "${g.fmtNumber(day.highPrz(g), 0)} %",
      "style": style,
      "alignment": "right",
      "fillColor": style == "total" ? colHigh : null
    });
    // two columns for carbohydrates. Maybe they are better placed in an extra area below the line
    // to avoid columns to grow beyond every limit.
/*
    addRow(true, "auto", row, {"text": "KH\nin g", "style": "total", "alignment": "center"},
      {"text": "${carbFromData(day.carbs)}", "style": style, "alignment": "right"});
    addRow(true, "auto", row, {"text": msgKHPerDay, "style": "total", "alignment": "center"},
      {"text": "${carbFromData(day.avgCarbs)}", "style": style, "alignment": "right"});
// */
    addTableRow(showCount, "auto", row, {"text": msgValues, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.entryCount, 0)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgMin, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.min)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgMax, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.max)}", "style": style, "alignment": "right"});
    addTableRow(true, "auto", row, {"text": msgAverage, "style": "total", "alignment": "center"},
        {"text": "${g.glucFromData(day.mid, 1)}", "style": style, "alignment": "right"});
    addTableRow(showStdabw, "auto", row, {"text": msgDeviation, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.stdAbw(g.glucMGDL), 1)}", "style": style, "alignment": "right"});
    addTableRow(showVarK, "auto", row, {"text": msgVarK, "style": "total", "alignment": "center"},
        {"text": "${g.fmtNumber(day.varK, 1)}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, cm(1.5), row, {"text": msg25, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 25))}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, cm(1.5), row, {"text": msgMedian, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 50))}", "style": style, "alignment": "right"});
    addTableRow(showPercentile, cm(1.5), row, {"text": msg75, "style": "total", "alignment": "center"},
        {"text": "${percentileFor(Globals.percentile(day.entries, 75))}", "style": style, "alignment": "right"});
    addTableRow(showHbA1c, cm(1.5), row, {"text": msgHbA1C, "style": "total", "alignment": "center", "color": colHbA1c},
        {"text": "${hba1c(day.mid)} %", "style": style, "alignment": "right", "color": colHbA1c});
    tableHeadFilled = true;
  }

  String percentileFor(double value) {
    if (value == -1) return "";
    return g.glucFromData(value, 1);
  }

  @override
  void fillPages(List<Page> pages) {
    tableHeadFilled = false;
    tableHeadLine = [];
    tableWidths = [];
    title = Intl.message("Tagesstatistik");
    titleInfo = titleInfoBegEnd();
    _settings = repData.status.settings;
    double f = 3.3;
    if(showTDD)
      f = f/2 - 0.3;
    var body = [];
    // maybe later the margins will work properly, up to now it
    // doesn't work beacause of hardcoded margins in the tablecells
    // this code has to be moved to addRow for operating correctly
/*
    int colCount = 6;
    double wid = width - 4.4 - f - 2.0;
    var widths = [cm(2.0), cm(f), w, w, w];
    if (showCount)widths.add(w);
    widths.add(w);
    widths.add(w);
    widths.add(w);
    if (showStdabw)widths.add(w);
    if (showPercentile)
    {
      widths.add(cm(1.5));
      widths.add(cm(1.5));
      widths.add(cm(1.5));
    }
    if (showHbA1c)widths.add(cm(1.5));
// */
    f /= 100;

    ProfileGlucData prevProfile = null;
    int lineCount = 0;
    var page = [];
    DayData totalDay = DayData(null, ProfileGlucData(ProfileStoreData("Intern")));
    totalDay.basalData.targetHigh = 0;
    totalDay.basalData.targetLow = 1000;
    int totalDays = 0;
    int oldLength = pages.length;
    _maxTDD = 0.0;

    for (DayData day in repData.data.days)
    {
      day.init();
      if (day.entryCount == 0) continue;
      _maxTDD = max(_maxTDD, day.ieBasalSum + day.ieBolusSum);
    }

    for (DayData day in repData.data.days) {
      if (day.entryCount == 0) continue;
      totalDays++;
      totalDay.entries.addAll(day.entries);
      totalDay.bloody.addAll(day.bloody);
      totalDay.treatments.addAll(day.treatments);
      totalDay.basalData.targetHigh = max(totalDay.basalData.targetHigh, day.basalData.targetHigh);
      totalDay.basalData.targetLow = min(totalDay.basalData.targetLow, day.basalData.targetLow);
      var row = [];
      fillRow(row, f, fmtDate(day.date, null, true), day, "row");
      ProfileGlucData profile = repData.profile(DateTime(day.date.year, day.date.month, day.date.day));
      if (prevProfile == null ||
          profile.targetLow != prevProfile.targetLow ||
          profile.targetHigh != prevProfile.targetHigh) {
        body.add(tableHeadLine);
        lineCount += 2;
      }
      prevProfile = profile;

      body.add(row);
      lineCount++;
      if (lineCount == 21) {
        page.add(headerFooter());
        page.add(getTable(tableWidths, body));
        lineCount = 0;
        pages.add(Page(isPortrait, page));
        page = [];
        body = [];
        prevProfile = null;
      }
    }

    var row = [];
    totalDay.init();
    fillRow(row, f, msgDaySum(totalDays), totalDay, "total");
    body.add(row);

    if (prevProfile != null) {
      page.add(headerFooter());
      page.add(getTable(tableWidths, body));
      pages.add(Page(isPortrait, page));
    } else {
      Map test = pages.last.content.last as Map;
      test["columns"].last["table"]["body"].add(body.last);
    }
    if (repData.isForThumbs && pages.length - oldLength > 1) pages.removeRange(oldLength + 1, pages.length);
    pages.add(getInsulinPage(repData));
  }

  Page getInsulinPage(ReportData src)
  {
    String t = title;
    title = Intl.message("Insulinstatistik");

    double contentWidth = new Page(false, null).width - 2*xorg; // 23.25 --> 29.7
    double contentHeight = new Page(false, null).height - 1.5*yorg; // 13 --> 21
    double weekly_monthly_distance = 1;
    double legendHeight = 3;
    double dailyWidth = contentWidth;
    double weeklyWidth = (contentWidth - weekly_monthly_distance)/2;
    double allGraphHeight = contentHeight / 2 - legendHeight;
    double xo = xorg; // 3.35
    double yo = yorg; // 3.9
    Map<String, double> dailyValues = new Map();
    Map<String, double> weeklyValues = new Map();
    Map<String, double> monthlyValues = new Map();
    Map<String, int> weeklyCounter = new Map();
    Map<String, int> monthlyCounter = new Map();
    List<double> valuesDaily = [];
    List<double> valuesWeekly = [];
    List<double> valuesMonthly = [];
    List<String> xValuesDaily = [];
    List<String> xValuesWeekly = [];
    List<String> xValuesMonthly = [];
    for (DayData day in src.data.days) {
      double sum = 0;
      for (TreatmentData t in day.treatments)
        sum += t.insulin;
      String dayStr = fmtDateShort(day.date, "day");
      String weekStr = fmtDateShort(day.date, "week");
      String monthStr = fmtDateShort(day.date, "month");
      dailyValues.update(dayStr, (double v) => v + sum, ifAbsent: () => sum);
      weeklyValues.update(weekStr, (double v) => v + sum, ifAbsent: () => sum);
      weeklyCounter.update(weekStr, (int v) => v + 1, ifAbsent: () => 1);
      monthlyValues.update(monthStr, (double v) => v + sum, ifAbsent: () => sum);
      monthlyCounter.update(monthStr, (int v) => v + 1, ifAbsent: () => 1);
    }
    xValuesDaily = dailyValues.keys.toList();
    xValuesWeekly = weeklyValues.keys.toList();
    xValuesMonthly = monthlyValues.keys.toList();
    valuesDaily = dailyValues.values.toList();
    for (String s in xValuesWeekly)
      valuesWeekly.add(weeklyValues[s]/weeklyCounter[s]);
    for (String s in xValuesMonthly)
      valuesMonthly.add(monthlyValues[s]/monthlyCounter[s]);

    List<dynamic> daily = drawGraphicGridGeneric(allGraphHeight, dailyWidth,
        xo, yo,
        xValuesDaily, valuesDaily, "#000000", Intl.message("Gesamtinsulin pro Tag"), graphBottom: allGraphHeight);
    List<dynamic> weekly = drawGraphicGridGeneric(allGraphHeight, weeklyWidth,
        xo, yo + allGraphHeight + legendHeight,
        xValuesWeekly, valuesWeekly, "#000000", Intl.message("Gesamtinsulin pro Tag"), graphBottom: allGraphHeight);
    List<dynamic> monthly = drawGraphicGridGeneric(allGraphHeight, weeklyWidth,
        xo + weeklyWidth + weekly_monthly_distance, yo + allGraphHeight + legendHeight,
        xValuesMonthly, valuesMonthly, "#000000", Intl.message("Gesamtinsulin pro Tag"), graphBottom: allGraphHeight);

    List<dynamic> content = [ headerFooter(), ];
    content.addAll(daily);
    content.addAll(weekly);
    content.addAll(monthly);
    var ret = Page(isPortrait, content);

    title = t;
    return ret;
  }
}
