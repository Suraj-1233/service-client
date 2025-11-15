import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../new_order/new_order_screen.dart';
import '../order_detail/order_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<dynamic> _services = [];
  List<dynamic> _activeOrders = [];
  bool _isLoadingServices = true;
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchActiveOrders();
  }

  Future<void> _fetchServices() async {
    try {
      final data = await ApiService.getServices();
      setState(() {
        _services = data;
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _fetchActiveOrders() async {
    try {
      final data = await ApiService.getActiveOrders(context);
      setState(() {
        _activeOrders = data;
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() => _isLoadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchServices();
            await _fetchActiveOrders();
          },
          color: Colors.purple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧾 Greeting Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Hello 👋\nYour clothes deserve the best care!',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🧺 Services Section
                const Text(
                  'Our Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _isLoadingServices
                    ? const Center(
                    child:
                    CircularProgressIndicator(color: Colors.purple))
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _services.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return _buildServiceCard(
                      title: s['name'],
                      description: s['description'],
                      serviceId: s['id'],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // 📦 Active Orders Section
                const Text(
                  'Active Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _isLoadingOrders
                    ? const Center(
                    child:
                    CircularProgressIndicator(color: Colors.purple))
                    : _activeOrders.isEmpty
                    ? _buildEmptyOrdersCard()
                    : Column(
                  children: _activeOrders
                      .map((order) => _buildOrderCard(order))
                      .toList(),
                ),

                const SizedBox(height: 40),

                // 🧺 Footer
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_laundry_service,
                          size: 60, color: Colors.purple[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Your laundry, our responsibility 🧺',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧺 Service Card (click → redirect to NewOrderScreen)
  Widget _buildServiceCard({
    required String title,
    required String description,
    required String serviceId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NewOrderScreen(userId: 1), // ✅ pass userId dynamically later
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 📦 Active Order Card (click → redirect to OrderDetailScreen)
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String orderId = order['orderId'] ?? '';
    final String status = order['status'] ?? '';
    final String pickupDate = order['pickupDate'] ?? '';

    Color statusColor;
    switch (status) {
      case 'PLACED':
        statusColor = Colors.orange;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        break;
      case 'READY':
        statusColor = Colors.purple;
        break;
      case 'OUT_FOR_DELIVERY':
        statusColor = Colors.teal;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderId,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Pickup: $pickupDate",
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // 📨 Empty Orders Placeholder
  Widget _buildEmptyOrdersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: Colors.purple[200]),
          const SizedBox(height: 8),
          Text("No active orders yet",
              style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        ],
      ),
    );
  }
}
