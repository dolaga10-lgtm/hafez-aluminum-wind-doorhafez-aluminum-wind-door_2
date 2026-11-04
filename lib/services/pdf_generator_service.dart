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

  static Future<void> _ensureFontsLoaded() async {
    if (_regularFont != null && _boldFont != null) return;
    final regData = await rootBundle.load('assets/fonts/Rubik-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Rubik-Bold.ttf');
    _regularFont = pw.Font.ttf(regData);
    _boldFont = pw.Font.ttf(boldData);
  }

  /// 1. توليد ملف PDF الأول: كشف عرض السعر للعميل (Quotation PDF)
  static Future<Uint8List> buildQuotationPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document();
    final bool minOneM2 = storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalSectorsCost = 0.0;
    double totalGlassAndSpacerCost = 0.0;
    double totalGeorgianCost = 0.0;
    double totalAreaAll = 0.0;

    final List<List<String>> tableRows = [];
    for (int i = 0; i < client.items.length; i++) {
      final item = client.items[i];
      final sector = storage.getSectorById(item.sectorId);
      final double area = item.totalAreaM2(minOneM2: minOneM2);
      final double secCost = item.calculateSectorCost(minOneM2: minOneM2);
      final double glCost =
          item.calculateGlassAndSpacerCost(sector, minOneM2: minOneM2);
      final double geoCost = item.calculateGeorgianCost();
      final double rowTotal = secCost + glCost + geoCost;

      totalAreaAll += area;
      totalSectorsCost += secCost;
      totalGlassAndSpacerCost += glCost;
      totalGeorgianCost += geoCost;

      tableRows.add([
        rowTotal.toStringAsFixed(1),
        geoCost > 0
            ? '${item.georgianMetersPerWindow * item.quantity} م (${geoCost.toStringAsFixed(0)})'
            : 'لا يوجد',
        item.glassSummaryText,
        area.toStringAsFixed(2),
        '${item.quantity}',
        '${item.widthCm.toStringAsFixed(1)} × ${item.heightCm.toStringAsFixed(1)} سم',
        '${item.sectorName} (${item.sashCount} ضلفة)',
        item.label,
        '${i + 1}',
      ]);
    }

    final double grandSubTotal =
        totalSectorsCost + totalGlassAndSpacerCost + totalGeorgianCost;
    final double netTotal =
        (grandSubTotal - client.discountAmount).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: _regularFont!,
          bold: _boldFont!,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#991B1B'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'الورشة الذكية — كشف عرض سعر مقايسة',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'تاريخ الإصدار: ${client.createdAt}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
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
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (client.clientPhone.isNotEmpty)
                      pw.Text(
                        'الهاتف: ${client.clientPhone}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    if (client.clientAddress.isNotEmpty)
                      pw.Text(
                        'العنوان: ${client.clientAddress}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Items Table
          pw.TableHelper.fromTextArray(
            headers: [
              'الإجمالي (ج.م)',
              'الجورجيا',
              'تفاصيل الزجاج والسبيسر',
              'المساحة م²',
              'العدد',
              'المقاس (عرض×ارتفاع)',
              'القطاع والنظام',
              'البند / الغرفة',
              'م',
            ],
            data: tableRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1E293B'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.2),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          ),
          pw.SizedBox(height: 18),

          // Financial Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              border: pw.Border.all(color: PdfColor.fromHex('#991B1B'), width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ملخص عرض السعر المالي:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#991B1B'),
                  ),
                ),
                pw.SizedBox(height: 6),
                _summaryRow('إجمالي عدد البنود والمساحة الكلية:',
                    '${client.items.length} بند — إجمالي ${totalAreaAll.toStringAsFixed(2)} م²'),
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
          if (client.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'ملاحظات وشروط التعاقد: ${client.notes}',
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// 2. توليد ملف PDF الثاني: كشف الطلبية الشامل والتخصيم وتقطيع الزجاج والأعواد
  static Future<Uint8List> buildOrderAndCuttingPdfBytes({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document();

    // تجميع أجزاء القطاعات لكل الشبابيك + تجميع مقاسات الزجاج والسبيسر والجورجيا
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
            '${item.label} (${item.widthCm.toStringAsFixed(0)}×${item.heightCm.toStringAsFixed(0)})',
          ]);

          final String groupKey = '${sector.name} — ${part.name}';
          piecesByPartKey.putIfAbsent(groupKey, () => []);
          for (int q = 0; q < totalQty; q++) {
            piecesByPartKey[groupKey]!.add(pieceLen);
          }
        }
      }

      // حساب مقاسات الزجاج الصافية لهذا الشباك
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
                ? '${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(2)} م'
                : '—',
            'بدون سبيسر (سنجل)',
            '$panesPerSashSet فردة (${item.glass1Name})',
            '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
            'سنجل (فردي)',
            item.label,
          ]);
        } else {
          final double spacerMeters = item.totalSpacerMeters(sector);
          glassOrderRows.add([
            item.hasGeorgianBars
                ? '${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(2)} م'
                : '—',
            '${spacerMeters.toStringAsFixed(2)} متر طولي سبيسر',
            '$panesPerSashSet فردة (${item.glass1Name}) + $panesPerSashSet فردة (${item.glass2Name})',
            '${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم',
            'دبل (مزدوج)',
            item.label,
          ]);
        }
      }
    }

    // حساب تقسيم الأعواد (600 سم) لكل جزء
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
        margin: const pw.EdgeInsets.all(22),
        theme: pw.ThemeData.withFont(
          base: _regularFont!,
          bold: _boldFont!,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#15803D'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'كشف الطلبية الشامل والتخصيم وتقطيع الزجاج والأعواد',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'طول العود القياسي: ${stockLen.toStringAsFixed(0)} سم | سُمك المنشار: ${kerfMm.toStringAsFixed(1)} مم',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9.5,
                      ),
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
                    pw.Text(
                      'التاريخ: ${client.createdAt}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          pw.Text(
            'أولاً: كشف تخصيم وتقطيع أجزاء القطاعات (الحلق، الضلف، السكاكين، والإضافات):',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'إجمالي العدد',
              'مقاس القص الصافي',
              'الفئة',
              'اسم الجزء',
              'القطاع',
              'الشباك / البند',
            ],
            data: partsCuttingRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0F172A'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.2),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'ثانياً: كشف طلبية الزجاج (الفردي / الدبل) والسبيسر والجورجيا:',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#991B1B'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'أمتار الجورجيا',
              'السبيسر (للدبل)',
              'عدد ونوع فردات الزجاج',
              'مقاس الزجاج الصافي',
              'النظام',
              'الشباك / البند',
            ],
            data: glassOrderRows.isNotEmpty
                ? glassOrderRows
                : [
                    ['—', '—', 'لا يوجد زجاج مضاف', '—', '—', '—']
                  ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#991B1B'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.2),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'ثالثاً: جدول تقسيم الأعواد القياسية (${stockLen.toStringAsFixed(0)} سم) وتقليل الهالك:',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#15803D'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'الفضلة المتبقية (الهالك)',
              'توزيع القطعيات داخل العود (سم)',
              'رقم العود',
              'القطاع والجزء',
            ],
            data: barSummaryRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#15803D'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.2),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryRow(String title, String val, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: isBold ? 11 : 9.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            val,
            style: pw.TextStyle(
              fontSize: isBold ? 11.5 : 9.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isBold ? PdfColor.fromHex('#991B1B') : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// حفظ ومشاركة ملفي الـ PDF معاً (عرض السعر + كشف الطلبية)
  static Future<void> generateAndShareBothPdfs({
    required ClientRecord client,
    required WorkshopStorage storage,
  }) async {
    final quoteBytes =
        await buildQuotationPdfBytes(client: client, storage: storage);
    final orderBytes =
        await buildOrderAndCuttingPdfBytes(client: client, storage: storage);

    final dir = await getTemporaryDirectory();
    final safeName =
        client.clientName.replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_');
    final quoteFile = File('${dir.path}/عرض_سعر_$safeName.pdf');
    final orderFile = File('${dir.path}/كشف_طلبية_وتخصيم_$safeName.pdf');

    await quoteFile.writeAsBytes(quoteBytes);
    await orderFile.writeAsBytes(orderBytes);

    await Share.shareXFiles(
      [XFile(quoteFile.path), XFile(orderFile.path)],
      text:
          'مرفق ملفي PDF للعميل (${client.clientName}):\n1. كشف عرض السعر\n2. كشف الطلبية والتخصيم وتقطيع الزجاج والأعواد',
    );
  }

  /// معاينة وطباعة أي ملف PDF مباشرة على الهاتف
  static Future<void> previewPdfBytes(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }
}
