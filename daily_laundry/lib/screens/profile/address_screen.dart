import 'package:flutter/material.dart';
import 'package:daily_laundry/screens/address/address_model.dart';
import '../../api/api_service.dart';

class AddressScreen extends StatefulWidget {
  final Map<String, dynamic>? addressData; // null = new address

  const AddressScreen({this.addressData, Key? key}) : super(key: key);

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.addressData?['label'] ?? '');
    _addressController =
        TextEditingController(text: widget.addressData?['address'] ?? '');
    _cityController =
        TextEditingController(text: widget.addressData?['city'] ?? '');
    _pincodeController =
        TextEditingController(text: widget.addressData?['pincode'] ?? '');
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final addressJson = {
        "label": _labelController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "pincode": _pincodeController.text.trim(),
      };

      if (widget.addressData != null) {
        // Update existing address
        await ApiService.updateAddress(widget.addressData!['id'], addressJson as Address);
      } else {
        // Add new address
        await ApiService.addAddress(addressJson as Address);
      }

      Navigator.pop(context, true); // refresh previous screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Address saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save address: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.addressData != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Address" : "Add Address"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Label (Home/Work)", _labelController),
              _buildTextField("Address", _addressController),
              _buildTextField("City", _cityController),
              _buildTextField("Pincode", _pincodeController,
                  keyboard: TextInputType.number),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Update Address" : "Add Address",
                    style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.purple[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) =>
        (value == null || value.trim().isEmpty) ? "Please enter $label" : null,
      ),
    );
  }
}
