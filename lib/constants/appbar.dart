import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomContainerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;

  const CustomContainerAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.height = 120, // ✅ You can increase/decrease height
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   colors: [AppColors.primary, AppColors.secondary],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(
          //bottom: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
      //      mainAxisAlignment: MainAxisAlignment.spaceBetween,
           // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.menu, size: 35),
              SizedBox(width: 25),
              Icon(Icons.location_history, size: 27),
              SizedBox(width: 5),

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current tehsil",
                    style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Chakwal",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(width: 55),

            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
