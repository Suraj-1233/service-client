import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../widgets/order_item_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId, Key? key}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final data = await ApiService.getOrderDetails(context,widget.orderId);
      setState(() {
        _orderDetails = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load order details.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _buildOrderDetailView(),
    );
  }

  Widget _buildOrderDetailView() {
    final List<dynamic> items = _orderDetails?['services'] ?? [];
    final total = _orderDetails?['totalAmount'] ?? 0.0;
    final status = _orderDetails?['status'] ?? 'Unknown';
    final orderId = _orderDetails?['id'] ?? 'N/A';
    final pickupDate = _orderDetails?['pickupDate'] ?? '';
    final createdAt = _orderDetails?['createdAt'] ?? '';

    String formattedDate = createdAt.isNotEmpty
        ? DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(createdAt).toLocal())
        : 'N/A';
    String formattedPickupDate = pickupDate.isNotEmpty
        ? DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(pickupDate).toLocal())
        : 'N/A';

    // 🔄 Transform items into grouped map: { serviceName: [item1, item2, ...] }
    final Map<String, List<Map<String, dynamic>>> groupedByService = {};

    for (var item in items) {
      final List<dynamic> services = item['services'] ?? [];
      for (var service in services) {
        final String serviceName = service['serviceName'] ?? 'Unknown Service';
        final double price = service['price'] ?? 0.0;
        final entry = {
          'itemName': item['name'] ?? 'Unknown Item',
          'quantity': item['quantity'] ?? 1,
          'price': price,
        };

        groupedByService.putIfAbsent(serviceName, () => []).add(entry);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧾 Header
          Text(
            'Order ID: $orderId',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Created On: $formattedDate',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Pickup Date: $formattedPickupDate',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Status: $status',
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 🧩 Service-Grouped Items
          const Text(
            'Services:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: groupedByService.isEmpty
                ? const Center(child: Text("No services found"))
                : ListView(
              children: groupedByService.entries.map((entry) {
                final String serviceName = entry.key;
                final List<Map<String, dynamic>> serviceItems = entry.value;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🧺 Service name (e.g., Wash & Fold)
                        Text(
                          '🧺 $serviceName',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Items under that service
                        ...serviceItems.map((item) {
                          final name = item['itemName'];
                          final qty = item['quantity'];
                          final price = item['price'];
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 4.0),
                            child: OrderItemCard(
                              item: name,
                              service: "x$qty",
                              price: '₹${price.toStringAsFixed(2)}',
                              quantity: qty.toString(),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 💰 Total Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
