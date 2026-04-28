import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileCorner extends StatefulWidget {
  final Color borderPhoto;
  final Color bgPhoto;

  const ProfileCorner({
    super.key,
    this.borderPhoto = const Color(0xFF94DF0C),
    this.bgPhoto = const Color(0xFF013236)
  });

  @override
  State<ProfileCorner> createState() => _ProfileCornerState();
}


class _ProfileCornerState extends State<ProfileCorner>{

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
            color: widget.bgPhoto,
            shape: BoxShape.circle,
            border: Border.all(
                width: 2,
                color: widget.borderPhoto
            )
        ),
        padding: EdgeInsets.all(12),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final initial = auth.nama.isNotEmpty ? auth.nama[0] : 'T';
            return Text(
              initial,
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20
              ),
            );
          },
        ),
      ),
    );
  }
}
