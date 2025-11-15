import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String item;
  final String service;
  final String price;
  final String quantity; // ✅ new field

  const OrderItemCard({
    Key? key,
    required this.item,
    required this.service,
    required this.price,
    required this.quantity, // ✅ added here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '$service • Qty: $quantity', // ✅ quantity shown inline
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          // Right section (price)
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
