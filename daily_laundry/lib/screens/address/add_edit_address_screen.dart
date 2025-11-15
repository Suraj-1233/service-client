import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import 'address_model.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  const AddEditAddressScreen({this.address, Key? key}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _mobileController;
  late TextEditingController _flatBuildingController;
  late TextEditingController _areaStreetController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  String _selectedType = "Home";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _fullNameController =
        TextEditingController(text: widget.address?.fullName ?? "");
    _mobileController =
        TextEditingController(text: widget.address?.mobileNumber ?? "");
    _flatBuildingController =
        TextEditingController(text: widget.address?.flatBuilding ?? "");
    _areaStreetController =
        TextEditingController(text: widget.address?.areaStreet ?? "");
    _cityController = TextEditingController(text: widget.address?.city ?? "");
    _pincodeController =
        TextEditingController(text: widget.address?.pincode ?? "");
    _selectedType = widget.address?.label ?? "Home";
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newAddress = Address(
      id: widget.address?.id,
      fullName: _fullNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(), // ✅ fixed name
      flatBuilding: _flatBuildingController.text.trim(),
      areaStreet: _areaStreetController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      label: _selectedType,
    );

    try {
      if (widget.address != null) {
        await ApiService.updateAddress(widget.address!.id!, newAddress);
      } else {
        await ApiService.addAddress(newAddress);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address saved successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save address: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address != null ? "Edit Address" : "Add New Address"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Full Name", _fullNameController),
              _buildTextField("Mobile Number", _mobileController,
                  keyboard: TextInputType.phone),
              _buildTextField(
                  "Flat / House No. / Building Name", _flatBuildingController),
              _buildTextField("Street / Area / Landmark", _areaStreetController),
              _buildTextField("City", _cityController),
              _buildTextField("Pincode", _pincodeController,
                  keyboard: TextInputType.number),
              const SizedBox(height: 10),
              _buildAddressTypeSelector(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Address",
                  style: TextStyle(fontSize: 18),
                ),
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
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ["Home", "Work", "Other"].map((type) {
        final bool isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          selectedColor: Colors.purple,
          backgroundColor: Colors.purple[100],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (selected) {
            setState(() => _selectedType = type);
          },
        );
      }).toList(),
    );
  }
}
