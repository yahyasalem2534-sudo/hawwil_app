class PackageModel {
  final String amount;
  final double price;
  final String? region;

  PackageModel({
    required this.amount,
    required this.price,
    this.region,
  });

  factory PackageModel.fromMap(Map<String, dynamic> data) {
    return PackageModel(
      amount: data['amount']?.toString() ?? '',
      price: (data['price'] ?? 0).toDouble(),
      region: data['region'],
    );
  }
}

class GameModel {
  final String id;
  final String name;
  final String? logo;
  final String? icon;
  final String? bg;
  final String? desc;
  final String? badge;
  final String? provider;
  final String? productType; // 'game' | 'service'
  final bool isGlobal;
  final List<PackageModel> pkgs;
  final int order;

  GameModel({
    required this.id,
    required this.name,
    this.logo,
    this.icon,
    this.bg,
    this.desc,
    this.badge,
    this.provider,
    this.productType,
    this.isGlobal = true,
    required this.pkgs,
    required this.order,
  });

  bool get isService => productType == 'service';
  bool get isRegional => isGlobal == false && pkgs.any((p) => p.region != null);

  factory GameModel.fromFirestore(Map<String, dynamic> data, String id) {
    final pkgList = (data['pkgs'] as List<dynamic>? ?? [])
        .map((p) => PackageModel.fromMap(p as Map<String, dynamic>))
        .toList();

    return GameModel(
      id: id,
      name: data['name'] ?? '',
      logo: data['logo'],
      icon: data['icon'],
      bg: data['bg'],
      desc: data['desc'],
      badge: data['badge'],
      provider: data['provider'],
      productType: data['productType'],
      isGlobal: data['isGlobal'] ?? true,
      pkgs: pkgList,
      order: data['order'] ?? 0,
    );
  }
}
