import 'package:flutter/material.dart';

class OrderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  OrderTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }
}
