import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import 'add_edit_address_screen.dart';
import 'address_model.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({Key? key}) : super(key: key);

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Address> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAddresses(context);
      setState(() {
        addresses = data; // Already List<Address> from ApiService
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load addresses")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Addresses"),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? Center(child: Text("No addresses found"))
          : ListView.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final addr = addresses[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(addr.label),
              subtitle:
              Text("${addr.address}, ${addr.city} - ${addr.pincode}"),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Colors.purple),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditAddressScreen(address: addr),
                    ),
                  );
                  if (updated == true) fetchAddresses();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditAddressScreen(),
            ),
          );
          if (added == true) fetchAddresses();
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }
}
