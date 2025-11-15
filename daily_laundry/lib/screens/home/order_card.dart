import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final String date;

  OrderCard({required this.orderId, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Order #$orderId'),
        subtitle: Text('Status: $status\nDate: $date'),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {},
      ),
    );
  }
}
