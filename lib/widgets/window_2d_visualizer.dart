import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ويدجت رسم هندسي احترافي يحاكي شاشة معاينة تطبيق الورشة الذكية التفاعلية بالكامل
class Window2DVisualizer extends StatelessWidget {
  final double widthCm;
  final double heightCm;
  final String unitType; // شباك | باب
  final String openType; // جرار | مفصلي | قلاب | ثابت
  final int sashCount; // 1, 2, 3, 4
  final String barType; // بار عادي | بار مقلوب | بدون بار
  final String openDirection; // يمين للداخل | شمال للداخل | يمين للخارج | شمال للخارج
  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;
  final double height;

  const Window2DVisualizer({
    super.key,
    required this.widthCm,
    required this.heightCm,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.sashCount = 2,
    this.barType = 'بار عادي',
    this.openDirection = 'يمين للداخل',
    this.hasGlass = true,
    this.isDoubleGlass = false,
    this.hasGeorgian = false,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // خلفية لوحة الرسم الهندسية
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // شبكة رسم هندسية خفيفة في الخلفية (Blueprint Grid)
            CustomPaint(
              size: Size.infinite,
              painter: BlueprintGridPainter(),
            ),

            // الرسم الهندسي للشباك / الباب
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: CustomPaint(
                  size: Size(double.infinity, height - 32),
                  painter: ArchitecturalWindowPainter(
                    widthCm: widthCm <= 0 ? 120 : widthCm,
                    heightCm: heightCm <= 0 ? 120 : heightCm,
                    unitType: unitType,
                    openType: openType,
                    sashCount: sashCount <= 0 ? 2 : sashCount,
                    barType: barType,
                    openDirection: openDirection,
                    hasGlass: hasGlass,
                    isDoubleGlass: isDoubleGlass,
                    hasGeorgian: hasGeorgian,
                  ),
                ),
              ),
            ),

