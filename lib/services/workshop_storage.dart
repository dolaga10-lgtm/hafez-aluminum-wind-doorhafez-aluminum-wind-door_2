import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workshop_models.dart';

class WorkshopStorage extends ChangeNotifier {
  static const String _kSectorsKey = 'sw_sectors_v4';
  static const String _kGlassesKey = 'sw_glasses_v4';
  static const String _kSettingsKey = 'sw_pricing_settings_v4';
  static const String _kClientsKey = 'sw_clients_records_v4';

  List<SectorProfile> sectors = [];
  List<GlassTypeItem> glassTypes = [];
  PricingSettings pricingSettings = PricingSettings();
  List<ClientRecord> clients = [];
  bool isLoaded = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. تحميل القطاعات
    final String? sectorsRaw = prefs.getString(_kSectorsKey);
    if (sectorsRaw != null && sectorsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(sectorsRaw);
        sectors = list
            .map((e) => SectorProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        sectors = _defaultSectors();
      }
    } else {
      sectors = _defaultSectors();
    }

    // 2. تحميل أنواع الزجاج
    final String? glassesRaw = prefs.getString(_kGlassesKey);
    if (glassesRaw != null && glassesRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(glassesRaw);
        glassTypes = list
            .map((e) => GlassTypeItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        glassTypes = _defaultGlassTypes();
      }
    } else {
      glassTypes = _defaultGlassTypes();
    }

