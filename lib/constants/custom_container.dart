import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomCard extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;

  const CustomCard({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.height = 120, // ✅ You can increase/decrease height
  });

  @override
  Widget build(BuildContext context) {
    return  Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // shadow color
                blurRadius: 8, // how soft the shadow is
                spreadRadius: 2, // how wide the shadow spreads
                offset: const Offset(2, 4), // (x, y) — move right & down
              ),
            ],
            border: Border.all(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text("Conatiner !"),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