            // شريط المقاسات والبيانات الهندسية فوق الرسم مباشرة
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B110A).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: Text(
                  'المقاس: ${widthCm.toStringAsFixed(1)} × ${heightCm.toStringAsFixed(1)} سم',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // شريط المواصفات المختارة
            Positioned(
              bottom: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$unitType $openType • $sashCount ضلفة • $barType • $openDirection',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسم شبكة خلفية هندسية Blueprint
class BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.4)
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// الرسام الهندسي للأبواب والشبابيك
class ArchitecturalWindowPainter extends CustomPainter {
  final double widthCm;
  final double heightCm;
  final String unitType;
  final String openType;
  final int sashCount;
  final String barType;
  final String openDirection;
  final bool hasGlass;
  final bool isDoubleGlass;
  final bool hasGeorgian;

  ArchitecturalWindowPainter({
    required this.widthCm,
    required this.heightCm,
    required this.unitType,
    required this.openType,
    required this.sashCount,
    required this.barType,
    required this.openDirection,
    required this.hasGlass,
    required this.isDoubleGlass,
    required this.hasGeorgian,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // حساب التناسب القياسي (Aspect Ratio) بحيث يناسب الحاوية بالكامل
    final double aspect = widthCm / (heightCm > 0 ? heightCm : 1);
    double drawW = size.width;
    double drawH = drawW / aspect;

    if (drawH > size.height) {
      drawH = size.height;
      drawW = drawH * aspect;
    }

    final double startX = (size.width - drawW) / 2;
    final double startY = (size.height - drawH) / 2;
    final Rect frameRect = Rect.fromLTWH(startX, startY, drawW, drawH);

    // 1. رسم البار الخارجي إن وجد (بار عادي / بار مقلوب)
    if (barType != 'بدون بار') {
      final double barThick = math.min(10.0, drawW * 0.05);
      final barPaint = Paint()
        ..color = barType == 'بار مقلوب'
            ? const Color(0xFF78350F) // بني كهرماني
            : const Color(0xFF92400E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = barThick;

      canvas.drawRect(
        frameRect.inflate(barThick / 2),
        barPaint,
      );

      // خطوط مائلة رمزية على زوايا البار (متروسة 45 درجة)
      final miterPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 1.0;
      canvas.drawLine(
          frameRect.topLeft, frameRect.topLeft.translate(-barThick, -barThick), miterPaint);
      canvas.drawLine(
          frameRect.topRight, frameRect.topRight.translate(barThick, -barThick), miterPaint);
      canvas.drawLine(
          frameRect.bottomLeft, frameRect.bottomLeft.translate(-barThick, barThick), miterPaint);
      canvas.drawLine(
          frameRect.bottomRight, frameRect.bottomRight.translate(barThick, barThick), miterPaint);
    }

    // 2. رسم الحلق الأساسي (Outer Frame)
    final double frameProfileW = math.min(12.0, drawW * 0.06);
    final outerFramePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    final frameBorderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRect(frameRect, outerFramePaint);
    canvas.drawRect(frameRect, frameBorderPaint);

    final Rect innerFrameRect = frameRect.deflate(frameProfileW);
    final innerFrameClearPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(innerFrameRect, innerFrameClearPaint);

    // 3. تقسيم الضلف (Sashes)
    final int sashes = sashCount > 0 ? sashCount : 1;
    final double sashW = innerFrameRect.width / sashes;
    final double sashH = innerFrameRect.height;

    final sashFillPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final sashStrokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final glassFillPaint = Paint()
      ..color = hasGlass
          ? (isDoubleGlass
              ? const Color(0xFF0284C7).withOpacity(0.45) // أزرق سماوي داكن للدبل
              : const Color(0xFF38BDF8).withOpacity(0.28)) // أزرق شفاف للسنجل
          : Colors.transparent
      ..style = PaintingStyle.fill;

    final georgianPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final bool isHinged = openType == 'مفصلي' || openType == 'قلاب';
    final bool isDoor = unitType == 'باب';

    for (int i = 0; i < sashes; i++) {
      // في الجرار: محاكاة تداخل السكينة (Overlap)
      final double overlap = (openType == 'جرار' && sashes > 1) ? 3.0 : 0.0;
      final double sLeft = innerFrameRect.left + (i * sashW) - (i > 0 ? overlap : 0);
      final double sRight = sLeft + sashW + (i < sashes - 1 ? overlap : 0);
      final Rect sashRect = Rect.fromLTRB(sLeft, innerFrameRect.top, sRight, innerFrameRect.bottom);

      // رسم بروفيل الضلفة
      canvas.drawRect(sashRect, sashFillPaint);
      canvas.drawRect(sashRect, sashStrokePaint);

      // فتحة الزجاج الداخلية داخل الضلفة
      final double sashProfileMargin = math.min(8.0, sashRect.width * 0.12);
      final Rect glassRect = sashRect.deflate(sashProfileMargin);

      if (hasGlass) {
        canvas.drawRect(glassRect, glassFillPaint);
        canvas.drawRect(
          glassRect,
          Paint()
            ..color = isDoubleGlass ? const Color(0xFF0284C7) : const Color(0xFF38BDF8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );

        // خطوط انعكاس الزجاج (Glass Reflection Sheen)
        final sheenPaint = Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..strokeWidth = 1.2;
        canvas.drawLine(
          glassRect.topLeft.translate(6, 6),
          glassRect.topLeft.translate(glassRect.width * 0.45, glassRect.height * 0.45),
          sheenPaint,
        );

        // شبكة الجورجيا إن وجدت داخل الزجاج
        if (hasGeorgian) {
          // خطين أفقيين وخطين رأسيين
          final gY1 = glassRect.top + glassRect.height * 0.33;
          final gY2 = glassRect.top + glassRect.height * 0.66;
          final gX1 = glassRect.left + glassRect.width * 0.33;
          final gX2 = glassRect.left + glassRect.width * 0.66;

          canvas.drawLine(Offset(glassRect.left, gY1), Offset(glassRect.right, gY1), georgianPaint);
          canvas.drawLine(Offset(glassRect.left, gY2), Offset(glassRect.right, gY2), georgianPaint);
          canvas.drawLine(Offset(gX1, glassRect.top), Offset(gX1, glassRect.bottom), georgianPaint);
          canvas.drawLine(Offset(gX2, glassRect.top), Offset(gX2, glassRect.bottom), georgianPaint);
        }
      }

      // 4. رسم رمز طريقة واتجاه الفتح (Opening Direction Indicators)
      if (isHinged) {
        // خطوط منقطة توضح زاوية مفصلات الباب/الشباك
        final hingeDashPaint = Paint()
          ..color = const Color(0xFFEF4444) // أحمر معماري
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final bool openRight = openDirection.contains('يمين');
        final Offset hinge1 = openRight ? sashRect.topRight : sashRect.topLeft;
        final Offset hinge2 = openRight ? sashRect.bottomRight : sashRect.bottomLeft;
        final Offset openPoint = openRight
            ? Offset(sashRect.left, sashRect.center.dy)
            : Offset(sashRect.right, sashRect.center.dy);

        // مثلث اتجاه الفتح المعماري
        final path = Path()
          ..moveTo(hinge1.dx, hinge1.dy)
          ..lineTo(openPoint.dx, openPoint.dy)
          ..lineTo(hinge2.dx, hinge2.dy);
        canvas.drawPath(path, hingeDashPaint);

        // مقبض الباب / الشباك
        final handlePaint = Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.fill;
        final Offset handlePos = openRight
            ? Offset(sashRect.left + 5, sashRect.center.dy + (isDoor ? 10 : 0))
            : Offset(sashRect.right - 5, sashRect.center.dy + (isDoor ? 10 : 0));
        canvas.drawCircle(handlePos, 3.5, handlePaint);
      } else if (openType == 'جرار') {
        // أسهم توضح حركة الضلفة المنزلقة يميناً ويساراً
        final arrowPaint = Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;

        final centerY = sashRect.center.dy;
        final bool slideLeft = (i % 2 == 0);
        final startX = sashRect.center.dx + (slideLeft ? 14 : -14);
        final endX = sashRect.center.dx + (slideLeft ? -14 : 14);

        canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), arrowPaint);
        // رأس السهم
        canvas.drawLine(
          Offset(endX, centerY),
          Offset(endX + (slideLeft ? 4 : -4), centerY - 4),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(endX, centerY),
          Offset(endX + (slideLeft ? 4 : -4), centerY + 4),
          arrowPaint,
        );
      } else if (openType == 'قلاب') {
        // سهم أو مثلث قلاب لأسفل
        final hingeDashPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        final path = Path()
          ..moveTo(sashRect.bottomLeft.dx, sashRect.bottomLeft.dy)
          ..lineTo(sashRect.center.dx, sashRect.top)
          ..lineTo(sashRect.bottomRight.dx, sashRect.bottomRight.dy);
        canvas.drawPath(path, hingeDashPaint);
      }
    }

    // 5. أسهم خطوط الأبعاد المعمارية (Dimension Lines)
    final dimPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.0;

    // خط العرض أسفل الحلق
    final double dimY = frameRect.bottom + 8;
    canvas.drawLine(Offset(frameRect.left, dimY), Offset(frameRect.right, dimY), dimPaint);
    canvas.drawLine(Offset(frameRect.left, dimY - 3), Offset(frameRect.left, dimY + 3), dimPaint);
    canvas.drawLine(Offset(frameRect.right, dimY - 3), Offset(frameRect.right, dimY + 3), dimPaint);

    // خط الارتفاع يسار الحلق
    final double dimX = frameRect.left - 8;
    canvas.drawLine(Offset(dimX, frameRect.top), Offset(dimX, frameRect.bottom), dimPaint);
    canvas.drawLine(Offset(dimX - 3, frameRect.top), Offset(dimX + 3, frameRect.top), dimPaint);
    canvas.drawLine(Offset(dimX - 3, frameRect.bottom), Offset(dimX + 3, frameRect.bottom), dimPaint);
  }

  @override
  bool shouldRepaint(covariant ArchitecturalWindowPainter oldDelegate) {
    return oldDelegate.widthCm != widthCm ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.unitType != unitType ||
        oldDelegate.openType != openType ||
        oldDelegate.sashCount != sashCount ||
        oldDelegate.barType != barType ||
        oldDelegate.openDirection != openDirection ||
        oldDelegate.hasGlass != hasGlass ||
        oldDelegate.isDoubleGlass != isDoubleGlass ||
        oldDelegate.hasGeorgian != hasGeorgian;
  }
}
