import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/services/profil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailProfilNasabahScreen extends StatefulWidget {
  final String nasabahId;
  const DetailProfilNasabahScreen({super.key, required this.nasabahId});

  @override
  State<DetailProfilNasabahScreen> createState() => _DetailProfilNasabahScreenState();
}

class _DetailProfilNasabahScreenState extends State<DetailProfilNasabahScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await ProfilService.getDetailNasabah(widget.nasabahId);
      if (mounted) setState(() { _detail = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_struk.webp',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              TopBarBack(title: "Profil Nasabah"),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                    : _error.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(_error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.red)),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _buildCardProfile(),
                                _buildAsosiasiCard(),
                                const SizedBox(height: 25),
                                _buildInformasiPribadiSection(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildCardProfile() {
    if (_detail == null) return const SizedBox.shrink();

    final status = _detail!['status_nasabah']?.toString().toLowerCase() ?? '';
    Color borderColor = const Color(0xFF4EA771);
    if (status == 'nonaktif') {
      borderColor = Colors.red;
    } else if (status == 'pending') {
      borderColor = Colors.orange;
    }

    final photoUrl = _detail!['photo_url']?.toString() ?? '';
    final nama = _detail!['nama']?.toString() ?? '-';
    final namaBank = _detail!['nama_bank']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LihatFotoScreen(photoUrl: photoUrl.isNotEmpty ? photoUrl : null, nama: nama),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: ClipOval(
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/profile.png',
                            width: 100, height: 100, fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/profile.png',
                          width: 100, height: 100, fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              nama,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Nasabah',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF94DF0C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF013236)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      namaBank,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF013236),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildAsosiasiCard() {
    if (_detail == null) return const SizedBox.shrink();

    final isAdmin = _detail!['is_admin'] == true;
    if (!isAdmin) return const SizedBox.shrink();

    final role = _detail!['role_admin']?.toString() ?? '';
    final bankAdmin = _detail!['nama_bank_admin']?.toString() ?? '';
    final adminId = _detail!['admin_id']?.toString() ?? '';

    String roleDisplay = role;
    if (role == 'petugas_bsi') {
      roleDisplay = 'Petugas BSI';
    } else if (role == 'admin_bsi') {
      roleDisplay = 'Admin BSI';
    } else if (role == 'petugas_bsu') {
      roleDisplay = 'Petugas BSU';
    } else if (role == 'admin_bsu') {
      roleDisplay = 'Admin BSU';
    } else if (role == 'petugas_bsm') {
      roleDisplay = 'Petugas BSM';
    } else if (role == 'admin_bsm') {
      roleDisplay = 'Admin BSM';
    } else if (role == 'superadmin') {
      roleDisplay = 'Superadmin';
    }

    String bankDisplay = bankAdmin;
    if (role == 'superadmin' || bankDisplay.isEmpty) {
      bankDisplay = 'Dinas Lingkungan Hidup Kota Padang';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFBF0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4EA771).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4EA771), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: const Color(0xFF013236).withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Akun ini juga terasosiasi sebagai akun '),
                    TextSpan(text: roleDisplay, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' di '),
                    TextSpan(text: bankDisplay, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' dengan ID '),
                    TextSpan(text: adminId, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformasiPribadiSection() {
    if (_detail == null) return const SizedBox.shrink();

    String joinedAtStr = '-';
    if (_detail!['joined_at'] != null) {
      try {
        final dt = DateTime.parse(_detail!['joined_at'].toString().replaceAll(' ', 'T'));
        joinedAtStr = DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    return Column(
      children: [
        _buildSectionContainer(
          icon: CupertinoIcons.person_solid,
          iconBgColor: const Color(0xFF013236),
          title: 'Informasi Pribadi',
          children: [
            _buildInfoRow('NIK', _detail!['user_id']?.toString() ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Email', _detail!['email']?.toString() ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Nomor WhatsApp', _detail!['no_whatsapp']?.toString() ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Nomor Rekening', _detail!['nomor_rekening']?.toString() ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Status', _detail!['status_nasabah']?.toString() ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Bergabung Sejak', joinedAtStr),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: const Color(0xFF013236).withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF013236),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContainer({
    required IconData icon,
    required Color iconBgColor,
    Color iconColor = Colors.white,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(width: 1, color: const Color(0xFF013236).withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF013236),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(height: 0.5, color: const Color(0xFF013236).withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ],
        ),
      ),
    );
  }
}
