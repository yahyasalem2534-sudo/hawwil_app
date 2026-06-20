import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/game_model.dart';

class PackageSelectorWidget extends StatefulWidget {
  final GameModel game;
  final ValueChanged<PackageModel?> onPackageSelected;

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
  PackageModel? _selectedPkg;

  @override
  void initState() {
    super.initState();
    if (widget.game.isRegional) {
      final regions = _getRegions();
      if (regions.isNotEmpty) _selectedRegion = regions.first;
    }
  }

  List<String> _getRegions() {
    return widget.game.pkgs
        .where((p) => p.region != null)
        .map((p) => p.region!)
        .toSet()
        .toList();
  }

  List<PackageModel> get _filteredPkgs {
    if (_selectedRegion != null) {
      return widget.game.pkgs
          .where((p) => p.region == _selectedRegion)
          .toList();
    }
    return widget.game.pkgs;
  }

  void _selectPkg(PackageModel pkg) {
    setState(() => _selectedPkg = pkg);
    widget.onPackageSelected(pkg);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.game.isRegional) _buildRegionSelector(),
        _buildPackageGrid(),
        if (_selectedPkg != null) _buildPriceDisplay(),
      ],
    );
  }

  Widget _buildRegionSelector() {
    final regions = _getRegions();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: regions.map((r) {
          final isActive = r == _selectedRegion;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _selectedRegion = r;
                  _selectedPkg = null;
                  widget.onPackageSelected(null);
                }),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isActive ? AppTheme.greenLight : null,
                  foregroundColor: isActive ? AppTheme.green : Colors.grey,
                  side: BorderSide(
                    color: isActive ? AppTheme.green : Colors.grey[300]!,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  AppConstants.regionNames[r] ?? r,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPackageGrid() {
    final pkgs = _filteredPkgs;
    if (pkgs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('لا توجد باقات', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pkgs.length,
      itemBuilder: (_, i) => _PkgTab(
        pkg: pkgs[i],
        isSelected: _selectedPkg == pkgs[i],
        onTap: () => _selectPkg(pkgs[i]),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    final fmt = NumberFormat('#,###', 'ar');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: fmt.format(_selectedPkg!.price),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.green,
                ),
              ),
              const TextSpan(
                text: ' أوقية موريتانية',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PkgTab extends StatelessWidget {
  final PackageModel pkg;
  final bool isSelected;
  final VoidCallback onTap;

  const _PkgTab({
    required this.pkg,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ar');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(isSelected ? 1.04 : 1.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.greenDark, AppTheme.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Theme.of(context).cardColor,
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.green.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pkg.amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: isSelected ? Colors.white : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fmt.format(pkg.price)} أوقية',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 10, color: AppTheme.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
