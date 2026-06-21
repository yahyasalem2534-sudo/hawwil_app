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
  
  // تنسيق الأرقام لتبدو احترافية (مثال: 1,500)
  final _fmt = NumberFormat('#,###', 'en_US');

  // استخراج قائمة المناطق الفريدة من الباقات
  List<String> get _regions {
    final regions = widget.game.pkgs
        .map((p) => p.region)
        .whereType<String>()
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
    return regions;
  }

  // فلترة الباقات بناءً على المنطقة المختارة (إذا وجدت)
  List<PackageModel> get _currentPackages {
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      return widget.game.pkgs.where((p) => p.region == _selectedRegion).toList();
    }
    return widget.game.pkgs;
  }

  @override
  void initState() {
    super.initState();
    // تحديد أول منطقة كقيمة افتراضية إذا كانت اللعبة تدعم المناطق
    final regions = _regions;
    if (regions.isNotEmpty) {
      _selectedRegion = regions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final regions = _regions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- قسم اختيار المنطقة (يظهر فقط إذا كان هناك مناطق) ---
        if (regions.isNotEmpty) ...[
          const Text('🌍 اختر المنطقة (Region)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: regions.map((region) {
                final isSelected = _selectedRegion == region;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRegion = region;
                        _selectedPackage = null; // إعادة تعيين الباقة عند تغيير المنطقة
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.green : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                            : [],
                      ),
                      child: Text(
                        region,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // --- قسم اختيار الباقة (Grid) ---
        const Text('💎 اختر الباقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        
        if (_currentPackages.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('لا توجد باقات متاحة لهذه المنطقة حالياً.', style: TextStyle(color: Colors.grey)),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _currentPackages.map((pkg) {
              final isSelected = _selectedPackage == pkg;
              
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPackage = pkg);
                  widget.onPackageSelected(pkg); // إرسال الباقة المختارة للصفحة الأب
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: (MediaQuery.of(context).size.width - 52) / 2, // عرض نصف الشاشة مع مراعاة المسافات
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.greenLight.withOpacity(isDark ? 0.1 : 0.5) 
                        : Theme.of(context).cardColor,
                    border: Border.all(
                      color: isSelected ? AppTheme.green : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: AppTheme.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] 
                        : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الكمية (Amount)
                      Text(
                        pkg.amount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // السعر (Price)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.green : (isDark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_fmt.format(pkg.price)} أوقية',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
}
