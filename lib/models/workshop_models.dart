import 'dart:convert';
import 'dart:math' as math;

/// يمثل جزءاً داخل القطاع (سكينة، حلق، ضلفة، مكمل، تقابل، باكتة، محبس، أو أي مسمى مخصص)
class SectorPart {
  String id;
  String name; // اسم الجزء الحر (سكينة، حلق، ضلفة، مكمل، تقابل، باكتة، محبس...)
  String role; // تصنيف الجزء: حلق | ضلفة | سكينة | مكمل | تقابل | باكتة | محبس | إضافي
  String dimensionBasis; // width | height | width_per_sash | height_per_sash | fixed
  double offsetCm; // قيمة التخصيم أو الإضافة بالسنتيمتر (سالب للخصم، موجب للإضافة)
  int quantityPerWindow; // كم قطعة تضاف للشباك/الباب
  bool multiplyBySashes; // هل يُضرب العدد في عدد الضلف؟

  SectorPart({
    required this.id,
    required this.name,
    required this.role,
    required this.dimensionBasis,
    required this.offsetCm,
    required this.quantityPerWindow,
    this.multiplyBySashes = false,
  });

  /// حساب طول القطعة الواحدة بالسنتيمتر بناءً على أبعاد الشباك/الباب وعدد الضلف
  double calculatePieceLength(double widthCm, double heightCm, int sashCount) {
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    double baseVal = 0.0;
    switch (dimensionBasis) {
      case 'width':
        baseVal = widthCm;
        break;
      case 'height':
        baseVal = heightCm;
        break;
      case 'width_per_sash':
        baseVal = widthCm / safeSashes;
        break;
      case 'height_per_sash':
        baseVal = heightCm / safeSashes;
        break;
      case 'fixed':
        baseVal = 0.0;
        break;
      default:
        baseVal = widthCm;
    }
    final double result = baseVal + offsetCm;
    return result > 0 ? double.parse(result.toStringAsFixed(2)) : 0.0;
  }

  /// حساب إجمالي عدد القطع لهذا الجزء
  int calculateTotalCount(int windowQuantity, int sashCount) {
    final int safeWindows = windowQuantity > 0 ? windowQuantity : 1;
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    final int perWindow = multiplyBySashes
        ? (quantityPerWindow * safeSashes)
        : quantityPerWindow;
    return perWindow * safeWindows;
  }

  String get basisArabicLabel {
    switch (dimensionBasis) {
      case 'width':
        return 'العرض الكلي (W)';
      case 'height':
        return 'الارتفاع الكلي (H)';
      case 'width_per_sash':
        return 'العرض ÷ عدد الضلف';
      case 'height_per_sash':
        return 'الارتفاع ÷ عدد الضلف';
      case 'fixed':
        return 'طول ثابت (سم)';
      default:
        return 'العرض الكلي (W)';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'dimensionBasis': dimensionBasis,
        'offsetCm': offsetCm,
        'quantityPerWindow': quantityPerWindow,
        'multiplyBySashes': multiplyBySashes,
      };

  factory SectorPart.fromJson(Map<String, dynamic> json) => SectorPart(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? 'جزء مخصص',
        dimensionBasis: json['dimensionBasis']?.toString() ?? 'width',
        offsetCm: (json['offsetCm'] as num?)?.toDouble() ?? 0.0,
        quantityPerWindow: (json['quantityPerWindow'] as num?)?.toInt() ?? 1,
        multiplyBySashes: json['multiplyBySashes'] == true,
      );
}

/// يمثل قطاع ألومنيوم أو uPVC أو باب أو شباك أو مطبخ
class SectorProfile {
  String id;
  String name;
  String companyGroup; // الشارقة | السعد PS | الدولية ماكسيم | ألوميل | فولكانو | فالف | uPVC | مطابخ | مخصص
  String systemType; // شباك جرار | باب جرار | شباك مفصلي | باب مفصلي | قلاب | مطبخ | مخصص
  int defaultSashCount;
  String? imagePath; // مسار صورة القطاع المرفوعة
  double pricePerSquareMeter; // سعر المتر المربع في التسعير الخارجي
  double glassWidthDeductCm; // خصم عرض الزجاج من عرض الضلفة (سم)
  double glassHeightDeductCm; // خصم ارتفاع الزجاج من ارتفاع الضلفة (سم)
  bool isCustom;
  List<SectorPart> parts;

  SectorProfile({
    required this.id,
    required this.name,
    required this.companyGroup,
    required this.systemType,
    this.defaultSashCount = 2,
    this.imagePath,
    required this.pricePerSquareMeter,
    this.glassWidthDeductCm = 11.4,
    this.glassHeightDeductCm = 11.4,
    this.isCustom = false,
    required this.parts,
  });

