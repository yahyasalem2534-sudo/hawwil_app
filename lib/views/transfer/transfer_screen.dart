import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bank_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/telegram_service.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});
  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _fromBankId;
  String? _toBankId;
  String? _receiptBase64;
  bool _loading = false;
  bool _success = false;
  String _successRef = '';

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _commission => _amount * AppConstants.commissionRate;
  double get _receive => _amount - _commission;

  final _fmt = NumberFormat('#,###', 'ar');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحويل البنكي')),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppTheme.greenLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  size: 50, color: AppTheme.green),
            ),
            const SizedBox(height: 20),
            const Text('تم استلام طلبك بنجاح!',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'سيتم مراجعة طلبك وإتمام التحويل قريباً.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'رقم الطلب: #$_successRef',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.green,
                    fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetForm,
              child: const Text('طلب تحويل جديد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final banksAsync = ref.watch(banksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.person_outline, title: 'بيانات العميل'),
          const SizedBox(height: 12),
          _buildTextField(_nameCtrl, 'الاسم الكامل', 'محمد ولد أحمد'),
          const SizedBox(height: 10),
          _buildTextField(_phoneCtrl, 'رقم الهاتف', '2222 00 222',
              type: TextInputType.phone),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.attach_money, title: 'المبلغ والعمولة'),
          const SizedBox(height: 12),
          _buildTextField(_amountCtrl, 'المبلغ المُرسَل (أوقية)', '10000',
              type: TextInputType.number,
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _buildCalcBox(),

          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.send_outlined, title: 'بنك الإرسال'),
          const SizedBox(height: 12),
          banksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('خطأ في تحميل البنوك'),
            data: (banks) => _buildBankSelector(banks, 'from'),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('⬇ سيتم التحويل إلى',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
            ),
          ),

          _SectionTitle(icon: Icons.account_balance_outlined, title: 'بنك الاستلام'),
          const SizedBox(height: 12),
          banksAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (banks) => _buildBankSelector(banks, 'to'),
          ),

          const SizedBox(height: 16),
          _buildTextField(_accountCtrl, 'رقم حساب المستلم *', '0000123456'),
          const SizedBox(height: 10),
          _buildTextField(_notesCtrl, 'ملاحظات (اختياري)', ''),

          const SizedBox(height: 16),
          _buildPaymentNote(),

          const SizedBox(height: 16),
          _SectionTitle(icon: Icons.image_outlined, title: 'إرفاق صورة الوصل *'),
          const SizedBox(height: 12),
          _buildReceiptUploader(),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('✅ إرسال طلب التحويل'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCalcBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _CalcRow(label: 'المبلغ المُرسَل',
              value: _amount > 0 ? '${_fmt.format(_amount)} أوقية' : '—'),
          _CalcRow(
              label: 'العمولة (5%)',
              value: _amount > 0 ? '-${_fmt.format(_commission)} أوقية' : '—',
              valueColor: AppTheme.red),
          const Divider(),
          _CalcRow(
            label: '✅ المبلغ الذي يستلمه',
            value: _amount > 0 ? '${_fmt.format(_receive)} أوقية' : '—',
            bold: true,
            valueColor: AppTheme.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector(List<BankModel> banks, String type) {
    final selected = type == 'from' ? _fromBankId : _toBankId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: banks.map((b) {
        final isSelected = selected == b.id;
        return GestureDetector(
          onTap: () => setState(() {
            if (type == 'from') _fromBankId = b.id;
            else _toBankId = b.id;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.greenLight : Colors.white,
              border: Border.all(
                color: isSelected ? AppTheme.green : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              b.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.green : null,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.green, style: BorderStyle.solid, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('📱 رقمنا لاستلام الحوالات',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.green,
                  fontSize: 14)),
          const SizedBox(height: 6),
          const Text(AppConstants.paymentNumber,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 4),
          const Text(
            'حوّل المبلغ الكامل لهذا الرقم أولاً، ثم أرفق صورة الوصل.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _receiptBase64 != null ? AppTheme.greenLight : Colors.white,
          border: Border.all(
            color: _receiptBase64 != null ? AppTheme.green : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _receiptBase64 != null
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_receiptBase64!.split(',').last),
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('✅ تم إرفاق الوصل — اضغط لتغييره',
                      style: TextStyle(
                          color: AppTheme.green, fontWeight: FontWeight.w700)),
                ],
              )
            : const Column(
                children: [
                  Icon(Icons.upload_file_rounded, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('اضغط لإرفاق صورة الوصل',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppTheme.green)),
                  Text('JPG, PNG', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  TextField _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType type = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _receiptBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('⚠️ يرجى تسجيل الدخول أولاً')));
      return;
    }

    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty ||
        _amount <= 0 || _fromBankId == null || _toBankId == null ||
        _accountCtrl.text.isEmpty || _receiptBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ يرجى ملء جميع الحقول وإرفاق الوصل')));
      return;
    }

    if (_fromBankId == _toBankId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ بنك الإرسال والاستلام لا يمكن أن يكونا نفس البنك')));
      return;
    }

    setState(() => _loading = true);

    try {
      final banks = ref.read(banksProvider).value ?? [];
      final fromBank = banks.firstWhere((b) => b.id == _fromBankId);
      final toBank = banks.firstWhere((b) => b.id == _toBankId);
      final ref_ =
          'HW-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';

      await ref.read(firebaseServiceProvider).submitTransfer(
        uid: user.uid,
        ref: ref_,
        data: {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'amount': _amount,
          'commRate': 5.0,
          'commission': _commission,
          'receive': _receive,
          'fromBank': fromBank.name,
          'toBank': toBank.name,
          'account': _accountCtrl.text.trim(),
          'notes': _notesCtrl.text.trim(),
          'image': _receiptBase64,
        },
      );

      await TelegramService.sendNotification(
        '🔔 طلب تحويل جديد!\nالرقم: $ref_\nالاسم: ${_nameCtrl.text}\n'
        'المبلغ: ${_fmt.format(_amount)} أوقية\n'
        'من: ${fromBank.name} ➡️ ${toBank.name}',
      );

      setState(() {
        _success = true;
        _successRef = ref_;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('❌ خطأ في الإرسال، حاول لاحقاً')));
    }

    setState(() => _loading = false);
  }

  void _resetForm() {
    setState(() {
      _success = false;
      _fromBankId = _toBankId = _receiptBase64 = null;
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _amountCtrl.clear();
      _accountCtrl.clear();
      _notesCtrl.clear();
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.green),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _CalcRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 13,
                  color: valueColor)),
        ],
      ),
    );
  }
}
