import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/profil_provider.dart';
import 'package:enviroo/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Avatar bulat di pojok `TopBarCustom`, tampil di semua beranda.
///
/// Fotonya diambil lewat [ProfilProvider.fetchActiveUser], bukan memanggil
/// service langsung. Pemicu ambil-ulangnya `AuthProvider.profilePhotoVersion`,
/// yang dinaikkan `edit_profil_screen` sesudah foto berhasil diganti.
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
  AuthProvider? _auth;
  int _lastPhotoVersion = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      _auth = auth;
      _lastPhotoVersion = auth.profilePhotoVersion;
      auth.addListener(_onPhotoVersionChanged);

      if (auth.userId.isNotEmpty) {
        context.read<ProfilProvider>().fetchActiveUser(auth.userId);
      }
    });
  }

  @override
  void dispose() {
    _auth?.removeListener(_onPhotoVersionChanged);
    super.dispose();
  }

  /// Bandingkan versi, jangan sekadar "ada notifikasi": AuthProvider ber-notify
  /// untuk banyak hal lain (login, profil sesi, error), dan tidak satu pun dari
  /// itu boleh memicu ambil-ulang foto.
  void _onPhotoVersionChanged() {
    if (!mounted || _auth == null) return;
    final versi = _auth!.profilePhotoVersion;
    if (versi == _lastPhotoVersion) return;
    _lastPhotoVersion = versi;

    if (_auth!.userId.isEmpty) return;
    // paksa: foto memang baru berubah, jadi cache-nya yang harus dibuang.
    context.read<ProfilProvider>().fetchActiveUser(_auth!.userId, paksa: true);
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
        child: Consumer<ProfilProvider>(
          builder: (context, prov, _) {
            final photoUrl = prov.activeUser?['photo_url'] as String?;

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