  bool get isDoor => systemType.contains('باب');
  bool get isSliding => systemType.contains('جرار');
  bool get isHinged => systemType.contains('مفصلي') || systemType.contains('قلاب');

  double calculateSingleSashWidth(double widthCm, int sashCount) {
    for (final p in parts) {
      if (p.role == 'ضلفة' &&
          (p.dimensionBasis == 'width_per_sash' || p.dimensionBasis == 'width')) {
        return p.calculatePieceLength(widthCm, 0, sashCount);
      }
    }
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    return (widthCm / safeSashes) + (isSliding ? 1.5 : -4.8);
  }

  double calculateSingleSashHeight(double heightCm, int sashCount) {
    for (final p in parts) {
      if (p.role == 'ضلفة' && p.dimensionBasis == 'height') {
        return p.calculatePieceLength(0, heightCm, sashCount);
      }
    }
    return math.max(0.0, heightCm - (isSliding ? 8.2 : 4.8));
  }

  double calculateGlassWidthCm(double widthCm, int sashCount) {
    final double sashW = calculateSingleSashWidth(widthCm, sashCount);
    return math.max(0.0, double.parse((sashW - glassWidthDeductCm).toStringAsFixed(2)));
  }

  double calculateGlassHeightCm(double heightCm, int sashCount) {
    final double sashH = calculateSingleSashHeight(heightCm, sashCount);
    return math.max(0.0, double.parse((sashH - glassHeightDeductCm).toStringAsFixed(2)));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'companyGroup': companyGroup,
        'systemType': systemType,
        'defaultSashCount': defaultSashCount,
        'imagePath': imagePath,
        'pricePerSquareMeter': pricePerSquareMeter,
        'glassWidthDeductCm': glassWidthDeductCm,
        'glassHeightDeductCm': glassHeightDeductCm,
        'isCustom': isCustom,
        'parts': parts.map((e) => e.toJson()).toList(),
      };

