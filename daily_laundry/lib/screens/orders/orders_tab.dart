import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../order_detail/order_detail_screen.dart';

class OrdersTab extends StatefulWidget {
  final String? selectedOrderId;
  final String userId;

  const OrdersTab({this.selectedOrderId, required this.userId, Key? key})
      : super(key: key);

  @override
  _OrdersTabState createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.getUserOrders();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedOrderId != null) {
      return OrderDetailScreen(orderId: widget.selectedOrderId!);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        final orders = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = order['id'] ?? 'N/A';
            final status = order['status'] ?? 'Unknown';
            final total = order['totalAmount'] ?? 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                title: Text('Order #$orderId'),
                subtitle: Text('Status: $status\nTotal: ₹$total'),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: orderId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
