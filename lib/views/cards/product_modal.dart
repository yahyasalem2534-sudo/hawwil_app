import 'dart:convert';
import 'dart:ui';
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
    backgroundColor: Colors.transparent, // Required for Glassmorphism
    barrierColor: Colors.black.withOpacity(0.7), // Deeper barrier color
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context).overlay!,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    ),
    builder: (ctx) => _ProductModal(game: game),
  );
}

// دالة مساعدة للجسر من الشاشة الرئيسية
Widget showProductModalContent(BuildContext context, GameModel game) {
  return _ProductModal(game: game);
}

class _ProductModal extends ConsumerStatefulWidget {
  final GameModel game;
  const _ProductModal({required this.game});

  @override
  ConsumerState<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends ConsumerState<_ProductModal> with SingleTickerProviderStateMixin {
  PackageModel? _selectedPkg;
  BankModel? _selectedPayBank;
  final _playerIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _receiptBase64;
  bool _loading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _fmt = NumberFormat('#,###', 'ar');

  @override
  void initState() {
    super.initState();
    // Animation for the "Checkout" button to make it feel alive
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _playerIdCtrl.dispose();
    _phoneCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payBanksAsync = ref.watch(paymentBanksProvider);
    final gameColor = _parseColor(widget.game.bg) ?? AppTheme.primaryColor;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Deep Glassmorphism effect
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92, // Slightly taller
        decoration: BoxDecoration(
          // Gradient background using the game's theme color mixed with dark theme
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gameColor.withOpacity(0.15),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
        ),
        child: Column(
          children: [
            // --- Drag Indicator ---
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // --- Premium Header ---
            _buildPremiumHeader(gameColor),
            
            const SizedBox(height: 10),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Extra bottom padding
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Packages Selection
                    PackageSelectorWidget(
                      game: widget.game,
                      onPackageSelected: (pkg) => setState(() => _selectedPkg = pkg),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bank Selection
                    _buildSectionTitle('طريقة الدفع', Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 16),
                    _buildBankSelector(payBanksAsync),
                    
                    const SizedBox(height: 32),

                    // Inputs Section
                    _buildSectionTitle('بيانات الطلب', Icons.info_outline_rounded),
                    const SizedBox(height: 16),
                    
                    if (!widget.game.isService) ...[
                      _buildPremiumTextField(
                        controller: _playerIdCtrl,
                        label: 'معرّف اللاعب (Player ID)',
                        icon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildPremiumTextField(
                      controller: _phoneCtrl,
                      label: 'رقم هاتفك للتأكيد',
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Instructions & Receipt
                    _buildPaymentInstructions(),
                    const SizedBox(height: 24),
                    _buildReceiptUploader(),
                  ],
                ),
              ),
            ),

            // --- Pulsing Floating Checkout Button ---
            _buildFloatingCheckoutButton(gameColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(Color gameColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Logo with Glow Effect
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gameColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: widget.game.logo != null
                  ? CachedNetworkImage(
                      imageUrl: widget.game.logo!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppTheme.surfaceColor),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.videogame_asset, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: gameColor,
                      child: Center(child: Text(widget.game.icon ?? '🎮', style: const TextStyle(fontSize: 40))),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.game.name,
                  style: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    widget.game.isService ? 'بطاقة رقمية فورية' : 'شحن مباشر للحساب',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Elegant Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBankSelector(AsyncValue<List<BankModel>> payBanksAsync) {
    return payBanksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      error: (_, __) => const Text('حدث خطأ', style: TextStyle(color: Colors.redAccent)),
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
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.surfaceColor,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] 
                    : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      b.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_rounded, color: AppTheme.primaryColor, size: 28),
          const SizedBox(height: 12),
          Text(
            'قم بتحويل المبلغ عبر ${_selectedPayBank?.name ?? '—'} إلى الرقم:',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Text(
              AppConstants.paymentNumber,
              style: TextStyle(
                fontSize: 28, 
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
    final bool hasImage = _receiptBase64 != null;

    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hasImage ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
          border: Border.all(
            color: hasImage ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: hasImage
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_receiptBase64!.split(',').last),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 18),
                        SizedBox(width: 8),
                        Text('تم إرفاق الإيصال (اضغط للتغيير)', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    child: const Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('إرفاق صورة التحويل البنكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('اضغط هنا لاختيار لقطة الشاشة', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
      ),
    );
  }

  Widget _buildFloatingCheckoutButton(Color gameColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // Safe area + padding
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
        scale: _pulseAnimation,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64), // Taller button
            elevation: 10,
            shadowColor: AppTheme.primaryColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _loading
              ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('إتمام الطلب الآن', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(width: 12),
                    if (_selectedPkg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${_fmt.format(_selectedPkg!.price)} أوقية',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                  ],
                ),
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
      _showCustomSnackBar('يرجى تسجيل الدخول أولاً لإتمام الطلب', Icons.lock_outline_rounded);
      return;
    }
    if (_selectedPkg == null) {
      _showCustomSnackBar('يرجى اختيار الباقة التي تريد شرائها', Icons.shopping_cart_outlined);
      return;
    }
    if (!widget.game.isService && _playerIdCtrl.text.isEmpty) {
      _showCustomSnackBar('يرجى إدخال معرّف اللاعب (Player ID)', Icons.person_outline_rounded);
      return;
    }
    if (_phoneCtrl.text.isEmpty || _receiptBase64 == null) {
      _showCustomSnackBar('يرجى إدخال رقم الهاتف وإرفاق صورة الإيصال', Icons.warning_amber_rounded);
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
        _showCustomSnackBar('تم استلام طلبك بنجاح! سيتم التنفيذ قريباً 🚀', Icons.check_circle_rounded, isSuccess: true);
      }
    } catch (e) {
      _showCustomSnackBar('حدث خطأ أثناء المعالجة، يرجى المحاولة لاحقاً', Icons.error_outline_rounded);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showCustomSnackBar(String message, IconData icon, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.primaryColor : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
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
