import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/workshop_models.dart';
import '../services/workshop_storage.dart';

class SectorsManagerScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const SectorsManagerScreen({super.key, required this.storage});

  @override
  State<SectorsManagerScreen> createState() => _SectorsManagerScreenState();
}

class _SectorsManagerScreenState extends State<SectorsManagerScreen> {
  void _openSectorEditor({SectorProfile? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectorEditorPage(
          storage: widget.storage,
          existingSector: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectors = widget.storage.sectors;
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFFEF2F2),
            child: Row(
              children: [
                const Icon(Icons.design_services, color: Color(0xFF991B1B)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'أضف أي قطاع جديد بالاسم والصورة وحدد أجزاءه (حلق، ضلفة، سكينة، أو أي جزء إضافي) وعدد القطع في الشباك ليظهر في المعاينة وفي قائمة القطاعات.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF7F1D1D)),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _openSectorEditor(),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('إضافة قطاع جديد'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sectors.length,
              itemBuilder: (context, index) {
                final sec = sectors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sec.isCustom
                          ? const Color(0xFF15803D)
                          : Colors.grey.shade300,
                      width: sec.isCustom ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    leading: _buildSectorAvatar(sec),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sec.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (sec.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'قطاع مضاف',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الفئة: ${sec.category} (${sec.defaultSashCount} ضلفة) • سعر المتر: ${sec.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²',
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: sec.parts
                                .map((p) => Chip(
                                      visualDensity: VisualDensity.compact,
                                      labelPadding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      label: Text(
                                        '${p.name} (العدد: ${p.quantityPerWindow}${p.multiplyBySashes ? "×الضلف" : ""})',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل ومعاينة القطاع',
                          icon: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
                          onPressed: () => _openSectorEditor(existing: sec),
                        ),
                        IconButton(
                          tooltip: 'حذف القطاع',
                          icon:
                              const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: Text(
                                    'هل تريد حذف القطاع "${sec.name}" من قائمة القطاعات؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await widget.storage.deleteSector(sec.id);
                            }
                          },
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

  Widget _buildSectorAvatar(SectorProfile sec) {
    if (sec.imagePath != null &&
        sec.imagePath!.isNotEmpty &&
        File(sec.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(sec.imagePath!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Icon(Icons.window, color: Color(0xFF991B1B), size: 30),
    );
  }
}

/// شاشة إضافة / تعديل قطاع كامل مع رفع الصورة وإضافة الأجزاء وشاشة المعاينة الفورية
class SectorEditorPage extends StatefulWidget {
  final WorkshopStorage storage;
  final SectorProfile? existingSector;

  const SectorEditorPage({
    super.key,
    required this.storage,
    this.existingSector,
  });

  @override
  State<SectorEditorPage> createState() => _SectorEditorPageState();
}

class _SectorEditorPageState extends State<SectorEditorPage> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _glassWDeductCtrl = TextEditingController();
  final _glassHDeductCtrl = TextEditingController();

  // حقول المعاينة الفورية
  final _previewWCtrl = TextEditingController(text: '150');
  final _previewHCtrl = TextEditingController(text: '120');
  int _previewSashes = 2;

  String _category = 'جرار';
  int _defaultSashCount = 2;
  String? _imagePath;
  List<SectorPart> _parts = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.existingSector;
    if (ex != null) {
      _nameCtrl.text = ex.name;
      _priceCtrl.text = ex.pricePerSquareMeter.toStringAsFixed(0);
      _glassWDeductCtrl.text = ex.glassWidthDeductCm.toString();
      _glassHDeductCtrl.text = ex.glassHeightDeductCm.toString();
      _category = ex.category;
      _defaultSashCount = ex.defaultSashCount;
      _previewSashes = ex.defaultSashCount;
      _imagePath = ex.imagePath;
      _parts = ex.parts
          .map((p) => SectorPart(
                id: p.id,
                name: p.name,
                role: p.role,
                dimensionBasis: p.dimensionBasis,
                offsetCm: p.offsetCm,
                quantityPerWindow: p.quantityPerWindow,
                multiplyBySashes: p.multiplyBySashes,
              ))
          .toList();
    } else {
      _priceCtrl.text = '2400';
      _glassWDeductCtrl.text = '11.4';
      _glassHDeductCtrl.text = '11.4';
      // أجزاء افتراضية قابلة للتعديل أو الحذف أو الإضافة عليها
      _parts = [
        SectorPart(
          id: 'part_1',
          name: 'حلق (عرض علوي وسفلي)',
          role: 'حلق',
          dimensionBasis: 'width',
          offsetCm: 0.0,
          quantityPerWindow: 2,
        ),
        SectorPart(
          id: 'part_2',
          name: 'حلق (ارتفاع جنبين)',
          role: 'حلق',
          dimensionBasis: 'height',
          offsetCm: 0.0,
          quantityPerWindow: 2,
        ),
        SectorPart(
          id: 'part_3',
          name: 'ضلفة (رأس وكعب عرض)',
          role: 'ضلفة',
          dimensionBasis: 'width_per_sash',
          offsetCm: 1.5,
          quantityPerWindow: 2,
          multiplyBySashes: true,
        ),
        SectorPart(
          id: 'part_4',
          name: 'ضلفة (قائم ارتفاع)',
          role: 'ضلفة',
          dimensionBasis: 'height',
          offsetCm: -8.2,
          quantityPerWindow: 2,
          multiplyBySashes: true,
        ),
        SectorPart(
          id: 'part_5',
          name: 'سكينة',
          role: 'سكينة',
          dimensionBasis: 'height',
          offsetCm: -8.2,
          quantityPerWindow: 2,
          multiplyBySashes: false,
        ),
      ];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked =
          await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار الصورة: $e')),
      );
    }
  }

  void _showPartDialog({SectorPart? existingPart, int? editIndex}) {
    final nameCtrl = TextEditingController(text: existingPart?.name ?? '');
    final offsetCtrl = TextEditingController(
        text: existingPart != null ? existingPart.offsetCm.toString() : '0.0');
    final qtyCtrl = TextEditingController(
        text: existingPart != null
            ? existingPart.quantityPerWindow.toString()
            : '2');
    String role = existingPart?.role ?? 'حلق';
    String basis = existingPart?.dimensionBasis ?? 'width';
    bool multSashes = existingPart?.multiplyBySashes ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingPart == null
              ? 'إضافة جزء جديد للقطاع'
              : 'تعديل بيانات الجزء'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الجزء (مثلاً: حلق، ضلفة، سكينة، محبس، بار)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'تصنيف الجزء',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'حلق', child: Text('حلق (Frame)')),
                    DropdownMenuItem(value: 'ضلفة', child: Text('ضلفة (Sash)')),
                    DropdownMenuItem(
                        value: 'سكينة', child: Text('سكينة (Adapter/Overlap)')),
                    DropdownMenuItem(
                        value: 'منخل', child: Text('ضلفة سلك / منخل')),
                    DropdownMenuItem(
                        value: 'إضافي',
                        child: Text('جزء إضافي مخصص (بار / كاب / محبس)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: basis,
                  decoration: const InputDecoration(
                    labelText: 'يُحسب مقاس هذا الجزء بناءً على:',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'width', child: Text('العرض الكلي للشباك (W)')),
                    DropdownMenuItem(
                        value: 'height',
                        child: Text('الارتفاع الكلي للشباك (H)')),
                    DropdownMenuItem(
                        value: 'width_per_sash',
                        child: Text('العرض مقسوماً على عدد الضلف (W ÷ الضلف)')),
                    DropdownMenuItem(
                        value: 'fixed', child: Text('مقاس ثابت بالسنتيمتر')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => basis = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: offsetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  decoration: const InputDecoration(
                    labelText:
                        'قيمة التخصيم أو الإضافة بالـ سم (مثال: -8.2 أو +1.5 أو 0)',
                    helperText:
                        'ضع علامة سالب (-) للخصم من المقاس، أو موجب (+) للزيادة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الشباك هيتضاف منه كم قطعة؟ (العدد)',
                    helperText: 'مثال: 2 قطعة للحلق أو 2 قطعة للسكينة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'ضرب هذا العدد في عدد الضلف؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'فعّل هذا الخيار إذا كان العدد المذكور يخص الضلفة الواحدة (مثل قوائم الضلف)',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  value: multSashes,
                  onChanged: (v) => setDialogState(() => multSashes = v),
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
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final offset = double.tryParse(offsetCtrl.text.trim()) ?? 0.0;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                final newPart = SectorPart(
                  id: existingPart?.id ??
                      'part_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  role: role,
                  dimensionBasis: basis,
                  offsetCm: offset,
                  quantityPerWindow: qty > 0 ? qty : 1,
                  multiplyBySashes: multSashes,
                );

                setState(() {
                  if (editIndex != null) {
                    _parts[editIndex] = newPart;
                  } else {
                    _parts.add(newPart);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('حفظ الجزء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSector() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم القطاع أولاً')),
      );
      return;
    }
    if (_parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة جزء واحد على الأقل للقطاع')),
      );
      return;
    }

    final sector = SectorProfile(
      id: widget.existingSector?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: _category,
      defaultSashCount: _defaultSashCount,
      imagePath: _imagePath,
      pricePerSquareMeter: double.tryParse(_priceCtrl.text.trim()) ?? 2200.0,
      glassWidthDeductCm:
          double.tryParse(_glassWDeductCtrl.text.trim()) ?? 11.4,
      glassHeightDeductCm:
          double.tryParse(_glassHDeductCtrl.text.trim()) ?? 11.4,
      isCustom: true,
      parts: _parts,
    );

    await widget.storage.addOrUpdateSector(sector);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ القطاع "${sector.name}" في قائمة القطاعات')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double pW = double.tryParse(_previewWCtrl.text) ?? 150.0;
    final double pH = double.tryParse(_previewHCtrl.text) ?? 120.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSector == null
            ? 'إضافة قطاع جديد بالصورة والأجزاء'
            : 'تعديل ومعاينة القطاع'),
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveSector,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text(
              'حفظ القطاع',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. بطاقة الاسم والصورة والسعر
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. بيانات القطاع الأساسية وصورة المعاينة:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF991B1B), width: 1.5),
                            ),
                            child: (_imagePath != null &&
                                    _imagePath!.isNotEmpty &&
                                    File(_imagePath!).existsSync())
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          color: Color(0xFF991B1B), size: 28),
                                      SizedBox(height: 4),
                                      Text(
                                        'صورة القطاع',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'اسم القطاع الجديد',
                                  hintText: 'مثال: قطاع جامبو خاص / قطاع ورشتي',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library,
                                        size: 18),
                                    label: const Text('من الاستوديو'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                    icon:
                                        const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('التقاط بالكاميرا'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'نظام القطاع',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'جرار', child: Text('شباك/باب جرار')),
                              DropdownMenuItem(
                                  value: 'مفصلي',
                                  child: Text('شباك/باب مفصلي')),
                              DropdownMenuItem(
                                  value: 'مطبخ', child: Text('قطاع مطابخ')),
                              DropdownMenuItem(
                                  value: 'مخصص', child: Text('نظام مخصص')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _category = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر المتر المربع (ج.م)',
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
                            controller: _glassWDeductCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'خصم عرض الزجاج من الضلفة (سم)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _glassHDeductCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'خصم ارتفاع الزجاج من الضلفة (سم)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. أجزاء القطاع (حلق، ضلفة، سكينة، إضافات) والعدد
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '2. أجزاء القطاع (حلق، ضلفة، سكينة، أو أي جزء آخر) والعدد:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF15803D)),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showPartDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة جزء للقطاع'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_parts.length, (idx) {
                      final part = _parts[idx];
                      final sign = part.offsetCm >= 0 ? '+' : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF991B1B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                part.role,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5),
                                  ),
                                  Text(
                                    'المعادلة: ${part.basisArabicLabel} ($sign${part.offsetCm} سم) | العدد للشباك: ${part.quantityPerWindow} قطعة ${part.multiplyBySashes ? "(× عدد الضلف)" : "(ثابت للشباك)"}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 20, color: Color(0xFF1D4ED8)),
                              onPressed: () => _showPartDialog(
                                  existingPart: part, editIndex: idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _parts.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. شاشة المعاينة الفورية للقطاع قبل الحفظ
            Card(
              color: const Color(0xFFF0FDF4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF15803D), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_imagePath != null &&
                            _imagePath!.isNotEmpty &&
                            File(_imagePath!).existsSync())
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePath!),
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '3. شاشة المعاينة الفورية للقطاع: ${_nameCtrl.text.isEmpty ? "(اسم القطاع)" : _nameCtrl.text}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _previewWCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'عرض تجريبي (سم)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _previewHCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'ارتفاع تجريبي (سم)',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _previewSashes,
                            decoration: const InputDecoration(
                              labelText: 'عدد الضلف',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 ضلفة')),
                              DropdownMenuItem(value: 2, child: Text('2 ضلفة')),
                              DropdownMenuItem(value: 3, child: Text('3 ضلفة')),
                              DropdownMenuItem(value: 4, child: Text('4 ضلفة')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _previewSashes = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نتيجة التخصيم والعدد الفوري للشباك في المعاينة:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Divider(),
                          ..._parts.map((p) {
                            final len = p.calculatePieceLength(
                                pW, pH, _previewSashes);
                            final cnt =
                                p.calculateTotalCount(1, _previewSashes);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${p.name} (${p.role}):',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    'المقاس: ${len.toStringAsFixed(1)} سم  |  العدد: $cnt قطعة',
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveSector,
                icon: const Icon(Icons.save),
                label: const Text(
                  'حفظ القطاع وإضافته لقائمة القطاعات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
