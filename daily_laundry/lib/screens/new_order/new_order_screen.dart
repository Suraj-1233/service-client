import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../address/address_model.dart';

class NewOrderScreen extends StatefulWidget {
  final int userId;
  const NewOrderScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _NewOrderScreenState createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _availableServices = [];
  List<Address> _userAddresses = [];
  Address? _selectedAddress;

  int _selectedServiceIndex = 0;

  // ✅ serviceId -> { itemId -> qty }
  final Map<String, Map<String, int>> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchUserAddress();
  }

  // ✅ Fetch services → items → price
  void _fetchServices() async {
    try {
      final data = await ApiService.getServicesWithItems(context);
      setState(() {
        _availableServices = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading services: $e")));
    }
  }

  // ✅ Fetch user addresses
  void _fetchUserAddress() async {
    try {
      final addresses = await ApiService.getAddresses(context);
      setState(() {
        _userAddresses = addresses;
        if (_userAddresses.isNotEmpty) _selectedAddress = _userAddresses.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to load address")));
    }
  }

  // ✅ Select pickup date
  void _selectPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 15)),
    );
    if (picked != null) setState(() => _pickupDate = picked);
  }

  // ✅ Select pickup time
  void _selectPickupTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _pickupTime = picked);
  }

  // ✅ Increase / Decrease Quantity
  void _increaseQty(String serviceId, String itemId) {
    setState(() {
      _itemQuantities.putIfAbsent(serviceId, () => {});
      _itemQuantities[serviceId]![itemId] =
          (_itemQuantities[serviceId]![itemId] ?? 0) + 1;
    });
  }

  void _decreaseQty(String serviceId, String itemId) {
    setState(() {
      if (_itemQuantities.containsKey(serviceId)) {
        final current = _itemQuantities[serviceId]![itemId] ?? 0;
        if (current > 0) {
          _itemQuantities[serviceId]![itemId] = current - 1;
        }
      }
    });
  }

  // ✅ Calculate total amount
  int _calculateTotal() {
    double total = 0;
    for (var service in _availableServices) {
      final serviceId = service['serviceId'];
      for (var item in service['items']) {
        final itemId = item['itemId'];
        final price = (item['price'] ?? 0).toDouble();
        final qty = _itemQuantities[serviceId]?[itemId]?.toDouble() ?? 0;
        total += price * qty;
      }
    }
    return total.toInt();
  }

  // ✅ Place Order
  void _placeOrder() async {
    if (_pickupDate == null ||
        _pickupTime == null ||
        _selectedAddress == null ||
        !_itemQuantities.values
            .any((serviceItems) => serviceItems.values.any((q) => q > 0))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final total = _calculateTotal();

    final orderData = {
      "pickupDate": DateFormat('yyyy-MM-dd').format(_pickupDate!),
      "pickupTime": _pickupTime!.format(context),
      "pickupAddressId": _selectedAddress?.id,
      "deliveryAddressId": _selectedAddress?.id,
      "note": _noteController.text,
      "services": _availableServices.map((service) {
        final serviceId = service['serviceId'];
        final selectedItems = (service['items'] as List)
            .where((i) => (_itemQuantities[serviceId]?[i['itemId']] ?? 0) > 0)
            .map((i) => {
          "id": i['itemId'],
          "name": i['itemName'],
          "quantity": _itemQuantities[serviceId]?[i['itemId']] ?? 0,
          "price": i['price']
        })
            .toList();

        return {
          "serviceId": serviceId,
          "serviceName": service['serviceName'],
          "items": selectedItems
        };
      }).where((s) => (s['items'] as List).isNotEmpty).toList(),
      "totalAmount": total.toDouble(),
      "status": "PLACED",
    };

    try {
      await ApiService.placeOrder(context,orderData);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")));

      setState(() {
        _pickupDate = null;
        _pickupTime = null;
        _noteController.clear();
        _itemQuantities.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule New Pickup'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Pickup Date & Time
            const Text("Pickup Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectPickupDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_pickupDate == null
                        ? "Select Date"
                        : DateFormat('dd MMM yyyy').format(_pickupDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectPickupTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_pickupTime == null
                        ? "Select Time"
                        : _pickupTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 Address
            const Text("Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _userAddresses.isEmpty
                ? const Text("No address found")
                : DropdownButton<Address>(
              isExpanded: true,
              value: _selectedAddress,
              items: _userAddresses.map((addr) {
                return DropdownMenuItem(
                  value: addr,
                  child: Text(
                      "${addr.label} - ${addr.address}, ${addr.city}"),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAddress = val),
            ),
            const SizedBox(height: 20),

            // 🔹 Services & Items
            const Text("Select Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _availableServices.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_availableServices.length,
                            (index) {
                          final service = _availableServices[index];
                          final isSelected =
                              index == _selectedServiceIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(service['serviceName']),
                              selected: isSelected,
                              selectedColor: Colors.purple,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setState(
                                      () => _selectedServiceIndex = index),
                            ),
                          );
                        }),
                  ),
                ),
                const SizedBox(height: 12),

                // Items for Selected Service
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                  (_availableServices[_selectedServiceIndex]['items']
                  as List)
                      .length,
                  itemBuilder: (context, index) {
                    final service =
                    _availableServices[_selectedServiceIndex];
                    final serviceId = service['serviceId'];
                    final item = service['items'][index];
                    final id = item['itemId'];
                    final name = item['itemName'];
                    final price = item['price'];
                    final qty =
                        _itemQuantities[serviceId]?[id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text("₹${price.toStringAsFixed(2)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              onPressed: qty > 0
                                  ? () =>
                                  _decreaseQty(serviceId, id)
                                  : null,
                            ),
                            Text('$qty',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline),
                              onPressed: () =>
                                  _increaseQty(serviceId, id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 Notes
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                  labelText: "Add a note (optional)",
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // 🔹 Total + Button
            Center(
              child: Column(
                children: [
                  Text("Total: ₹${_calculateTotal()}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 14),
                    ),
                    child: const Text("Place Order",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
