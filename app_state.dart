import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/theme.dart';
import '../../data/repository/app_state.dart';
import '../../data/models/models.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedMemberIds = {};
  final List<_OrderItemInput> _orderItems = [];
  String? _photoPath;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _totalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: const Text('🍽️ Thêm bữa ăn'),
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.muted),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Lưu',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Tên quán ──────────────────────────────
                _buildLabel('TÊN QUÁN / ĐỊA ĐIỂM *'),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText: 'VD: Bún bò Mợ Ba, KFC Aeon...',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Bắt buộc nhập tên' : null,
                ),
                const SizedBox(height: 16),

                // ── Địa điểm ──────────────────────────────
                _buildLabel('KHU VỰC / THÀNH PHỐ'),
                TextFormField(
                  controller: _locationCtrl,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(hintText: 'VD: Bình Dương, TP.HCM...'),
                ),
                const SizedBox(height: 16),

                // ── Ngày ──────────────────────────────────
                _buildLabel('NGÀY ĂN *'),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.muted, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          Fmt.dateFull(_selectedDate),
                          style: const TextStyle(color: AppColors.white, fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tổng tiền ─────────────────────────────
                _buildLabel('TỔNG HOÁ ĐƠN (₫) *'),
                TextFormField(
                  controller: _totalCtrl,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'VD: 480000'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Bắt buộc nhập số tiền';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Thành viên ────────────────────────────
                _buildLabel('THÀNH VIÊN ĐI ĂN *'),
                const SizedBox(height: 8),
                _MemberSelector(
                  members: state.members,
                  selected: _selectedMemberIds,
                  onToggle: (id) => setState(() {
                    if (!_selectedMemberIds.remove(id)) _selectedMemberIds.add(id);
                    // Xoá order items của người bị bỏ chọn
                    _orderItems.removeWhere((o) => o.memberId == id && !_selectedMemberIds.contains(id));
                  }),
                  onAddNew: () => _showAddMemberDialog(context, state),
                ),
                const SizedBox(height: 20),

                // ── Món riêng ─────────────────────────────
                if (_selectedMemberIds.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(child: _buildLabel('MÓN GỌI RIÊNG (tuỳ chọn)', bottom: 0)),
                      TextButton.icon(
                        onPressed: () => _showAddOrderDialog(context, state),
                        icon: const Icon(Icons.add, size: 16, color: AppColors.teal),
                        label: const Text('Thêm', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._orderItems.asMap().entries.map((e) => _OrderItemTile(
                        item: e.value,
                        members: state.members,
                        onDelete: () => setState(() => _orderItems.removeAt(e.key)),
                      )),
                  const SizedBox(height: 8),
                ],

                // ── Ảnh chụp chung ────────────────────────
                _buildLabel('ẢNH CHỤP CHUNG (minh chứng)'),
                const SizedBox(height: 8),
                _PhotoPicker(
                  photoPath: _photoPath,
                  onPick: _pickPhoto,
                  onRemove: () => setState(() => _photoPath = null),
                ),
                const SizedBox(height: 16),

                // ── Ghi chú ───────────────────────────────
                _buildLabel('GHI CHÚ'),
                TextFormField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: AppColors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Ghi chú thêm về bữa ăn...'),
                ),
                const SizedBox(height: 32),

                // ── Save button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '💾  Lưu bữa ăn',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, {double bottom = 6}) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 1.0,
          ),
        ),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickPhoto() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.accent),
            title: const Text('Chụp ảnh', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.teal),
            title: const Text('Chọn từ thư viện', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
    if (result == null) return;
    final picked = await ImagePicker().pickImage(source: result, imageQuality: 85);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  void _showAddOrderDialog(BuildContext context, AppState state) {
    final selectedMembers = state.members.where((m) => _selectedMemberIds.contains(m.id)).toList();
    if (selectedMembers.isEmpty) return;

    Member? chosenMember = selectedMembers.first;
    final itemCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Thêm món riêng', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ai gọi?', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              // Member dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<Member>(
                  value: chosenMember,
                  isExpanded: true,
                  dropdownColor: AppColors.surface2,
                  underline: const SizedBox(),
                  items: selectedMembers.map((m) => DropdownMenuItem(
                    value: m,
                    child: Row(children: [
                      Text(m.emoji), const SizedBox(width: 8),
                      Text(m.name, style: const TextStyle(color: AppColors.white)),
                    ]),
                  )).toList(),
                  onChanged: (m) => setDialogState(() => chosenMember = m),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Món gọi', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: itemCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'VD: Chả giò, Sinh tố...'),
              ),
              const SizedBox(height: 14),
              const Text('Tiền thêm (₫)', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                style: const TextStyle(color: AppColors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'VD: 25000'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppColors.muted))),
            ElevatedButton(
              onPressed: () {
                if (chosenMember == null || itemCtrl.text.isEmpty) return;
                final amount = int.tryParse(amountCtrl.text) ?? 0;
                setState(() => _orderItems.add(_OrderItemInput(
                  memberId: chosenMember!.id,
                  itemName: itemCtrl.text.trim(),
                  extraAmount: amount,
                )));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Thêm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '😊';
    Color selectedColor = AppColors.memberColors.first;

    final emojis = ['😊', '😎', '🤙', '😄', '🌸', '👑', '🎯', '🦁', '🐉', '⚡'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Thêm thành viên mới', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Tên thành viên'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Chọn emoji', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => setDialogState(() => selectedEmoji = e),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selectedEmoji == e ? AppColors.accent.withOpacity(0.2) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedEmoji == e ? AppColors.accent : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Chọn màu', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppColors.memberColors.map((c) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppColors.muted))),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await state.addMember(nameCtrl.text.trim(), selectedEmoji, selectedColor);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Thêm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 thành viên'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final state = context.read<AppState>();

    final orderItems = _orderItems.map((o) => OrderItem(
      mealId: 0,
      memberId: o.memberId,
      itemName: o.itemName,
      extraAmount: o.extraAmount,
    )).toList();

    final mealId = await state.addMeal(
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      date: _selectedDate,
      totalAmount: int.parse(_totalCtrl.text),
      payerId: state.payerId,
      memberIds: _selectedMemberIds.toList(),
      orderItems: orderItems,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    // Lưu ảnh sau khi có mealId
    if (_photoPath != null) {
      await state.updateMealPhoto(mealId, _photoPath);
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu bữa ăn!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _MemberSelector extends StatelessWidget {
  final List<Member> members;
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onAddNew;

  const _MemberSelector({
    required this.members,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...members.map((m) => MemberChip(
              name: m.name,
              emoji: m.emoji,
              color: m.color,
              isSelected: selected.contains(m.id),
              onTap: () => onToggle(m.id),
            )),
        GestureDetector(
          onTap: onAddNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.teal),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: AppColors.teal),
                SizedBox(width: 4),
                Text('Thêm người', style: TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoPicker({this.photoPath, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('📸', style: TextStyle(fontSize: 28)),
            SizedBox(height: 6),
            Text('Chụp hoặc chọn ảnh chụp chung', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final _OrderItemInput item;
  final List<Member> members;
  final VoidCallback onDelete;

  const _OrderItemTile({required this.item, required this.members, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final member = members.firstWhere((m) => m.id == item.memberId, orElse: () => Member(id: 0, name: '?'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(member.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w700)),
                  Text(item.itemName, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Text(
              '+${Fmt.money(item.extraAmount)}',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemInput {
  final int memberId;
  final String itemName;
  final int extraAmount;
  _OrderItemInput({required this.memberId, required this.itemName, required this.extraAmount});
}
