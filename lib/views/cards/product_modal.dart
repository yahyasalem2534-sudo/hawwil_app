import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bank_model.dart';
import '../../models/game_model.dart';
import '../../providers/providers.dart';
import '../../services/telegram_service.dart';
import '../../widgets/package_selector_widget.dart';

void showProductModal(BuildContext context, GameModel game) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.75),
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _ProductModal(game: game),
    ),
  );
}

class _ProductModal extends ConsumerStatefulWidget {
  final GameModel game;
  const _ProductModal({required this.game});

  @override
  ConsumerState<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends ConsumerState<_ProductModal>
    with SingleTickerProviderStateMixin {
  PackageModel? _selectedPkg;
  BankModel?    _selectedPayBank;

  final _playerIdCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  String? _receiptBase64;
  bool _loading = false;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _phoneCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _gameColor =>
      _parseColor(widget.game.bg) ?? AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final payBanksAsync = ref.watch(paymentBanksProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _gameColor.withOpacity(0.18),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.28, 1.0],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
        ),
        child: Column(
          children: [
            // مقبض
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 18),
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            _buildHeader(),

            Divider(color: Colors.white.withOpacity(0.06), height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 90),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اختيار الباقة
                    PackageSelectorWidget(
                      game: widget.game,
                      onPackageSelected: (pkg) =>
                          setState(() => _selectedPkg = pkg),
                    ),

                    const SizedBox(height: 28),

                    // طريقة الدفع
                    _sectionTitle('طريقة الدفع', Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 14),
                    _buildBankSelector(payBanksAsync),

                    const SizedBox(height: 28),

                    // بيانات الطلب
                    _sectionTitle('بيانات الطلب', Icons.info_outline_rounded),
                    const SizedBox(height: 14),

                    if (!widget.game.isService) ...[
                      _buildTextField(
                        controller: _playerIdCtrl,
                        label: 'معرّف اللاعب (Player ID)',
                        icon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'رقم هاتفك للتأكيد',
                      icon: Icons.phone_iphone_rounded,
                      type: TextInputType.phone,
                    ),

                    const SizedBox(height: 28),

                    // تعليمات الدفع
                    _buildPaymentInstructions(),
                    const SizedBox(height: 22),

                    // إرفاق الوصل
                    _buildReceiptUploader(),
                  ],
                ),
              ),
            ),

            // زر الإتمام
            _buildCheckoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          // شعار اللعبة
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _gameColor.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.game.logo != null
                  ? CachedNetworkImage(
                      imageUrl: widget.game.logo!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: _gameColor,
                        child: const Icon(Icons.videogame_asset,
                            color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: _gameColor,
                      child: Center(
                        child: Text(
                          widget.game.icon ?? '🎮',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.game.isService
                        ? 'بطاقة رقمية فورية'
                        : 'شحن مباشر',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 30, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildBankSelector(AsyncValue<List<BankModel>> payBanksAsync) {
    return payBanksAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (_, __) =>
          const Text('خطأ', style: TextStyle(color: Colors.redAccent)),
      data: (banks) {
        if (_selectedPayBank == null && banks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _selectedPayBank = banks.first));
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: banks.map((b) {
            final isSel = _selectedPayBank?.id == b.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedPayBank = b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppTheme.primaryColor.withOpacity(0.18)
                      : AppTheme.surfaceColor,
                  border: Border.all(
                    color: isSel
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.06),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                              color:
                                  AppTheme.primaryColor.withOpacity(0.25),
                              blurRadius: 12)
                        ]
                      : [],
                ),
                child: Text(
                  b.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: isSel ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: 'Cairo'),
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
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.18),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_rounded, color: AppTheme.primaryColor, size: 26),
          const SizedBox(height: 10),
          Text(
            'حوّل المبلغ عبر ${_selectedPayBank?.name ?? '—'} إلى الرقم:',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
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
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    final has = _receiptBase64 != null;
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: has
              ? AppTheme.primaryColor.withOpacity(0.09)
              : AppTheme.surfaceColor,
          border: Border.all(
            color: has
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.06),
            width: has ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: has
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.primaryColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'تم إرفاق الإيصال — اضغط للتغيير',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined,
                        size: 32, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'إرفاق صورة الإيصال',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط هنا لاختيار لقطة الشاشة',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Cairo'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor.withOpacity(0.0),
            AppTheme.backgroundColor.withOpacity(0.9),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: ScaleTransition(
        scale: _pulseAnim,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            elevation: 10,
            shadowColor: AppTheme.primaryColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: _loading
              ? const SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'إتمام الطلب',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo'),
                    ),
                    if (_selectedPkg != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_fmt.format(_selectedPkg!.price)} أوقية',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() =>
        _receiptBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _snack('يرجى تسجيل الدخول أولاً', Icons.lock_outline_rounded);
      return;
    }
    if (_selectedPkg == null) {
      _snack('يرجى اختيار الباقة', Icons.shopping_cart_outlined);
      return;
    }
    if (!widget.game.isService && _playerIdCtrl.text.isEmpty) {
      _snack('يرجى إدخال معرّف اللاعب', Icons.person_outline_rounded);
      return;
    }
    if (_phoneCtrl.text.isEmpty || _receiptBase64 == null) {
      _snack('يرجى إدخال رقم الهاتف وإرفاق الإيصال',
          Icons.warning_amber_rounded);
      return;
    }

    setState(() => _loading = true);

    try {
      final ref_ =
          'CRD-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}';
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
          'playerId': _playerIdCtrl.text.trim().isEmpty
              ? 'غير مطلوب'
              : _playerIdCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'image': _receiptBase64,
        },
      );

      await TelegramService.sendNotification(
        '🎮 طلب جديد!\nالرقم: $ref_\n'
        'المنتج: ${widget.game.name}\nالباقة: $pkgDisplay\n'
        'السعر: ${_fmt.format(_selectedPkg!.price)} أوقية\n'
        'الهاتف: ${_phoneCtrl.text}',
      );

      if (mounted) {
        Navigator.pop(context);
        _snack('تم استلام طلبك! سيتم التنفيذ قريباً 🚀',
            Icons.check_circle_rounded,
            success: true);
      }
    } catch (_) {
      _snack('حدث خطأ، حاول لاحقاً', Icons.error_outline_rounded);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg, IconData icon, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor:
            success ? AppTheme.primaryColor : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
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