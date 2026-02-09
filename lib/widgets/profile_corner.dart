import 'package:flutter/material.dart';

class ProfileCorner extends StatefulWidget{
  @override
  State<ProfileCorner> createState() => _ProfileCornerState();
}

class _ProfileCornerState extends State<ProfileCorner>{
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF06C0C9),
          shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: Color(0xFF4EA771)
        )
      ),
      padding: EdgeInsets.all(12),
      child: Text(
        "R",
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
      ),
    );
  }
}
