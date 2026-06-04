import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/profile_screen.dart';
import 'package:enviroo/services/user_service.dart';
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
  Future<Map<String, dynamic>?>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId.isNotEmpty) {
        setState(() {
          _userDataFuture = UserService.getActiveUser(auth.userId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                width: 2,
                color: widget.borderPhoto
            )
        ),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (_userDataFuture == null && auth.userId.isNotEmpty) {
              _userDataFuture = UserService.getActiveUser(auth.userId);
            }
            return FutureBuilder<Map<String, dynamic>?>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  photoUrl = snapshot.data?['photo_url'];
                }

                if (photoUrl != null && photoUrl.isNotEmpty) {
                  return ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultPhoto(),
                    ),
                  );
                }

                return _buildDefaultPhoto();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultPhoto() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile.png',
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if profile.png is missing
          return Container(
            width: 38,
            height: 38,
            color: widget.bgPhoto,
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          );
        },
      ),
    );
  }
}
