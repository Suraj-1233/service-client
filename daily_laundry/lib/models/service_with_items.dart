class ServiceWithItems {
  final String serviceId;
  final String serviceName;
  final List<ItemWithPrice> items;

  ServiceWithItems({
    required this.serviceId,
    required this.serviceName,
    required this.items,
  });

  factory ServiceWithItems.fromJson(Map<String, dynamic> json) {
    return ServiceWithItems(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      items: (json['items'] as List)
          .map((e) => ItemWithPrice.fromJson(e))
          .toList(),
    );
  }
}

class ItemWithPrice {
  final String itemId;
  final String itemName;
  final double price;

  ItemWithPrice({
    required this.itemId,
    required this.itemName,
    required this.price,
  });

  factory ItemWithPrice.fromJson(Map<String, dynamic> json) {
    return ItemWithPrice(
      itemId: json['itemId'],
      itemName: json['itemName'],
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