    // 3. تحميل إعدادات التسعير الخارجية
    final String? settingsRaw = prefs.getString(_kSettingsKey);
    if (settingsRaw != null && settingsRaw.isNotEmpty) {
      try {
        pricingSettings = PricingSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(settingsRaw)));
      } catch (_) {
        pricingSettings = PricingSettings();
      }
    }

    // 4. تحميل سجل العملاء
    final String? clientsRaw = prefs.getString(_kClientsKey);
    if (clientsRaw != null && clientsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(clientsRaw);
        clients = list
            .map((e) => ClientRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        clients = [];
      }
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kSectorsKey, jsonEncode(sectors.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kGlassesKey, jsonEncode(glassTypes.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettingsKey, jsonEncode(pricingSettings.toJson()));
    await prefs.setString(
        _kClientsKey, jsonEncode(clients.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  SectorProfile? getSectorById(String id) {
    for (final s in sectors) {
      if (s.id == id) return s;
    }
    return sectors.isNotEmpty ? sectors.first : null;
  }

  // إدارة القطاعات (إضافة / تعديل / حذف)
  Future<void> addOrUpdateSector(SectorProfile sector) async {
    final idx = sectors.indexWhere((e) => e.id == sector.id);
    if (idx >= 0) {
      sectors[idx] = sector;
    } else {
      sectors.add(sector);
    }
    await _saveAll();
  }

  Future<void> deleteSector(String id) async {
    sectors.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updateSectorPrice(String sectorId, double newPrice) async {
    final idx = sectors.indexWhere((e) => e.id == sectorId);
    if (idx >= 0) {
      sectors[idx].pricePerSquareMeter = newPrice;
      await _saveAll();
    }
  }

  // إدارة أنواع الزجاج والتسعير الخارجي
  Future<void> addOrUpdateGlassType(GlassTypeItem item) async {
    final idx = glassTypes.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      glassTypes[idx] = item;
    } else {
      glassTypes.add(item);
    }
    await _saveAll();
  }

  Future<void> deleteGlassType(String id) async {
    glassTypes.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updatePricingSettings(PricingSettings newSettings) async {
    pricingSettings = newSettings;
    await _saveAll();
  }

  // إدارة سجل العملاء (إضافة / تعديل / حذف)
  Future<void> saveClientRecord(ClientRecord record) async {
    final idx = clients.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      clients[idx] = record;
    } else {
      clients.insert(0, record);
    }
    await _saveAll();
  }

  Future<void> deleteClientRecord(String clientId) async {
    clients.removeWhere((e) => e.id == clientId);
    await _saveAll();
  }

  /// خوارزمية تقسيم الأعواد القياسية (1D First-Fit Decreasing)
  static List<BarCutPlan> optimize1DBars({
    required List<double> requiredPiecesCm,
    double stockLengthCm = 600.0,
    double sawKerfMm = 4.0,
  }) {
    final double kerfCm = sawKerfMm / 10.0;
    final List<double> sorted = requiredPiecesCm
        .where((p) => p > 0 && p <= stockLengthCm)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final List<List<double>> bins = [];
    final List<double> binRemaining = [];

    for (final piece in sorted) {
      bool placed = false;
      for (int i = 0; i < bins.length; i++) {
        final double needed = piece + (bins[i].isEmpty ? 0.0 : kerfCm);
        if (binRemaining[i] >= needed - 1e-6) {
          bins[i].add(piece);
          binRemaining[i] = math.max(0.0, binRemaining[i] - needed);
          placed = true;
          break;
        }
      }
      if (!placed) {
        bins.add([piece]);
        binRemaining.add(math.max(0.0, stockLengthCm - piece));
      }
    }

    final List<BarCutPlan> plans = [];
    for (int i = 0; i < bins.length; i++) {
      final double waste = double.parse(binRemaining[i].toStringAsFixed(2));
      final double used =
          double.parse((stockLengthCm - waste).toStringAsFixed(2));
      plans.add(BarCutPlan(
        barNumber: i + 1,
        stockLengthCm: stockLengthCm,
        cutsCm: bins[i],
        usedLengthCm: used,
        wasteLengthCm: waste,
      ));
    }
    return plans;
  }

  List<SectorProfile> _defaultSectors() {
    return [
      SectorProfile(
        id: 'sec_jumbo_100',
        name: 'قطاع جامبو 100 جرار (Jumbo 100)',
        category: 'جرار',
        defaultSashCount: 2,
        pricePerSquareMeter: 2650.0,
        glassWidthDeductCm: 11.4,
        glassHeightDeductCm: 11.4,
        parts: [
          SectorPart(
            id: 'p1',
            name: 'حلق جامبو علوي وسفلي',
            role: 'حلق',
            dimensionBasis: 'width',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'p2',
            name: 'حلق جامبو جنبين',
            role: 'حلق',
            dimensionBasis: 'height',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'p3',
            name: 'رأس وكعب ضلفة جامبو',
            role: 'ضلفة',
            dimensionBasis: 'width_per_sash',
            offsetCm: 1.5,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'p4',
            name: 'قائم ضلفة جامبو',
            role: 'ضلفة',
            dimensionBasis: 'height',
            offsetCm: -8.2,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'p5',
            name: 'سكينة تداخل جامبو',
            role: 'سكينة',
            dimensionBasis: 'height',
            offsetCm: -8.2,
            quantityPerWindow: 2,
            multiplyBySashes: false,
          ),
          SectorPart(
            id: 'p6',
            name: 'ضلفة سلك (عرض)',
            role: 'منخل',
            dimensionBasis: 'width_per_sash',
            offsetCm: 1.5,
            quantityPerWindow: 2,
            multiplyBySashes: false,
          ),
          SectorPart(
            id: 'p7',
            name: 'ضلفة سلك (ارتفاع)',
            role: 'منخل',
            dimensionBasis: 'height',
            offsetCm: -6.5,
            quantityPerWindow: 2,
            multiplyBySashes: false,
          ),
        ],
      ),
      SectorProfile(
        id: 'sec_tango_60',
        name: 'قطاع تانجو 60 جرار (Tango 60)',
        category: 'جرار',
        defaultSashCount: 2,
        pricePerSquareMeter: 2350.0,
        glassWidthDeductCm: 10.2,
        glassHeightDeductCm: 10.2,
        parts: [
          SectorPart(
            id: 't1',
            name: 'حلق تانجو علوي وسفلي',
            role: 'حلق',
            dimensionBasis: 'width',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 't2',
            name: 'حلق تانجو جنبين',
            role: 'حلق',
            dimensionBasis: 'height',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 't3',
            name: 'رأس وكعب ضلفة تانجو',
            role: 'ضلفة',
            dimensionBasis: 'width_per_sash',
            offsetCm: 1.2,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 't4',
            name: 'قائم ضلفة تانجو',
            role: 'ضلفة',
            dimensionBasis: 'height',
            offsetCm: -7.5,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 't5',
            name: 'سكينة تانجو',
            role: 'سكينة',
            dimensionBasis: 'height',
            offsetCm: -7.5,
            quantityPerWindow: 2,
          ),
        ],
      ),
      SectorProfile(
        id: 'sec_ps_9600',
        name: 'قطاع PS 9600 جرار كبير',
        category: 'جرار',
        defaultSashCount: 2,
        pricePerSquareMeter: 2250.0,
        glassWidthDeductCm: 10.6,
        glassHeightDeductCm: 10.6,
        parts: [
          SectorPart(
            id: 'ps1',
            name: 'حلق PS كبير (عرض)',
            role: 'حلق',
            dimensionBasis: 'width',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'ps2',
            name: 'حلق PS كبير (ارتفاع)',
            role: 'حلق',
            dimensionBasis: 'height',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'ps3',
            name: 'عرض ضلفة PS كبير',
            role: 'ضلفة',
            dimensionBasis: 'width_per_sash',
            offsetCm: -0.5,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'ps4',
            name: 'ارتفاع ضلفة PS كبير',
            role: 'ضلفة',
            dimensionBasis: 'height',
            offsetCm: -6.5,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'ps5',
            name: 'سكينة PS كبير',
            role: 'سكينة',
            dimensionBasis: 'height',
            offsetCm: -6.5,
            quantityPerWindow: 2,
          ),
        ],
      ),
      SectorProfile(
        id: 'sec_ps_6600',
        name: 'قطاع PS 6600 جرار صغير',
        category: 'جرار',
        defaultSashCount: 2,
        pricePerSquareMeter: 1950.0,
        glassWidthDeductCm: 8.8,
        glassHeightDeductCm: 8.8,
        parts: [
          SectorPart(
            id: 'pss1',
            name: 'حلق PS صغير (عرض)',
            role: 'حلق',
            dimensionBasis: 'width',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'pss2',
            name: 'حلق PS صغير (ارتفاع)',
            role: 'حلق',
            dimensionBasis: 'height',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'pss3',
            name: 'عرض ضلفة PS صغير',
            role: 'ضلفة',
            dimensionBasis: 'width_per_sash',
            offsetCm: -0.4,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'pss4',
            name: 'ارتفاع ضلفة PS صغير',
            role: 'ضلفة',
            dimensionBasis: 'height',
            offsetCm: -5.8,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'pss5',
            name: 'سكينة PS صغير',
            role: 'سكينة',
            dimensionBasis: 'height',
            offsetCm: -5.8,
            quantityPerWindow: 2,
          ),
        ],
      ),
      SectorProfile(
        id: 'sec_sonata_45',
        name: 'قطاع سوناتا 45 مفصلي (Sonata 45)',
        category: 'مفصلي',
        defaultSashCount: 1,
        pricePerSquareMeter: 2400.0,
        glassWidthDeductCm: 9.5,
        glassHeightDeductCm: 9.5,
        parts: [
          SectorPart(
            id: 'sn1',
            name: 'حلق سوناتا (عرض)',
            role: 'حلق',
            dimensionBasis: 'width',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'sn2',
            name: 'حلق سوناتا (ارتفاع)',
            role: 'حلق',
            dimensionBasis: 'height',
            offsetCm: 0.0,
            quantityPerWindow: 2,
          ),
          SectorPart(
            id: 'sn3',
            name: 'ضلفة سوناتا (عرض)',
            role: 'ضلفة',
            dimensionBasis: 'width_per_sash',
            offsetCm: -4.8,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'sn4',
            name: 'ضلفة سوناتا (ارتفاع)',
            role: 'ضلفة',
            dimensionBasis: 'height',
            offsetCm: -4.8,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'sn5',
            name: 'باكتة زجاج سوناتا (عرض)',
            role: 'إضافي',
            dimensionBasis: 'width_per_sash',
            offsetCm: -14.0,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
          SectorPart(
            id: 'sn6',
            name: 'باكتة زجاج سوناتا (ارتفاع)',
            role: 'إضافي',
            dimensionBasis: 'height',
            offsetCm: -14.0,
            quantityPerWindow: 2,
            multiplyBySashes: true,
          ),
        ],
      ),
    ];
  }

  List<GlassTypeItem> _defaultGlassTypes() {
    return [
      GlassTypeItem(
        id: 'g_clear_6',
        name: 'زجاج شفاف 6 مم',
        pricePerSquareMeter: 450.0,
      ),
      GlassTypeItem(
        id: 'g_reflective_6',
        name: 'زجاج عاكس (أزرق / بني / عسلي) 6 مم',
        pricePerSquareMeter: 600.0,
      ),
      GlassTypeItem(
        id: 'g_frosted_6',
        name: 'زجاج مصنفر / كريستال 6 مم',
        pricePerSquareMeter: 520.0,
      ),
      GlassTypeItem(
        id: 'g_tempered_10',
        name: 'زجاج سيكوريت 10 مم',
        pricePerSquareMeter: 1150.0,
      ),
      GlassTypeItem(
        id: 'g_clear_4',
        name: 'زجاج شفاف 4 مم',
        pricePerSquareMeter: 340.0,
      ),
    ];
  }
}