  factory SectorProfile.fromJson(Map<String, dynamic> json) => SectorProfile(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        companyGroup: json['companyGroup']?.toString() ?? 'مخصص',
        systemType: json['systemType']?.toString() ?? 'شباك جرار',
        defaultSashCount: (json['defaultSashCount'] as num?)?.toInt() ?? 2,
        imagePath: json['imagePath']?.toString(),
        pricePerSquareMeter:
            (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 2200.0,
        glassWidthDeductCm:
            (json['glassWidthDeductCm'] as num?)?.toDouble() ?? 11.4,
        glassHeightDeductCm:
            (json['glassHeightDeductCm'] as num?)?.toDouble() ?? 11.4,
        isCustom: json['isCustom'] == true,
        parts: (json['parts'] as List<dynamic>? ?? [])
            .map((e) => SectorPart.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// يمثل نوع زجاج في قائمة التسعير
class GlassTypeItem {
  String id;
  String name;
  double pricePerSquareMeter;

  GlassTypeItem({
    required this.id,
    required this.name,
    required this.pricePerSquareMeter,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pricePerSquareMeter': pricePerSquareMeter,
      };

  factory GlassTypeItem.fromJson(Map<String, dynamic> json) => GlassTypeItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        pricePerSquareMeter:
            (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 450.0,
      );
}

/// إعدادات التسعير وطبعة شركة الحافظ
class PricingSettings {
  double doubleSpacerPricePerMeter;
  double georgianBarPricePerMeter;
  double defaultStockBarLengthCm;
  double defaultSawKerfMm;
  bool enforceMinimumOneSquareMeter;

  String companyName;
  String companySubtitle;
  String companyPhones;
  String companyAddress;
  String termsAndConditions;

  PricingSettings({
    this.doubleSpacerPricePerMeter = 45.0,
    this.georgianBarPricePerMeter = 85.0,
    this.defaultStockBarLengthCm = 600.0,
    this.defaultSawKerfMm = 4.0,
    this.enforceMinimumOneSquareMeter = false,
    this.companyName = 'شركة الحافظ',
    this.companySubtitle =
        'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية (خبرة منذ 1980)',
    this.companyPhones = '01000000000 - 01200000000',
    this.companyAddress = 'جمهورية مصر العربية',
    this.termsAndConditions =
        'الأسعار شاملة التوريد والتركيب والضمان المعتمد من شركة الحافظ.',
  });

  Map<String, dynamic> toJson() => {
        'doubleSpacerPricePerMeter': doubleSpacerPricePerMeter,
        'georgianBarPricePerMeter': georgianBarPricePerMeter,
        'defaultStockBarLengthCm': defaultStockBarLengthCm,
        'defaultSawKerfMm': defaultSawKerfMm,
        'enforceMinimumOneSquareMeter': enforceMinimumOneSquareMeter,
        'companyName': companyName,
        'companySubtitle': companySubtitle,
        'companyPhones': companyPhones,
        'companyAddress': companyAddress,
        'termsAndConditions': termsAndConditions,
      };

  factory PricingSettings.fromJson(Map<String, dynamic> json) => PricingSettings(
        doubleSpacerPricePerMeter:
            (json['doubleSpacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        georgianBarPricePerMeter:
            (json['georgianBarPricePerMeter'] as num?)?.toDouble() ?? 85.0,
        defaultStockBarLengthCm:
            (json['defaultStockBarLengthCm'] as num?)?.toDouble() ?? 600.0,
        defaultSawKerfMm:
            (json['defaultSawKerfMm'] as num?)?.toDouble() ?? 4.0,
        enforceMinimumOneSquareMeter:
            json['enforceMinimumOneSquareMeter'] == true,
        companyName: json['companyName']?.toString() ?? 'شركة الحافظ',
        companySubtitle: json['companySubtitle']?.toString() ??
            'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية (خبرة منذ 1980)',
        companyPhones: json['companyPhones']?.toString() ?? '01000000000',
        companyAddress: json['companyAddress']?.toString() ?? 'مصر',
        termsAndConditions: json['termsAndConditions']?.toString() ?? '',
      );
}

/// بند شباك / باب / مطبخ داخل مقايسة العميل شامل البار واتجاه الفتح والمعاينة الهندسية
class ClientWindowItem {
  String id;
  String label; // وصف الفتحة (شباك صالة، باب بلكونة، باب مطبخ، إلخ)
  String unitType; // شباك | باب | مطبخ
  String openType; // جرار | مفصلي | قلاب | ثابت
  String barType; // بار عادي | بار مقلوب | بدون بار
  String openDirection; // يمين للداخل | شمال للداخل | يمين للخارج | شمال للخارج
  String sectorId;
  String sectorName;
  double sectorPricePerM2;
  double widthCm;
  double heightCm;
  int quantity;
  int sashCount;

  // إعدادات الزجاج
  bool hasGlass;
  bool isDoubleGlass; // يجمع الفردتين + السبيسر
  String? glass1Id;
  String glass1Name;
  double glass1PricePerM2;
  String? glass2Id;
  String glass2Name;
  double glass2PricePerM2;
  double spacerPricePerMeter;

  // إعدادات الجورجيا
  bool hasGeorgianBars;
  double georgianMetersPerWindow;
  double georgianPricePerMeter;

  ClientWindowItem({
    required this.id,
    required this.label,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.barType = 'بار عادي',
    this.openDirection = 'يمين للداخل',
    required this.sectorId,
    required this.sectorName,
    required this.sectorPricePerM2,
    required this.widthCm,
    required this.heightCm,
    this.quantity = 1,
    this.sashCount = 2,
    this.hasGlass = true,
    this.isDoubleGlass = false,
    this.glass1Id,
    this.glass1Name = 'زجاج شفاف 6 مم',
    this.glass1PricePerM2 = 450.0,
    this.glass2Id,
    this.glass2Name = 'زجاج عاكس 6 مم',
    this.glass2PricePerM2 = 550.0,
    this.spacerPricePerMeter = 45.0,
    this.hasGeorgianBars = false,
    this.georgianMetersPerWindow = 0.0,
    this.georgianPricePerMeter = 85.0,
  });

  /// مساحة الفتحة بالمتر المربع
  double singleWindowAreaM2({bool minOneM2 = false}) {
    final double rawArea = (widthCm / 100.0) * (heightCm / 100.0);
    if (minOneM2 && rawArea < 1.0) {
      return 1.0;
    }
    return rawArea;
  }

  double totalAreaM2({bool minOneM2 = false}) =>
      singleWindowAreaM2(minOneM2: minOneM2) * quantity;

  double totalSpacerMeters(SectorProfile? sector) {
    if (!hasGlass || !isDoubleGlass) return 0.0;
    final double gwCm = sector != null
        ? sector.calculateGlassWidthCm(widthCm, sashCount)
        : math.max(0.0, (widthCm / (sashCount > 0 ? sashCount : 1)) - 10.0);
    final double ghCm = sector != null
        ? sector.calculateGlassHeightCm(heightCm, sashCount)
        : math.max(0.0, heightCm - 18.0);
    final double singleSashPerimeterM = 2.0 * ((gwCm + ghCm) / 100.0);
    return singleSashPerimeterM * (sashCount > 0 ? sashCount : 1) * quantity;
  }

  double calculateSectorCost({bool minOneM2 = false}) =>
      totalAreaM2(minOneM2: minOneM2) * sectorPricePerM2;

  double calculateGlassAndSpacerCost(SectorProfile? sector, {bool minOneM2 = false}) {
    if (!hasGlass) return 0.0;
    final double area = totalAreaM2(minOneM2: minOneM2);
    if (!isDoubleGlass) {
      return area * glass1PricePerM2;
    } else {
      final double panesCost = area * (glass1PricePerM2 + glass2PricePerM2);
      final double spacerCost = totalSpacerMeters(sector) * spacerPricePerMeter;
      return panesCost + spacerCost;
    }
  }

  double calculateGeorgianCost() {
    if (!hasGeorgianBars || georgianMetersPerWindow <= 0) return 0.0;
    return georgianMetersPerWindow * quantity * georgianPricePerMeter;
  }

  double calculateTotalCost(SectorProfile? sector, {bool minOneM2 = false}) {
    return calculateSectorCost(minOneM2: minOneM2) +
        calculateGlassAndSpacerCost(sector, minOneM2: minOneM2) +
        calculateGeorgianCost();
  }

  String get glassSummaryText {
    if (!hasGlass) return 'بدون زجاج';
    if (!isDoubleGlass) {
      return 'سنجل: $glass1Name';
    }
    return 'دبل: ($glass1Name + $glass2Name + سبيسر)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'unitType': unitType,
        'openType': openType,
        'barType': barType,
        'openDirection': openDirection,
        'sectorId': sectorId,
        'sectorName': sectorName,
        'sectorPricePerM2': sectorPricePerM2,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'quantity': quantity,
        'sashCount': sashCount,
        'hasGlass': hasGlass,
        'isDoubleGlass': isDoubleGlass,
        'glass1Id': glass1Id,
        'glass1Name': glass1Name,
        'glass1PricePerM2': glass1PricePerM2,
        'glass2Id': glass2Id,
        'glass2Name': glass2Name,
        'glass2PricePerM2': glass2PricePerM2,
        'spacerPricePerMeter': spacerPricePerMeter,
        'hasGeorgianBars': hasGeorgianBars,
        'georgianMetersPerWindow': georgianMetersPerWindow,
        'georgianPricePerMeter': georgianPricePerMeter,
      };

  factory ClientWindowItem.fromJson(Map<String, dynamic> json) =>
      ClientWindowItem(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? 'بند',
        unitType: json['unitType']?.toString() ?? 'شباك',
        openType: json['openType']?.toString() ?? 'جرار',
        barType: json['barType']?.toString() ?? 'بار عادي',
        openDirection: json['openDirection']?.toString() ?? 'يمين للداخل',
        sectorId: json['sectorId']?.toString() ?? '',
        sectorName: json['sectorName']?.toString() ?? '',
        sectorPricePerM2:
            (json['sectorPricePerM2'] as num?)?.toDouble() ?? 2200.0,
        widthCm: (json['widthCm'] as num?)?.toDouble() ?? 120.0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 120.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        sashCount: (json['sashCount'] as num?)?.toInt() ?? 2,
        hasGlass: json['hasGlass'] != false,
        isDoubleGlass: json['isDoubleGlass'] == true,
        glass1Id: json['glass1Id']?.toString(),
        glass1Name: json['glass1Name']?.toString() ?? 'زجاج شفاف 6 مم',
        glass1PricePerM2:
            (json['glass1PricePerM2'] as num?)?.toDouble() ?? 450.0,
        glass2Id: json['glass2Id']?.toString(),
        glass2Name: json['glass2Name']?.toString() ?? 'زجاج عاكس 6 مم',
        glass2PricePerM2:
            (json['glass2PricePerM2'] as num?)?.toDouble() ?? 550.0,
        spacerPricePerMeter:
            (json['spacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        hasGeorgianBars: json['hasGeorgianBars'] == true,
        georgianMetersPerWindow:
            (json['georgianMetersPerWindow'] as num?)?.toDouble() ?? 0.0,
        georgianPricePerMeter:
            (json['georgianPricePerMeter'] as num?)?.toDouble() ?? 85.0,
      );
}

/// سجل العميل الكامل
class ClientRecord {
  String id;
  String clientName;
  String clientPhone;
  String clientAddress;
  String createdAt;
  String notes;
  double discountAmount;
  List<ClientWindowItem> items;

  ClientRecord({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.createdAt,
    this.notes = '',
    this.discountAmount = 0.0,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'createdAt': createdAt,
        'notes': notes,
        'discountAmount': discountAmount,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory ClientRecord.fromJson(Map<String, dynamic> json) => ClientRecord(
        id: json['id']?.toString() ?? '',
        clientName: json['clientName']?.toString() ?? '',
        clientPhone: json['clientPhone']?.toString() ?? '',
        clientAddress: json['clientAddress']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ClientWindowItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class BarCutPlan {
  int barNumber;
  double stockLengthCm;
  List<double> cutsCm;
  double usedLengthCm;
  double wasteLengthCm;

  BarCutPlan({
    required this.barNumber,
    required this.stockLengthCm,
    required this.cutsCm,
    required this.usedLengthCm,
    required this.wasteLengthCm,
  });
}
