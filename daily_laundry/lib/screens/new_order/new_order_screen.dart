import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../api/api_service.dart';
import '../address/address_model.dart';
import '../address/address_list_screen.dart';

class NewOrderScreen extends StatefulWidget {
  final int userId;
  const NewOrderScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _services = [];
  List<Address> _addresses = [];
  Address? _selectedAddress;

  int _selectedServiceIndex = 0;

  // serviceId -> Map<itemId, qty>
  final Map<String, Map<String, int>> _itemQty = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchAddresses();
  }

  // --------------------------
  // Fetching Data
  // --------------------------

  Future<void> _fetchServices() async {
    try {
      final data = await ApiService.getServicesWithItems(context);
      setState(() => _services = List<Map<String, dynamic>>.from(data));

      if (_selectedServiceIndex >= _services.length) {
        _selectedServiceIndex = 0;
      }
    } catch (e) {}
  }

  Future<void> _fetchAddresses() async {
    try {
      final data = await ApiService.getAddresses(context);
      setState(() {
        _addresses = data;
        if (_selectedAddress == null && _addresses.isNotEmpty) {
          _selectedAddress = _addresses.first;
        }
      });
    } catch (e) {}
  }

  // --------------------------
  // Total Calculation
  // --------------------------

  int _calculateTotal() {
    double total = 0;
    for (var service in _services) {
      final sId = service["serviceId"];
      final items = service["items"] as List;

      for (var item in items) {
        final iId = item["itemId"];
        final qty = _itemQty[sId]?[iId] ?? 0;
        final price = (item["price"] ?? 0).toDouble();

        total += qty * price;
      }
    }
    return total.toInt();
  }

  // --------------------------
  // Place Order (Toast + Reset only)
  // --------------------------

  Future<void> _placeOrder() async {
    if (_pickupDate == null ||
        _pickupTime == null ||
        _selectedAddress == null ||
        !_itemQty.values.any((m) => m.values.any((q) => q > 0))) {
      Fluttertoast.showToast(
        msg: "Please fill all fields",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final order = {
      "pickupDate": DateFormat("yyyy-MM-dd").format(_pickupDate!),
      "pickupTime": _pickupTime!.format(context),
      "pickupAddressId": _selectedAddress!.id,
      "deliveryAddressId": _selectedAddress!.id,
      "note": _noteController.text,
      "totalAmount": _calculateTotal(),
      "status": "PLACED",

      "services": _services.map((service) {
        final sId = service["serviceId"];

        final selectedItems = (service["items"] as List)
            .where((item) => (_itemQty[sId]?[item["itemId"]] ?? 0) > 0)
            .map((item) {
          final iId = item["itemId"];
          return {
            "id": item["itemId"],
            "name": item["itemName"],
            "quantity": _itemQty[sId]?[iId] ?? 0,
            "price": item["price"]
          };
        }).toList();

        return {
          "serviceId": sId,
          "serviceName": service["serviceName"],
          "items": selectedItems
        };
      }).where((s) => (s["items"] as List).isNotEmpty).toList()
    };

    try {
      await ApiService.placeOrder(context, order);

      Fluttertoast.showToast(
        msg: "Order Placed Successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // ❗ Reset only Inputs — UI stays same
      setState(() {
        _pickupDate = null;
        _pickupTime = null;
        _noteController.clear();
        _itemQty.clear();
      });

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Order failed! Try again.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // --------------------------
  // Qty Controls
  // --------------------------

  void _increaseQty(String sId, String iId) {
    _itemQty.putIfAbsent(sId, () => {});
    _itemQty[sId]![iId] = (_itemQty[sId]![iId] ?? 0) + 1;
    setState(() {});
  }

  void _decreaseQty(String sId, String iId) {
    if ((_itemQty[sId]?[iId] ?? 0) > 0) {
      _itemQty[sId]![iId] = _itemQty[sId]![iId]! - 1;
      setState(() {});
    }
  }

  // --------------------------
  // UI Widgets — UNCHANGED
  // --------------------------

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
          color: Colors.black12.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3))
    ],
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 15)),
    );
    if (d != null) setState(() => _pickupDate = d);
  }

  Future<void> _selectTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => _pickupTime = t);
  }

  // --------------------------
  // BUILD UI
  // --------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Schedule Pickup"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      bottomNavigationBar: _bottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Pickup Details"),
            _pickupSection(),
            const SizedBox(height: 25),
            _sectionTitle("Address"),
            _addresses.isEmpty ? _noAddressCard() : _addressCard(),
            const SizedBox(height: 25),
            _sectionTitle("Select Items"),
            _serviceTabs(),
            const SizedBox(height: 16),
            _itemList(),
            const SizedBox(height: 25),
            _sectionTitle("Note (optional)"),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration("Add a note"),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------
  // Bottom Bar
  // --------------------------
  bool _isPlacingOrder = false;

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              blurRadius: 8, color: Colors.black12, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Total: ₹${_calculateTotal()}",
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _isPlacingOrder ? null : _handleOrderButton,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text("Place Order"),          )
        ],
      ),
    );
  }

  // --------------------------
  // Pickup Section
  // --------------------------

  Widget _pickupSection() {
    return Row(
      children: [
        _dateTimeCard(
          label: _pickupDate == null
              ? "Select Date"
              : DateFormat("dd MMM").format(_pickupDate!),
          icon: Icons.calendar_month,
          onTap: _selectDate,
        ),
        const SizedBox(width: 12),
        _dateTimeCard(
          label: _pickupTime == null
              ? "Select Time"
              : _pickupTime!.format(context),
          icon: Icons.access_time_filled,
          onTap: _selectTime,
        ),
      ],
    );
  }

  Widget _dateTimeCard(
      {required String label,
        required IconData icon,
        required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------
  // Address Widgets
  // --------------------------

  Widget _noAddressCard() {
    return Column(
      children: [
        const Text("No address found",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressListScreen()),
            );

            if (result is Address) {
              setState(() => _selectedAddress = result);
              _fetchAddresses();
            } else if (result == true) {
              _fetchAddresses();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            padding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: const Text("Add Address"),
        )
      ],
    );
  }

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.purple, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${_selectedAddress!.label}: ${_selectedAddress!.address}, ${_selectedAddress!.city}",
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressListScreen()),
              );

              if (result is Address) {
                setState(() => _selectedAddress = result);
              } else if (result == true) {
                _fetchAddresses();
              }
            },
            child: const Text("Change"),
          )
        ],
      ),
    );
  }

  // --------------------------
  // Service Tabs
  // --------------------------

  Widget _serviceTabs() {
    if (_services.isEmpty) {
      return const Center(child: Text("No services available"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_services.length, (index) {
          final isSelected = index == _selectedServiceIndex;
          final name = _services[index]["serviceName"];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              selectedColor: Colors.purple,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) =>
                  setState(() => _selectedServiceIndex = index),
            ),
          );
        }),
      ),
    );
  }

  // --------------------------
  // Items List
  // --------------------------

  Widget _itemList() {
    if (_services.isEmpty) return const SizedBox.shrink();

    final items = _services[_selectedServiceIndex]["items"] as List;
    if (items.isEmpty) return const Text("No items in this service");

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final sId = _services[_selectedServiceIndex]["serviceId"];
        final iId = item["itemId"];
        final qty = _itemQty[sId]?[iId] ?? 0;
        final price = item["price"];

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              // Item Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["itemName"],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("₹$price",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              // Qty Controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: qty > 0 ? () => _decreaseQty(sId, iId) : null,
                  ),
                  Text("$qty", style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _increaseQty(sId, iId),
                  ),
                ],
              )
            ],
          ),
        );
      }),
    );
  }


  void _handleOrderButton() async {
    setState(() => _isPlacingOrder = true);

    await _placeOrder(); // your existing API call

    setState(() => _isPlacingOrder = false);
  }
}
