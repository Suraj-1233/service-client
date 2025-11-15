import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final String offer;
  final VoidCallback? onTap;

  OfferCard({required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            offer,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900]),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
