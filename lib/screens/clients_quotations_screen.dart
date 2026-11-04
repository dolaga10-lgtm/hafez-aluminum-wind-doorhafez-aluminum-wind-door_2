import 'dart:io';
import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/pdf_generator_service.dart';
import '../services/workshop_storage.dart';

class ClientsQuotationsScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const ClientsQuotationsScreen({super.key, required this.storage});

  @override
  State<ClientsQuotationsScreen> createState() =>
      _ClientsQuotationsScreenState();
}

class _ClientsQuotationsScreenState extends State<ClientsQuotationsScreen> {
  String _searchQuery = '';

  void _openClientEditor({ClientRecord? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientQuotationEditorPage(
          storage: widget.storage,
          existingClient: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allClients = widget.storage.clients;
    final filtered = _searchQuery.trim().isEmpty
        ? allClients
        : allClients
            .where((c) =>
                c.clientName.contains(_searchQuery) ||
                c.clientPhone.contains(_searchQuery))
            .toList();

    final bool minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث في سجل العملاء بالاسم أو رقم الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF991B1B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onPressed: () => _openClientEditor(),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text(
                    'عميل / مقايسة جديدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_shared_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'لا يوجد عملاء محفوظون في السجل حتى الآن',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اضغط على "عميل / مقايسة جديدة" لرفع المقاسات وإصدار ملفي PDF (عرض السعر + كشف الطلبية)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _openClientEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('بدء رفع مقاسات عميل جديد'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final client = filtered[idx];
                      double totalPrice = 0.0;
                      for (final item in client.items) {
                        final sec =
                            widget.storage.getSectorById(item.sectorId);
                        totalPrice += item.calculateTotalCost(sec,
                            minOneM2: minOneM2);
                      }
                      final netPrice = (totalPrice - client.discountAmount)
                          .clamp(0.0, double.infinity);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'العميل: ${client.clientName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF991B1B)),
                                    ),
                                    child: Text(
                                      'الصافي: ${netPrice.toStringAsFixed(1)} ج.م',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF991B1B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'التاريخ: ${client.createdAt} • عدد البنود: ${client.items.length} شباك/باب ${client.clientPhone.isNotEmpty ? "• هاتف: ${client.clientPhone}" : ""}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                              const Divider(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D4ED8),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _openClientEditor(existing: client),
                                    icon: const Icon(Icons.edit_note, size: 18),
                                    label: const Text('فتح وتعديل المقايسة'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      final bytes = await PdfGeneratorService
                                          .buildQuotationPdfBytes(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                      await PdfGeneratorService.previewPdfBytes(
                                          bytes,
                                          'عرض_سعر_${client.clientName}.pdf');
                                    },
                                    icon: const Icon(Icons.picture_as_pdf,
                                        size: 17, color: Color(0xFF991B1B)),
                                    label: const Text('PDF (1) عرض السعر'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      final bytes = await PdfGeneratorService
                                          .buildOrderAndCuttingPdfBytes(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                      await PdfGeneratorService.previewPdfBytes(
                                          bytes,
                                          'كشف_طلبية_${client.clientName}.pdf');
                                    },
                                    icon: const Icon(Icons.fact_check_outlined,
                                        size: 17, color: Color(0xFF15803D)),
                                    label: const Text('PDF (2) كشف الطلبية'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      await PdfGeneratorService
                                          .generateAndShareBothPdfs(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                    },
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('مشاركة الـ 2 PDF معاً'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => widget.storage
                                        .deleteClientRecord(client.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// شاشة رفع مقاسات العميل وإصدار كشف عرض السعر وكشف الطلبية الشامل (2 PDF)
class ClientQuotationEditorPage extends StatefulWidget {
  final WorkshopStorage storage;
  final ClientRecord? existingClient;

  const ClientQuotationEditorPage({
    super.key,
    required this.storage,
    this.existingClient,
  });

  @override
  State<ClientQuotationEditorPage> createState() =>
      _ClientQuotationEditorPageState();
}

class _ClientQuotationEditorPageState extends State<ClientQuotationEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  List<ClientWindowItem> _items = [];
  late String _recordId;
  late String _createdAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final ex = widget.existingClient;
    if (ex != null) {
      _recordId = ex.id;
      _createdAt = ex.createdAt;
      _clientNameCtrl.text = ex.clientName;
      _clientPhoneCtrl.text = ex.clientPhone;
      _clientAddressCtrl.text = ex.clientAddress;
      _discountCtrl.text = ex.discountAmount.toStringAsFixed(0);
      _notesCtrl.text = ex.notes;
      _items = ex.items
          .map((e) => ClientWindowItem.fromJson(e.toJson()))
          .toList();
    } else {
      final now = DateTime.now();
      _recordId = 'client_${now.millisecondsSinceEpoch}';
      _createdAt =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  ClientRecord _buildCurrentRecord() {
    return ClientRecord(
      id: _recordId,
      clientName: _clientNameCtrl.text.trim().isEmpty
          ? 'عميل بدون اسم'
          : _clientNameCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim(),
      createdAt: _createdAt,
      notes: _notesCtrl.text.trim(),
      discountAmount: double.tryParse(_discountCtrl.text.trim()) ?? 0.0,
      items: _items,
    );
  }

  Future<void> _saveClientToHistory() async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم العميل أولاً')),
      );
      return;
    }
    final record = _buildCurrentRecord();
    await widget.storage.saveClientRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('تم حفظ ملف العميل "${record.clientName}" في سجل العملاء')),
    );
  }

  void _showAddOrEditWindowModal({ClientWindowItem? existing, int? editIdx}) {
    final sectors = widget.storage.sectors;
    final glasses = widget.storage.glassTypes;
    if (sectors.isEmpty) return;

    SectorProfile selectedSector = existing != null
        ? (widget.storage.getSectorById(existing.sectorId) ?? sectors.first)
        : sectors.first;

    final labelCtrl =
        TextEditingController(text: existing?.label ?? 'شباك رقم ${_items.length + 1}');
    final widthCtrl = TextEditingController(
        text: existing != null ? existing.widthCm.toString() : '150');
    final heightCtrl = TextEditingController(
        text: existing != null ? existing.heightCm.toString() : '120');
    final qtyCtrl = TextEditingController(
        text: existing != null ? existing.quantity.toString() : '1');

    int sashCount = existing?.sashCount ?? selectedSector.defaultSashCount;
    bool hasGlass = existing?.hasGlass ?? true;
    bool isDoubleGlass = existing?.isDoubleGlass ?? false;

    GlassTypeItem glass1 = glasses.isNotEmpty
        ? glasses.firstWhere((g) => g.id == existing?.glass1Id,
            orElse: () => glasses.first)
        : GlassTypeItem(
            id: 'g1', name: 'زجاج شفاف 6 مم', pricePerSquareMeter: 450);

    GlassTypeItem glass2 = glasses.length > 1
        ? glasses.firstWhere((g) => g.id == existing?.glass2Id,
            orElse: () => glasses[1])
        : glass1;

    bool hasGeorgian = existing?.hasGeorgianBars ?? false;
    final georgianMetersCtrl = TextEditingController(
        text: existing != null
            ? existing.georgianMetersPerWindow.toString()
            : '3.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(existing == null
              ? 'إضافة شباك / باب لمقايسة العميل'
              : 'تعديل بيانات الشباك'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'وصف البند / المكان (مثلاً: شباك غرفة، بلكونة)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // اختيار القطاع مع عرض صورته وسعر المتر
                DropdownButtonFormField<String>(
                  value: selectedSector.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'اختر القطاع (شامل القطاعات المخصصة)',
                    border: OutlineInputBorder(),
                  ),
                  items: sectors
                      .map((s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Row(
                              children: [
                                if (s.imagePath != null &&
                                    s.imagePath!.isNotEmpty &&
                                    File(s.imagePath!).existsSync())
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Image.file(
                                      File(s.imagePath!),
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    '${s.name} (${s.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final found = widget.storage.getSectorById(val);
                      if (found != null) {
                        setModalState(() {
                          selectedSector = found;
                          sashCount = found.defaultSashCount;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'العرض (سم)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الارتفاع (سم)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'العدد (كم شباك بنفس المقاس)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: sashCount,
                        decoration: const InputDecoration(
                          labelText: 'عدد الضلف',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 ضلفة')),
                          DropdownMenuItem(value: 2, child: Text('2 ضلفة')),
                          DropdownMenuItem(value: 3, child: Text('3 ضلفة')),
                          DropdownMenuItem(value: 4, child: Text('4 ضلفة')),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => sashCount = v);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),

                // إعدادات الزجاج (سنجل أو دبل = فردتين + سبيسر)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'إضافة زجاج للشباك',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: hasGlass,
                  onChanged: (v) => setModalState(() => hasGlass = v),
                ),
                if (hasGlass) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('زجاج سنجل (فردة واحدة)'),
                        icon: Icon(Icons.crop_square),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('زجاج دبل (فردتين + سبيسر)'),
                        icon: Icon(Icons.layers),
                      ),
                    ],
                    selected: {isDoubleGlass},
                    onSelectionChanged: (s) =>
                        setModalState(() => isDoubleGlass = s.first),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: glass1.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isDoubleGlass
                          ? 'اختر فردة الزجاج الأولى'
                          : 'اختر نوع الزجاج',
                      border: const OutlineInputBorder(),
                    ),
                    items: glasses
                        .map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(
                                  '${g.name} (${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          glass1 = glasses.firstWhere((e) => e.id == v);
                        });
                      }
                    },
                  ),
                  if (isDoubleGlass) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: glass2.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'اختر فردة الزجاج الثانية (في الدبل)',
                        border: OutlineInputBorder(),
                      ),
                      items: glasses
                          .map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(
                                    '${g.name} (${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            glass2 = glasses.firstWhere((e) => e.id == v);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '✓ سيتم احتساب: ثمن (${glass1.name}) + ثمن (${glass2.name}) + السبيسر المحيط (${widget.storage.pricingSettings.doubleSpacerPricePerMeter.toStringAsFixed(0)} ج.م/متر طولي).',
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
                const Divider(height: 22),

                // إعدادات الجورجيا
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'إضافة أعواد جورجيا (${widget.storage.pricingSettings.georgianBarPricePerMeter.toStringAsFixed(0)} ج.م/متر)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  value: hasGeorgian,
                  onChanged: (v) => setModalState(() => hasGeorgian = v),
                ),
                if (hasGeorgian)
                  TextField(
                    controller: georgianMetersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'إجمالي أمتار الجورجيا في الشباك الواحد (متر)',
                      helperText: 'مثال: 3.5 متر طولي للشباك',
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final w = double.tryParse(widthCtrl.text.trim()) ?? 120.0;
                final h = double.tryParse(heightCtrl.text.trim()) ?? 120.0;
                final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                final geoM =
                    double.tryParse(georgianMetersCtrl.text.trim()) ?? 0.0;

                final newItem = ClientWindowItem(
                  id: existing?.id ??
                      'win_${DateTime.now().millisecondsSinceEpoch}',
                  label: labelCtrl.text.trim().isEmpty
                      ? 'شباك'
                      : labelCtrl.text.trim(),
                  sectorId: selectedSector.id,
                  sectorName: selectedSector.name,
                  sectorPricePerM2: selectedSector.pricePerSquareMeter,
                  widthCm: w,
                  heightCm: h,
                  quantity: q > 0 ? q : 1,
                  sashCount: sashCount,
                  hasGlass: hasGlass,
                  isDoubleGlass: isDoubleGlass,
                  glass1Id: glass1.id,
                  glass1Name: glass1.name,
                  glass1PricePerM2: glass1.pricePerSquareMeter,
                  glass2Id: glass2.id,
                  glass2Name: glass2.name,
                  glass2PricePerM2: glass2.pricePerSquareMeter,
                  spacerPricePerMeter:
                      widget.storage.pricingSettings.doubleSpacerPricePerMeter,
                  hasGeorgianBars: hasGeorgian,
                  georgianMetersPerWindow: hasGeorgian ? geoM : 0.0,
                  georgianPricePerMeter:
                      widget.storage.pricingSettings.georgianBarPricePerMeter,
                );

                setState(() {
                  if (editIdx != null) {
                    _items[editIdx] = newItem;
                  } else {
                    _items.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('إضافة وحفظ البند'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalSectorsCost = 0.0;
    double totalGlassCost = 0.0;
    double totalGeoCost = 0.0;
    for (final item in _items) {
      final sec = widget.storage.getSectorById(item.sectorId);
      totalSectorsCost += item.calculateSectorCost(minOneM2: minOneM2);
      totalGlassCost +=
          item.calculateGlassAndSpacerCost(sec, minOneM2: minOneM2);
      totalGeoCost += item.calculateGeorgianCost();
    }
    final double discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final double grandNet =
        (totalSectorsCost + totalGlassCost + totalGeoCost - discount)
            .clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع مقاسات العميل وإصدار الـ 2 PDF'),
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveClientToHistory,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'حفظ بالسجل',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(
              icon: Icon(Icons.request_quote),
              text: '1. كشف عرض السعر للعميل',
            ),
            Tab(
              icon: Icon(Icons.carpenter),
              text: '2. كشف الطلبية والتخصيم والزجاج',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // بيانات العميل الأساسية
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _clientNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم العميل',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _clientPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'الخصم (ج.م)',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showAddOrEditWindowModal(),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text(
                      '+ إضافة شباك / باب بالمقاس والقطاع والزجاج',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوى التبويبين (عرض السعر / كشف الطلبية)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // التبويب الأول: كشف عرض السعر
                _buildQuotationTab(minOneM2, totalSectorsCost, totalGlassCost,
                    totalGeoCost, grandNet),
                // التبويب الثاني: كشف الطلبية الشامل والتخصيم والزجاج
                _buildOrderAndCuttingTab(),
              ],
            ),
          ),

          // شريط أزرار تصدير الـ 2 ملف PDF في الأسفل
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        final bytes =
                            await PdfGeneratorService.buildQuotationPdfBytes(
                          client: rec,
                          storage: widget.storage,
                        );
                        await PdfGeneratorService.previewPdfBytes(
                            bytes, 'عرض_سعر_${rec.clientName}.pdf');
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 17),
                      label: const Text('PDF عرض السعر',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        final bytes = await PdfGeneratorService
                            .buildOrderAndCuttingPdfBytes(
                          client: rec,
                          storage: widget.storage,
                        );
                        await PdfGeneratorService.previewPdfBytes(
                            bytes, 'كشف_طلبية_${rec.clientName}.pdf');
                      },
                      icon: const Icon(Icons.list_alt, size: 17),
                      label: const Text('PDF كشف الطلبية',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        await PdfGeneratorService.generateAndShareBothPdfs(
                          client: rec,
                          storage: widget.storage,
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('إصدار الـ 2 PDF',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationTab(
    bool minOneM2,
    double totalSectorsCost,
    double totalGlassCost,
    double totalGeoCost,
    double grandNet,
  ) {
    if (_items.isEmpty) {
      return const Center(
        child: Text('أضف شبابيك أو أبواب لعرض كشف التسعير الفوري هنا'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...List.generate(_items.length, (idx) {
          final item = _items[idx];
          final sec = widget.storage.getSectorById(item.sectorId);
          final secCost = item.calculateSectorCost(minOneM2: minOneM2);
          final glCost =
              item.calculateGlassAndSpacerCost(sec, minOneM2: minOneM2);
          final geoCost = item.calculateGeorgianCost();
          final total = secCost + glCost + geoCost;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                '${idx + 1}. ${item.label} — ${item.sectorName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'المقاس: ${item.widthCm} × ${item.heightCm} سم • العدد: ${item.quantity} (${item.sashCount} ضلفة) • المساحة: ${item.totalAreaM2(minOneM2: minOneM2).toStringAsFixed(2)} م²'),
                  Text('الزجاج: ${item.glassSummaryText}'),
                  Text(
                    'تفصيل السعر: قطاع (${secCost.toStringAsFixed(0)}) + زجاج/سبيسر (${glCost.toStringAsFixed(0)}) + جورجيا (${geoCost.toStringAsFixed(0)}) = ${total.toStringAsFixed(1)} ج.م',
                    style: const TextStyle(
                        color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
                    onPressed: () =>
                        _showAddOrEditWindowModal(existing: item, editIdx: idx),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _items.removeAt(idx)),
                  ),
                ],
              ),
            ),
          );
        }),
        Card(
          color: const Color(0xFFFEF2F2),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'إجمالي القطاعات: ${totalSectorsCost.toStringAsFixed(1)} ج.م'),
                Text(
                    'إجمالي الزجاج والسبيسر: ${totalGlassCost.toStringAsFixed(1)} ج.م'),
                Text('إجمالي الجورجيا: ${totalGeoCost.toStringAsFixed(1)} ج.م'),
                const Divider(),
                Text(
                  'الصافي النهائي لعرض السعر: ${grandNet.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderAndCuttingTab() {
    if (_items.isEmpty) {
      return const Center(
        child: Text('أضف شبابيك لعرض كشف الطلبية والتخصيم وتقطيع الزجاج هنا'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _items.map((item) {
        final sec = widget.storage.getSectorById(item.sectorId);
        final double gw = sec != null
            ? sec.calculateGlassWidthCm(item.widthCm, item.sashCount)
            : (item.widthCm / item.sashCount) - 10.0;
        final double gh = sec != null
            ? sec.calculateGlassHeightCm(item.heightCm, item.sashCount)
            : item.heightCm - 18.0;
        final int panesCount = item.sashCount * item.quantity;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.label} (${item.widthCm}×${item.heightCm} سم — العدد: ${item.quantity}) — ${item.sectorName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF15803D)),
                ),
                const Divider(),
                if (sec != null)
                  ...sec.parts.map((p) {
                    final len = p.calculatePieceLength(
                        item.widthCm, item.heightCm, item.sashCount);
                    final cnt =
                        p.calculateTotalCount(item.quantity, item.sashCount);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${p.name} (${p.role}):'),
                          Text(
                            'المقاس: ${len.toStringAsFixed(1)} سم  |  العدد: $cnt قطعة',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                if (item.hasGlass) ...[
                  const Divider(),
                  Text(
                    item.isDoubleGlass
                        ? '• مقاس الزجاج الدبل الصافي: ${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم — العدد: $panesCount فردة (${item.glass1Name}) + $panesCount فردة (${item.glass2Name}) + سبيسر: ${item.totalSpacerMeters(sec).toStringAsFixed(2)} متر'
                        : '• مقاس الزجاج السنجل الصافي: ${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم — العدد: $panesCount فردة (${item.glass1Name})',
                    style: const TextStyle(
                        color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                  ),
                ],
                if (item.hasGeorgianBars)
                  Text(
                    '• إجمالي الجورجيا المطلوبة: ${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(2)} متر طولي',
                    style: const TextStyle(
                        color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
