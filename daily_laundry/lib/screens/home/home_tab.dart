import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../new_order/new_order_screen.dart';
import '../order_detail/order_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Future<void> _makePhoneCall() async {
    String supportNumber = await ApiService.getSupportNumber();
    final Uri callUri = Uri(scheme: 'tel', path: supportNumber);

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch call");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _makePhoneCall,
        label: const Text("Need Help?"),
        icon: const Icon(Icons.call),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                // 🌈 HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8E2DE2),
                        Color(0xFF4A00E0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Hello 👋",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Your clothes deserve the best care!",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 🧺 SERVICES HEADING
                const Text(
                  'Our Services',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 🧺 NEW SMALL SERVICE CATEGORY UI
                _isLoadingServices
                    ? const Center(
                    child:
                    CircularProgressIndicator(color: Colors.purple))
                    : SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: _buildServiceCategory(
                          title: s['name'],
                          icon: Icons.local_laundry_service,
                          serviceId: s['id'],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // 📦 ACTIVE ORDERS
                const Text(
                  "Active Orders",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                const SizedBox(height: 30),

                // FOOTER
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_laundry_service,
                          size: 55, color: Colors.purple.shade300),
                      const SizedBox(height: 10),
                      Text(
                        "Your laundry, our responsibility 🧺",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⭐ NEW SMALL CATEGORY CARD (Like Screenshot)
  Widget _buildServiceCategory({
    required String title,
    required IconData icon,
    required String serviceId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewOrderScreen(userId: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 34,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ ACTIVE ORDER CARD
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String orderId = order['orderId'] ?? '';
    final String status = order['status'] ?? '';

    final String pickupDate = order['pickupDate'] != null
        ? DateFormat("dd MMM yyyy • hh:mm a")
        .format(DateTime.parse(order['pickupDate']))
        : "";

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
        statusColor = Colors.green;
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month,
                  color: Colors.deepPurple, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Pickup: $pickupDate",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ EMPTY ORDER PLACEHOLDER
  Widget _buildEmptyOrdersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined,
              size: 55, color: Colors.purple.shade300),
          const SizedBox(height: 10),
          Text(
            "No active orders",
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
