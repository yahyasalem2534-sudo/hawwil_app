import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bank_model.dart';
import '../../models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/telegram_service.dart';
import '../../widgets/package_selector_widget.dart';

void showProductModal(BuildContext context, GameModel game) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // تم حذف ProviderScope هنا لأنها تسبب انهيار التطبيق (Crash) في الإصدارات الجديدة
    builder: (ctx) => _ProductModal(game: game),
  );
}

class _ProductModal extends ConsumerStatefulWidget {
  final GameModel game;
  const _ProductModal({required this.game});

  @override
  ConsumerState<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends ConsumerState<_ProductModal> {
  PackageModel? _selectedPkg;
  BankModel? _selectedPayBank;
  final _playerIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _receiptBase64;
  bool _loading = false;

  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payBanksAsync = ref.watch(paymentBanksProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.game.bg) ?? AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.game.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(widget.game.logo!, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(widget.game.icon ?? '🎮',
                              style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.game.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const Text('اختر الكمية والمنطقة المناسبة',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PackageSelectorWidget(
                    game: widget.game,
                    onPackageSelected: (pkg) => setState(() => _selectedPkg = pkg),
                  ),
                  const SizedBox(height: 20),
                  const Text('🏦 اختر بنك الدفع',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  payBanksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (banks) {
                      if (_selectedPayBank == null && banks.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => setState(() => _selectedPayBank = banks.first));
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: banks.map((b) {
                          final isSelected = _selectedPayBank?.id == b.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPayBank = b),
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
                                  fontSize: 12,
                                  color: isSelected ? AppTheme.green : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!widget.game.isService) ...[
                    TextField(
                      controller: _playerIdCtrl,
                      decoration: const InputDecoration(labelText: 'معرّف اللاعب / الحساب *'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم هاتفك للتأكيد *'),
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentNote(),
                  const SizedBox(height: 16),
                  _buildReceiptUploader(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('✅ إرسال الطلب الآن'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'للطلب يرجى الدفع عبر ${_selectedPayBank?.name ?? '—'} للرقم:',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.green, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(AppConstants.paymentNumber,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _receiptBase64 != null ? AppTheme.greenLight : Colors.white,
          border: Border.all(
            color: _receiptBase64 != null ? AppTheme.green : Colors.grey[300]!,
            width: 1.5,
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
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('✅ تم الإرفاق — اضغط لتغييره',
                      style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              )
            : const Column(
                children: [
                  Icon(Icons.upload_file_rounded, size: 32, color: Colors.grey),
                  SizedBox(height: 6),
                  Text('اضغط لإرفاق وصل الدفع *',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.green, fontSize: 13)),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _receiptBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى تسجيل الدخول أولاً')));
      return;
    }
    if (_selectedPkg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ اختر باقة أولاً')));
      return;
    }
    if (!widget.game.isService && _playerIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أدخل معرف اللاعب')));
      return;
    }
    if (_phoneCtrl.text.isEmpty || _receiptBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أدخل رقم هاتفك وأرفق الوصل')));
      return;
    }

    setState(() => _loading = true);

    try {
      final ref_ = 'CRD-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
      
      final pkgDisplay = _selectedPkg!.region != null 
          ? '[${_selectedPkg!.region}] ${_selectedPkg!.amount}'
          : _selectedPkg!.amount;

      await ref.read(firebaseServiceProvider).submitCard(
        uid: user.uid,
        ref: ref_,
        data: {
          'game': widget.game.name,
          'gameId': widget.game.id,
          'package': pkgDisplay,
          'price': _selectedPkg!.price,
          'paymentBank': _selectedPayBank?.name ?? 'غير محدد',
          'playerId': _playerIdCtrl.text.trim().isEmpty ? 'غير مطلوب' : _playerIdCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'image': _receiptBase64,
        },
      );

      await TelegramService.sendNotification(
        '🎮 طلب منتج رقمي جديد!\nالرقم: $ref_\n'
        'المنتج: ${widget.game.name}\nالباقة: $pkgDisplay\n'
        'السعر: ${_fmt.format(_selectedPkg!.price)} أوقية\n'
        'الهاتف: ${_phoneCtrl.text}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم إرسال طلبك بنجاح!'),
          backgroundColor: AppTheme.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ حدث خطأ، حاول لاحقاً')));
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}
