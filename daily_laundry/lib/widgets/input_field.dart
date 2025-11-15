import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final bool obscure;
  final TextEditingController controller;

  InputField({required this.label, this.obscure = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
