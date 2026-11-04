import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workshop_models.dart';
import 'workshop_storage.dart';

class PdfGeneratorService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.MemoryImage? _hafezLogoImage;

  static Future<void> _ensureAssetsLoaded() async {
    if (_regularFont == null || _boldFont == null) {
      final regData = await rootBundle.load('assets/fonts/Rubik-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Rubik-Bold.ttf');
      _regularFont = pw.Font.ttf(regData);
      _boldFont = pw.Font.ttf(boldData);
    }
    if (_hafezLogoImage == null) {
      try {
        final logoBytes = await rootBundle.load('assets/images/hafez_icon.png');
        _hafezLogoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }
  }

  /// ترويسة شركة الحافظ الرسمية في ملفات الـ PDF
  static pw.Widget _buildHafezHeader({
    required String title,
    required String docDate,
    required ClientRecord client,
    required PricingSettings settings,
    PdfColor bannerColor = const PdfColor.fromInt(0xFF7F1D1D),
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bannerColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (_hafezLogoImage != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(left: 10),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(_hafezLogoImage!, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    settings.companyName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    settings.companySubtitle,
                    style: const pw.TextStyle(
                      color: PdfColor.fromInt(0xFFFEF2F2),
                      fontSize: 8.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      color: PdfColor.fromInt(0xFFFDE68A),
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'العميل: ${client.clientName}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (client.clientPhone.isNotEmpty)
                pw.Text(
                  'الهاتف: ${client.clientPhone}',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 9.5),
                ),
              pw.Text(
                'التاريخ: $docDate',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 1. توليد كشف عرض السعر المعماري الموضح برسم كروكي هندسي لكل فتحة وسعرها
  static Future<Uint8List> buildQuotationPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureAssetsLoaded();
    final pdf = pw.Document();
    final bool minOneM2 = storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalSectorsCost = 0.0;
    double totalGlassAndSpacerCost = 0.0;
    double totalGeorgianCost = 0.0;
    double totalAreaAll = 0.0;

    for (final item in client.items) {
      final sector = storage.getSectorById(item.sectorId);
      final double area = item.totalAreaM2(minOneM2: minOneM2);
      final double secCost = item.calculateSectorCost(minOneM2: minOneM2);
      final double glCost = item.calculateGlassAndSpacerCost(sector, minOneM2: minOneM2);
      final double geoCost = item.calculateGeorgianCost();

      totalAreaAll += area;
      totalSectorsCost += secCost;
      totalGlassAndSpacerCost += glCost;
      totalGeorgianCost += geoCost;
    }

    final double grandSubTotal = totalSectorsCost + totalGlassAndSpacerCost + totalGeorgianCost;
    final double netTotal = (grandSubTotal - client.discountAmount).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: _regularFont!,
          bold: _boldFont!,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          _buildHafezHeader(
            title: 'كشف عرض سعر مقايسة معتمد بالرسم الهندسي والمواصفات',
            docDate: client.createdAt,
            client: client,
            settings: storage.pricingSettings,
            bannerColor: const PdfColor.fromInt(0xFF7F1D1D),
          ),
          pw.SizedBox(height: 12),

          // بطاقات الفتحات: كل فتحة مرسومة برسم كروكي معماري مع أبعادها وسعر المتر وسعرها الإجمالي
          ...List.generate(client.items.length, (i) {
            final item = client.items[i];
            final sector = storage.getSectorById(item.sectorId);
            final double area = item.totalAreaM2(minOneM2: minOneM2);
            final double singleArea = item.singleWindowAreaM2(minOneM2: minOneM2);
            final double secCost = item.calculateSectorCost(minOneM2: minOneM2);
            final double glCost = item.calculateGlassAndSpacerCost(sector, minOneM2: minOneM2);
            final double geoCost = item.calculateGeorgianCost();
            final double rowTotal = secCost + glCost + geoCost;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // الرسم الكروكي المعماري للشباك / الباب
                  pw.Container(
                    width: 70,
                    height: 60,
                    margin: const pw.EdgeInsets.only(left: 10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF0F172A),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFD97706), width: 1),
                    ),
                    child: pw.Center(
                      child: pw.CustomPaint(
                        size: const PdfPoint(56, 46),
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          _drawPdfWindowSchema(
                            canvas,
                            size,
                            item.widthCm,
                            item.heightCm,
                            item.sashCount,
                            item.openType,
                            item.barType,
                            item.hasGeorgianBars,
                            item.isDoubleGlass,
                          );
                        },
                      ),
                    ),
                  ),

                  // تفاصيل المقاس والمواصفات
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor.fromInt(0xFF7F1D1D),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Text(
                              '${item.label} [${item.unitType} ${item.openType} - ${item.sashCount} ضلفة]',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'المقاس: ${item.widthCm.toStringAsFixed(1)} × ${item.heightCm.toStringAsFixed(1)} سم  |  العدد: ${item.quantity}  |  المساحة: ${singleArea.toStringAsFixed(2)} م² (الإجمالي: ${area.toStringAsFixed(2)} م²)',
                          style: const pw.TextStyle(fontSize: 8.2, color: PdfColor.fromInt(0xFF334155)),
                        ),
                        pw.Text(
                          'القطاع: ${item.sectorName} (${item.sectorPricePerM2.toStringAsFixed(0)} ج.م/م²)  |  البار: ${item.barType}  |  الفتح: ${item.openDirection}',
                          style: const pw.TextStyle(fontSize: 7.8, color: PdfColor.fromInt(0xFF475569)),
                        ),
                        pw.Text(
                          'الزجاج: ${item.glassSummaryText} ${item.hasGeorgianBars ? " + جورجيا" : ""}',
                          style: pw.TextStyle(fontSize: 7.8, color: const PdfColor.fromInt(0xFF7F1D1D), fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // السعر الإجمالي للبند
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF2F2),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFF7F1D1D), width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('إجمالي البند', style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF475569))),
                        pw.Text(
                          '${rowTotal.toStringAsFixed(1)} ج.م',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 12),

          // صندوق الإجماليات والملخص المالي
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF7F1D1D), width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ملخص الحسابات المالية لعرض السعر:',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF7F1D1D),
                  ),
                ),
                pw.SizedBox(height: 4),
                _summaryRow('إجمالي عدد الفتحات والمساحة الكلية:',
                    '${client.items.length} فتحة — إجمالي ${totalAreaAll.toStringAsFixed(2)} م²'),
                _summaryRow('إجمالي تكلفة قطاعات الألومنيوم/uPVC:',
                    '${totalSectorsCost.toStringAsFixed(2)} ج.م'),
                _summaryRow('إجمالي تكلفة الزجاج (شامل الدبل والسبيسر):',
                    '${totalGlassAndSpacerCost.toStringAsFixed(2)} ج.م'),
                _summaryRow('إجمالي تكلفة الجورجيا:',
                    '${totalGeorgianCost.toStringAsFixed(2)} ج.م'),
                if (client.discountAmount > 0)
                  _summaryRow('قيمة الخصم الممنوح للعميل:',
                      '- ${client.discountAmount.toStringAsFixed(2)} ج.م'),
                pw.Divider(color: PdfColors.grey400),
                _summaryRow(
                  'الصافي النهائي المستحق لعرض السعر:',
                  '${netTotal.toStringAsFixed(2)} ج.م',
                  isBold: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFEF3C7),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '📞 اتصل بنا: ${storage.pricingSettings.companyPhones}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                ),
                pw.Text(
                  'العنوان: ${storage.pricingSettings.companyAddress}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
                ),
              ],
            ),
          ),
          if (client.notes.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'شروط وملاحظات: ${client.notes}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// 2. توليد كشف الطلبية الشامل والتخصيم والزجاج والأعواد (Order & Cutting PDF)
  static Future<Uint8List> buildOrderAndCuttingPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureAssetsLoaded();
    final pdf = pw.Document();

    final List<List<String>> partsCuttingRows = [];
    final List<List<String>> glassOrderRows = [];
    final Map<String, List<double>> piecesByPartKey = {};

    for (int i = 0; i < client.items.length; i++) {
      final item = client.items[i];
      final sector = storage.getSectorById(item.sectorId);
      if (sector != null) {
        for (final part in sector.parts) {
          final double pieceLen = part.calculatePieceLength(
              item.widthCm, item.heightCm, item.sashCount);
          final int totalQty =
              part.calculateTotalCount(item.quantity, item.sashCount);

          partsCuttingRows.add([
            '$totalQty قطعة',
            '${pieceLen.toStringAsFixed(1)} سم',
            part.role,
            part.name,
            sector.name,
            '${item.label} (${item.unitType} ${item.openType})',
          ]);

          final String groupKey = '${sector.name} — ${part.name}';
          piecesByPartKey.putIfAbsent(groupKey, () => []);
          for (int q = 0; q < totalQty; q++) {
            piecesByPartKey[groupKey]!.add(pieceLen);
          }
        }
      }

      if (item.hasGlass) {
        final double gw = sector != null
            ? sector.calculateGlassWidthCm(item.widthCm, item.sashCount)
            : (item.widthCm / item.sashCount) - 10.0;
        final double gh = sector != null
            ? sector.calculateGlassHeightCm(item.heightCm, item.sashCount)
            : item.heightCm - 18.0;
        final int panesPerSashSet = item.sashCount * item.quantity;

        if (!item.isDoubleGlass) {
          glassOrderRows.add([
            item.hasGeorgianBars
                ? '${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(1)} م'
                : '—',
            'بدون سبيسر (سنجل)',
            '$panesPerSashSet فردة (${item.glass1Name})',
            '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
            'سنجل (فردي)',
            '${item.label} (${item.unitType})',
          ]);
        } else {
          final double spacerMeters = item.totalSpacerMeters(sector);
          glassOrderRows.add([
            item.hasGeorgianBars
                ? '${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(1)} م'
                : '—',
            '${spacerMeters.toStringAsFixed(1)} م سبيسر',
            '$panesPerSashSet فردة (${item.glass1Name}) + $panesPerSashSet فردة (${item.glass2Name})',
            '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
            'دبل (مزدوج)',
            '${item.label} (${item.unitType})',
          ]);
        }
      }
    }

    final List<List<String>> barSummaryRows = [];
    final double stockLen = storage.pricingSettings.defaultStockBarLengthCm;
    final double kerfMm = storage.pricingSettings.defaultSawKerfMm;

    piecesByPartKey.forEach((partKey, piecesList) {
      final plans = WorkshopStorage.optimize1DBars(
        requiredPiecesCm: piecesList,
        stockLengthCm: stockLen,
        sawKerfMm: kerfMm,
      );
      for (final plan in plans) {
        barSummaryRows.add([
          '${plan.wasteLengthCm.toStringAsFixed(1)} سم',
          plan.cutsCm.map((c) => c.toStringAsFixed(1)).join(' + '),
          'عود #${plan.barNumber} (من ${plans.length})',
          partKey,
        ]);
      }
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: _regularFont!,
          bold: _boldFont!,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          _buildHafezHeader(
            title: 'كشف أمر التشغيل والطلبية الشامل للورشة وتقطيع الأعواد',
            docDate: client.createdAt,
            client: client,
            settings: storage.pricingSettings,
            bannerColor: const PdfColor.fromInt(0xFF15803D),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'أولاً: كشف تخصيم وتقطيع أجزاء القطاعات (الحلق، الضلف، السكاكين، والمكملات):',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              'العدد الإجمالي',
              'طول القص الصافي',
              'الفئة',
              'اسم الجزء',
              'القطاع',
              'الفتحة / البند',
            ],
            data: partsCuttingRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.0,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F172A),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'ثانياً: كشف طلبية الزجاج (الفردي / الدبل) والسبيسر والجورجيا:',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF7F1D1D),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              'أمتار الجورجيا',
              'السبيسر (للدبل)',
              'عدد ونوع فردات الزجاج',
              'مقاس الزجاج الصافي',
              'النظام',
              'الفتحة / البند',
            ],
            data: glassOrderRows.isNotEmpty
                ? glassOrderRows
                : [
                    ['—', '—', 'لا يوجد زجاج', '—', '—', '—']
                  ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.0,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF7F1D1D),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'ثالثاً: جدول أوامر تقطيع الأعواد القياسية (${stockLen.toStringAsFixed(0)} سم) وتقليل الهالك:',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF15803D),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.TableHelper.fromTextArray(
            headers: [
              'الفضلة (الهالك)',
              'توزيع القطعيات داخل العود (سم)',
              'رقم العود',
              'القطاع والجزء',
            ],
            data: barSummaryRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.0,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF15803D),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// رسم كروكي معماري لفتحة الشباك / الباب داخل ملف الـ PDF
  static void _drawPdfWindowSchema(
    PdfGraphics canvas,
    PdfPoint size,
    double wCm,
    double hCm,
    int sashes,
    String openType,
    String barType,
    bool georgian,
    bool dblGlass,
  ) {
    final double aspect = wCm / (hCm > 0 ? hCm : 1);
    double dW = size.x;
    double dH = dW / aspect;
    if (dH > size.y) {
      dH = size.y;
      dW = dH * aspect;
    }
    final double sX = (size.x - dW) / 2;
    final double sY = (size.y - dH) / 2;

    // بار خارجي
    if (barType != 'بدون بار') {
      canvas.setColor(const PdfColor.fromInt(0xFFD97706));
      canvas.drawRect(sX - 1.5, sY - 1.5, dW + 3, dH + 3);
      canvas.strokePath();
    }

    // الحلق
    canvas.setColor(const PdfColor.fromInt(0xFFCBD5E1));
    canvas.drawRect(sX, sY, dW, dH);
    canvas.fillPath();
    canvas.setColor(const PdfColor.fromInt(0xFF334155));
    canvas.drawRect(sX, sY, dW, dH);
    canvas.strokePath();

    // الضلف
    final int safeS = sashes > 0 ? sashes : 1;
    final double sashW = (dW - 4) / safeS;
    for (int i = 0; i < safeS; i++) {
      final double sx = sX + 2 + (i * sashW);
      canvas.setColor(const PdfColor.fromInt(0xFFF1F5F9));
      canvas.drawRect(sx, sY + 2, sashW, dH - 4);
      canvas.fillPath();

      // زجاج
      canvas.setColor(dblGlass ? const PdfColor.fromInt(0xFF0284C7) : const PdfColor.fromInt(0xFF38BDF8));
      canvas.drawRect(sx + 2, sY + 4, sashW - 4, dH - 8);
      canvas.strokePath();

      // جورجيا
      if (georgian) {
        canvas.setColor(const PdfColor.fromInt(0xFFFDE68A));
        canvas.drawLine(sx + 2, sY + dH * 0.5, sx + sashW - 2, sY + dH * 0.5);
        canvas.drawLine(sx + sashW * 0.5, sY + 4, sx + sashW * 0.5, sY + dH - 4);
        canvas.strokePath();
      }
    }
  }

  static pw.Widget _summaryRow(String title, String val, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: isBold ? 10.0 : 8.8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            val,
            style: pw.TextStyle(
              fontSize: isBold ? 10.5 : 8.8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBold ? const PdfColor.fromInt(0xFF7F1D1D) : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<String> savePdfToDeviceStorage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    dir ??= await getTemporaryDirectory();

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> generateAndShareBothPdfs({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    final quoteBytes =
        await buildQuotationPdfBytes(client: client, storage: storage);
    final orderBytes =
        await buildOrderAndCuttingPdfBytes(client: client, storage: storage);

    final safeName =
        client.clientName.replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_');
    final quotePath = await savePdfToDeviceStorage(
      bytes: quoteBytes,
      fileName: 'عرض_سعر_شركة_الحافظ_$safeName.pdf',
    );
    final orderPath = await savePdfToDeviceStorage(
      bytes: orderBytes,
      fileName: 'كشف_طلبية_شركة_الحافظ_$safeName.pdf',
    );

    await Share.shareXFiles(
      [XFile(quotePath), XFile(orderPath)],
      text:
          'مرفق ملفي PDF معتمدين من شركة الحافظ للعميل (${client.clientName}):\n1. كشف عرض السعر بالرسم الهندسي والمقاسات\n2. كشف الطلبية والتخصيم وتقطيع الزجاج والأعواد\n(تم حفظ الملفين أيضاً في مجلد Download بالجهاز)',
    );
  }

  static Future<void> previewPdfBytes(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }
}
