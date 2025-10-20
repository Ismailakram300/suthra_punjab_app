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
    this.height = 80, // ✅ You can increase/decrease height
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
           // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.menu, size: 30),
              SizedBox(width: 25),
              Text(title,style: TextStyle(fontSize: 19,color: Colors.white, fontWeight: FontWeight.bold),),
              SizedBox(width: 25),
              Icon(Icons.logout, size: 27),
              //SizedBox(width: 5),
            //  SizedBox(width: 55),

            ],
          ),

        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
