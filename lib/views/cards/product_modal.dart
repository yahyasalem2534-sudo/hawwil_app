import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          // --- مؤشر السحب وزر الإغلاق ---
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8, right: 16, left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // توازن المساحة
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                ),
              ],
            ),
          ),

          // --- الهيدر الفخم للمنتج ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: _parseColor(widget.game.bg) ?? AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: widget.game.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: widget.game.logo!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.videogame_asset),
                          ),
                        )
                      : Center(child: Text(widget.game.icon ?? '🎮', style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.game.isService ? 'بطاقة رقمية فورية' : 'شحن مباشر للحساب',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 30),

          // --- المحتوى القابل للتمرير ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ويدجت اختيار الباقات
                  PackageSelectorWidget(
                    game: widget.game,
                    onPackageSelected: (pkg) => setState(() => _selectedPkg = pkg),
                  ),
                  const SizedBox(height: 24),
                  
                  // اختيار بنك الدفع
                  const Text('🏦 اختر بنك الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  payBanksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('حدث خطأ في جلب البنوك', style: TextStyle(color: AppTheme.red)),
                    data: (banks) {
                      if (_selectedPayBank == null && banks.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _selectedPayBank = banks.first));
                      }
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: banks.map((b) {
                          final isSelected = _selectedPayBank?.id == b.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPayBank = b),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.green : (isDark ? Colors.grey[800] : Colors.white),
                                border: Border.all(
                                  color: isSelected ? AppTheme.green : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Text(
                                b.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // الحقول ومعلومات الدفع
                  if (!widget.game.isService) ...[
                    TextField(
                      controller: _playerIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'معرّف اللاعب (Player ID) *',
                        prefixIcon: Icon(Icons.person_pin_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتفك للتأكيد *',
                      prefixIcon: Icon(Icons.phone_android_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPaymentNote(),
                  const SizedBox(height: 20),
                  _buildReceiptUploader(),
                  
                  // مساحة إضافية لتجنب تغطية الزر السفلي للمحتوى
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 120),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // --- الزر السفلي الثابت ---
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), blurRadius: 10, offset: const Offset(0, -4))
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Text('إتمام الطلب', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greenLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.green.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'للطلب يرجى الدفع عبر ${_selectedPayBank?.name ?? '—'} للرقم:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greenDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              AppConstants.paymentNumber,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasImage = _receiptBase64 != null;

    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasImage ? AppTheme.greenLight.withOpacity(0.3) : (isDark ? Colors.grey[900] : Colors.grey[50]),
          border: Border.all(
            color: hasImage ? AppTheme.green : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: hasImage
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(_receiptBase64!.split(',').last),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 20),
                      SizedBox(width: 8),
                      Text('تم إرفاق الإيصال بنجاح (اضغط للتغيير)', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, size: 32, color: AppTheme.green),
                  ),
                  const SizedBox(height: 12),
                  const Text('إرفاق إيصال الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('صورة لقطة الشاشة للتحويل البنكي', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى اختيار الباقة')));
      return;
    }
    if (!widget.game.isService && _playerIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى إدخال معرّف اللاعب')));
      return;
    }
    if (_phoneCtrl.text.isEmpty || _receiptBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ يرجى إدخال رقم الهاتف وإرفاق الإيصال')));
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
          content: Text('✅ تم إرسال طلبك بنجاح! سيتم معالجته قريباً.'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ حدث خطأ أثناء إرسال الطلب، يرجى المحاولة لاحقاً')));
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
