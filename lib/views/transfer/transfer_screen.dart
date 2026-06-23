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
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _amountCtrl  = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String? _fromBankId;
  String? _toBankId;
  String? _receiptBase64;
  bool _loading = false;
  bool _success = false;
  String _successRef = '';

  double get _amount     => double.tryParse(_amountCtrl.text) ?? 0;
  double get _commission => _amount * AppConstants.commissionRate;
  double get _receive    => _amount - _commission;

  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التحويل البنكي',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            fontSize: 20,
          ),
        ),
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  // ─── شاشة النجاح ───────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة النجاح مع توهج
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'تم استلام طلبك بنجاح!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'سيتم مراجعة طلبك وإتمام التحويل قريباً.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // رقم الطلب
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag_rounded, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'رقم الطلب: $_successRef',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      fontFamily: 'Cairo',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'طلب تحويل جديد',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── النموذج الرئيسي ────────────────────────────────────────────────────
  Widget _buildForm() {
    final banksAsync = ref.watch(banksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── بيانات العميل ───────────────────────────────────────────────
          _buildSectionHeader('بيانات العميل', Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _buildPremiumTextField(_nameCtrl,   'الاسم الكامل',   Icons.badge_outlined),
          const SizedBox(height: 12),
          _buildPremiumTextField(_phoneCtrl,  'رقم الهاتف',     Icons.phone_iphone_rounded,
              type: TextInputType.phone),

          const SizedBox(height: 28),

          // ── المبلغ والعمولة ─────────────────────────────────────────────
          _buildSectionHeader('المبلغ والعمولة', Icons.attach_money_rounded),
          const SizedBox(height: 14),
          _buildPremiumTextField(
            _amountCtrl,
            'المبلغ المُرسَل (أوقية)',
            Icons.payments_outlined,
            type: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _buildCalcBox(),

          const SizedBox(height: 28),

          // ── بنك الإرسال ────────────────────────────────────────────────
          _buildSectionHeader('بنك الإرسال', Icons.send_rounded),
          const SizedBox(height: 14),
          banksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error:   (_, __) => const Text('خطأ في تحميل البنوك', style: TextStyle(color: Colors.redAccent)),
            data:    (banks) => _buildBankSelector(banks, 'from'),
          ),

          // سهم الاتجاه
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'سيتم التحويل إلى',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── بنك الاستلام ────────────────────────────────────────────────
          _buildSectionHeader('بنك الاستلام', Icons.account_balance_outlined),
          const SizedBox(height: 14),
          banksAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (banks) => _buildBankSelector(banks, 'to'),
          ),

          const SizedBox(height: 20),
          _buildPremiumTextField(_accountCtrl, 'رقم حساب المستلم', Icons.account_box_outlined),
          const SizedBox(height: 12),
          _buildPremiumTextField(_notesCtrl,   'ملاحظات (اختياري)', Icons.notes_rounded),

          const SizedBox(height: 28),

          // ── رقم التحويل ─────────────────────────────────────────────────
          _buildSectionHeader('رقم الاستلام', Icons.info_outline_rounded),
          const SizedBox(height: 14),
          _buildPaymentNote(),

          const SizedBox(height: 28),

          // ── إرفاق الوصل ─────────────────────────────────────────────────
          _buildSectionHeader('صورة الوصل', Icons.image_outlined),
          const SizedBox(height: 14),
          _buildReceiptUploader(),

          const SizedBox(height: 32),

          // ── زر الإرسال ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'إرسال طلب التحويل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
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

  // ─── مكوّنات UI ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildCalcBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _CalcRow(
            label: 'المبلغ المُرسَل',
            value: _amount > 0 ? '${_fmt.format(_amount)} أوقية' : '—',
          ),
          const SizedBox(height: 10),
          _CalcRow(
            label: 'العمولة (${(AppConstants.commissionRate * 100).toStringAsFixed(0)}%)',
            value: _amount > 0 ? '- ${_fmt.format(_commission)} أوقية' : '—',
            valueColor: Colors.redAccent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white.withOpacity(0.08)),
          ),
          _CalcRow(
            label: 'المبلغ الذي يستلمه',
            value: _amount > 0 ? '${_fmt.format(_receive)} أوقية' : '—',
            bold: true,
            valueColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector(List<BankModel> banks, String type) {
    final selected = type == 'from' ? _fromBankId : _toBankId;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: banks.map((b) {
        final isSelected = selected == b.id;
        return GestureDetector(
          onTap: () => setState(() {
            if (type == 'from') _fromBankId = b.id;
            else _toBankId = b.id;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.15)
                  : AppTheme.surfaceColor,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.07),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 8)]
                  : [],
            ),
            child: Text(
              b.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 13,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.18), AppTheme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.smartphone_rounded, color: AppTheme.primaryColor, size: 28),
          const SizedBox(height: 10),
          const Text(
            'رقمنا لاستلام الحوالات',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              AppConstants.paymentNumber,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'حوّل المبلغ الكامل لهذا الرقم أولاً، ثم أرفق صورة الوصل.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    final bool hasImage = _receiptBase64 != null;

    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: hasImage
              ? AppTheme.primaryColor.withOpacity(0.08)
              : AppTheme.surfaceColor,
          border: Border.all(
            color: hasImage ? AppTheme.primaryColor : Colors.white.withOpacity(0.07),
            width: hasImage ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: hasImage
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_receiptBase64!.split(',').last),
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'تم إرفاق الوصل — اضغط للتغيير',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, size: 34, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'اضغط لإرفاق صورة الوصل',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG أو PNG',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── المنطق ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _receiptBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('يرجى تسجيل الدخول أولاً', Icons.lock_outline_rounded);
      return;
    }
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty ||
        _amount <= 0 || _fromBankId == null || _toBankId == null ||
        _accountCtrl.text.isEmpty || _receiptBase64 == null) {
      _snack('يرجى ملء جميع الحقول وإرفاق الوصل', Icons.warning_amber_rounded);
      return;
    }
    if (_fromBankId == _toBankId) {
      _snack('بنك الإرسال والاستلام لا يمكن أن يكونا نفس البنك', Icons.error_outline_rounded);
      return;
    }

    setState(() => _loading = true);

    try {
      final banks    = ref.read(banksProvider).value ?? [];
      final fromBank = banks.firstWhere((b) => b.id == _fromBankId);
      final toBank   = banks.firstWhere((b) => b.id == _toBankId);
      final ref_     = 'HW-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';

      await ref.read(firebaseServiceProvider).submitTransfer(
        uid: user.uid,
        ref: ref_,
        data: {
          'name':      _nameCtrl.text.trim(),
          'phone':     _phoneCtrl.text.trim(),
          'amount':    _amount,
          'commRate':  AppConstants.commissionRate * 100,
          'commission': _commission,
          'receive':   _receive,
          'fromBank':  fromBank.name,
          'toBank':    toBank.name,
          'account':   _accountCtrl.text.trim(),
          'notes':     _notesCtrl.text.trim(),
          'image':     _receiptBase64,
        },
      );

      await TelegramService.sendNotification(
        '🔔 طلب تحويل جديد!\nالرقم: $ref_\n'
        'الاسم: ${_nameCtrl.text}\n'
        'المبلغ: ${_fmt.format(_amount)} أوقية\n'
        'من: ${fromBank.name} ➡️ ${toBank.name}',
      );

      setState(() { _success = true; _successRef = ref_; });
    } catch (_) {
      _snack('خطأ في الإرسال، حاول لاحقاً', Icons.error_outline_rounded);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _success      = false;
      _fromBankId   = _toBankId = _receiptBase64 = null;
      for (final c in [_nameCtrl, _phoneCtrl, _amountCtrl, _accountCtrl, _notesCtrl]) {
        c.clear();
      }
    });
  }
}

// ─── ويدجت مساعد: صف الحساب ───────────────────────────────────────────────
class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _CalcRow({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? Colors.white : AppTheme.textSecondary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'Cairo',
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontFamily: 'Cairo',
            fontSize: bold ? 15 : 13,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
