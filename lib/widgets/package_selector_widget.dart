import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/game_model.dart';

class PackageSelectorWidget extends StatefulWidget {
  final GameModel game;
  final ValueChanged<PackageModel> onPackageSelected;

  const PackageSelectorWidget({
    super.key,
    required this.game,
    required this.onPackageSelected,
  });

  @override
  State<PackageSelectorWidget> createState() => _PackageSelectorWidgetState();
}

class _PackageSelectorWidgetState extends State<PackageSelectorWidget> {
  String? _selectedRegion;
  PackageModel? _selectedPackage;
  
  // تنسيق الأرقام لتبدو احترافية
  final _fmt = NumberFormat('#,###', 'en_US');

  // استخراج قائمة المناطق الفريدة من الباقات
  List<String> get _regions {
    return widget.game.pkgs
        .map((p) => p.region)
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
  }

  // فلترة الباقات بناءً على المنطقة المختارة
  List<PackageModel> get _currentPackages {
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      return widget.game.pkgs.where((p) => p.region == _selectedRegion).toList();
    }
    return widget.game.pkgs;
  }

  @override
  void initState() {
    super.initState();
    final regions = _regions;
    if (regions.isNotEmpty) {
      _selectedRegion = regions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final regions = _regions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- قسم اختيار المنطقة (Regions) ---
        if (regions.isNotEmpty) ...[
          _buildSectionHeader('المنطقة المخصصة', Icons.public_rounded),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none, // للسماح للظلال بالظهور خارج الحواف
            child: Row(
              children: regions.map((region) {
                final isSelected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                        _selectedPackage = null; 
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : AppTheme.surfaceColor.withOpacity(0.5),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] 
                            : [],
                      ),
                      child: Text(
                        region,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // --- قسم اختيار الباقة (Glowing Cards Grid) ---
        _buildSectionHeader('باقات الشحن', Icons.diamond_outlined),
        const SizedBox(height: 16),
        
        if (_currentPackages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Center(
              child: Text('لا توجد باقات متاحة لهذه المنطقة حالياً', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _currentPackages.map((pkg) {
              final isSelected = _selectedPackage == pkg;
              // حساب العرض ليأخذ نصف الشاشة مع مراعاة الحواف (Padding = 24*2 = 48) والمسافة بين الكروت (16)
              final cardWidth = (MediaQuery.of(context).size.width - 64) / 2;
              
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPackage = pkg);
                  widget.onPackageSelected(pkg);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.03),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected 
                        ? [
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: -5),
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                          ] 
                        : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الأيقونة والكمية
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.game.isService ? Icons.card_giftcard_rounded : Icons.diamond_rounded, 
                            color: isSelected ? AppTheme.primaryColor : Colors.white54, 
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              pkg.amount,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isSelected ? Colors.white : Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // السعر داخل كبسولة أنيقة
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected 
                              ? LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)])
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_fmt.format(pkg.price)} أوقية',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // عنوان القسم (مكرر بلمسة فخمة)
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
