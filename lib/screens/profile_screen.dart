import 'dart:io';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:enviroo/screens/ubah_password_screen.dart';
import 'package:enviroo/services/profil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ─── Controllers ────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Daftar BSU untuk dropdown pemindahan
  final List<String> _daftarBsu = [
    "BSU Fakultas Teknik",
    "BSU Fakultas Ekonomi",
    "BSU Fakultas Hukum",
    "BSU Fakultas Kedokteran",
    "BSU Fakultas MIPA",
    "BSU Fakultas Ilmu Sosial",
  ];
  String? _selectedBsu;
  final _alasanController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  bool _isLoadingDetail = false;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _detailNasabah;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        _emailController.text = auth.nasabahProfile?.email ?? "";
        _fetchDetailNasabah(auth.identityId, auth.currentUser?.accessToken ?? "");
      } else if (auth.role.startsWith('petugas_')) {
        _emailController.text = auth.petugasProfile?.email ?? "";
      } else {
        _emailController.text = auth.currentUser?.email ?? "";
      }
    });
  }

  Future<void> _fetchDetailNasabah(String? nasabahId, String token) async {
    if (nasabahId == null) return;
    setState(() => _isLoadingDetail = true);
    try {
      final data = await ProfilService.getDetailNasabah(nasabahId, token);
      if (mounted) {
        setState(() {
          _detailNasabah = data;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetail = false);
      debugPrint("Gagal mengambil detail nasabah: $e");
    }
  }

  /// Bottom sheet: pilih antara Lihat Foto atau Ubah Foto
  void _showPhotoOptions() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String? photoUrl;
    String nama = auth.nama;
    if (auth.role == 'nasabah') {
      photoUrl = _detailNasabah?['photo_url'] ?? auth.nasabahProfile?.foto;
    } else if (auth.role.startsWith('petugas_')) {
      photoUrl = auth.petugasProfile?.photoUrl;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Foto Profil',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF013236),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF013236).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_search_rounded, color: Color(0xFF013236), size: 20),
                  ),
                  title: const Text(
                    'Lihat Foto',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LihatFotoScreen(photoUrl: photoUrl, nama: nama),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EA771).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF4EA771), size: 20),
                  ),
                  title: const Text(
                    'Ubah Foto',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Ambil gambar dari galeri lalu upload ke backend
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (pickedFile == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    final token = auth.currentUser?.accessToken ?? '';

    setState(() => _isUploadingPhoto = true);

    final result = await ProfilService.changePhotoProfile(userId, File(pickedFile.path), token);

    if (mounted) {
      setState(() {
        _isUploadingPhoto = false;
        if (result['success'] == true) {
          // Perbarui photo_url di _detailNasabah agar langsung tampil
          if (_detailNasabah != null) {
            _detailNasabah!['photo_url'] = result['photo_url'];
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] == true ? const Color(0xFF4EA771) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: "Profil"),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildCardProfile(),
                      if(auth.role == "nasabah") _buildAsosiasiCard(),
                      const SizedBox(height: 25),
                      if(auth.role == "nasabah") _buildInformasiPribadiSection(),
                      _buildPengaturanSection(),
                      const SizedBox(height: 30),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCardProfile() {
    final auth = context.read<AuthProvider>();
    
    Color borderColor = const Color(0xFF4EA771);
    if (auth.role == 'nasabah' && _detailNasabah != null) {
      final status = _detailNasabah!['status_nasabah']?.toString().toLowerCase();
      if (status == 'nonaktif') {
        borderColor = Colors.red;
      } else if (status == 'pending') {
        borderColor = Colors.orange;
      }
    }

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
            // ── Avatar (centered) ──
            GestureDetector(
              onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          String? photoUrl;
                          if (auth.role == 'nasabah') {
                            photoUrl = _detailNasabah?['photo_url'] ?? auth.nasabahProfile?.foto;
                          } else if (auth.role.startsWith('petugas_')) {
                            photoUrl = auth.petugasProfile?.photoUrl;
                          }

                          if (photoUrl != null && photoUrl.isNotEmpty) {
                            return Image.network(
                              photoUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                "assets/images/profile.png",
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Image.asset(
                            "assets/images/profile.png",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  // Upload loading overlay
                  if (_isUploadingPhoto)
                    Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Name ──
            Consumer<AuthProvider>(
              builder: (context, auth, _) => Text(
                auth.role == 'nasabah' && _detailNasabah != null 
                    ? (_detailNasabah!['nama'] ?? auth.nama) 
                    : auth.nama,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(height: 2),

            // ── Role ──
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                String roleText = 'Nasabah';
                if (auth.role == 'admin_bsu') {
                  roleText = 'Admin BSU';
                } else if (auth.role == 'petugas_bsi') {
                  roleText = 'Petugas BSI';
                } else if (auth.role == 'petugas_bsu') {
                  roleText = 'Petugas BSU';
                } else if (auth.role == 'petugas_bsm') {
                  roleText = 'Petugas BSM';
                }

                return Text(
                  roleText,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFFFFFFF),
                    fontSize: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // ── BSU badge ──
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
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        String bankName = '-';
                        if (auth.role == 'nasabah') {
                          bankName = _detailNasabah?['nama_bank'] ?? auth.nasabahProfile?.namaBsu ?? auth.nasabahProfile?.namaBsi ?? '-';
                        } else if (auth.role.startsWith('petugas_')) {
                          bankName = auth.petugasProfile?.namaBank ?? '-';
                        }

                        return Text(
                          bankName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF013236),
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
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

  // ═══════════════════════════════════════════════════════════════════
  // ─── Section: Informasi Asosiasi ─────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAsosiasiCard() {
    if (_detailNasabah == null) return const SizedBox.shrink();
    
    final isAdmin = _detailNasabah!['is_admin'] == true;
    if (!isAdmin) return const SizedBox.shrink();

    final role = _detailNasabah!['role_admin']?.toString() ?? '';
    final bankAdmin = _detailNasabah!['nama_bank_admin']?.toString() ?? '';
    final adminId = _detailNasabah!['admin_id']?.toString() ?? '';

    String roleDisplay = role;
    if (role == 'petugas_bsi') roleDisplay = 'Petugas BSI';
    else if (role == 'admin_bsi') roleDisplay = 'Admin BSI';
    else if (role == 'petugas_bsu') roleDisplay = 'Petugas BSU';
    else if (role == 'admin_bsu') roleDisplay = 'Admin BSU';
    else if (role == 'petugas_bsm') roleDisplay = 'Petugas BSM';
    else if (role == 'admin_bsm') roleDisplay = 'Admin BSM';
    else if (role == 'superadmin') roleDisplay = 'Superadmin';

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
          border: Border.all(color: const Color(0xFF4EA771).withOpacity(0.3)),
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
                    color: const Color(0xFF013236).withOpacity(0.8),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Akun Anda terasosiasi sebagai akun '),
                    TextSpan(
                      text: roleDisplay,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' di '),
                    TextSpan(
                      text: bankDisplay,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' dengan ID '),
                    TextSpan(
                      text: adminId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Section: Informasi Pribadi ─────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildInformasiPribadiSection() {
    if (_isLoadingDetail) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }
    
    if (_detailNasabah == null) {
      return const SizedBox.shrink();
    }

    String joinedAtStr = '-';
    if (_detailNasabah!['joined_at'] != null) {
      try {
        final dt = DateTime.parse(_detailNasabah!['joined_at'].toString().replaceAll(' ', 'T'));
        joinedAtStr = DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    return Column(
      children: [
        _buildSectionContainer(
          icon: CupertinoIcons.person_solid,
          iconBgColor: const Color(0xFF013236),
          title: "Informasi Pribadi",
          children: [
            _buildInfoRow("NIK", _detailNasabah!['user_id'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow("Email", _detailNasabah!['email'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow("Nomor WhatsApp", _detailNasabah!['no_whatsapp'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow("Nomor Rekening", _detailNasabah!['nomor_rekening'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow("Bergabung Sejak", joinedAtStr),
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
            color: const Color(0xFF013236).withOpacity(0.5),
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

  // ═══════════════════════════════════════════════════════════════════
  // ─── Section: Pengaturan ───────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPengaturanSection() {
    return _buildSectionContainer(
      icon: CupertinoIcons.settings_solid,
      iconBgColor: const Color(0xFF013236),
      title: "Pengaturan",
      children: [
        _buildListMenuTile(
          icon: CupertinoIcons.lock_fill,
          title: "Ubah Password",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UbahPasswordScreen(),
              ),
            );
          },
        ),
        _buildListMenuTile(
          icon: CupertinoIcons.doc_text_fill,
          title: "Log Aktivasi Akun",
          hideDivider: true,
          onTap: () {
            // TODO: Navigate to Log Aktivasi Akun
          },
        ),
      ],
    );
  }

  Widget _buildListMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool hideDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4EA771).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF4EA771)),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF013236),
                  ),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: const Color(0xFF013236).withOpacity(0.4),
                ),
              ],
            ),
          ),
          if (!hideDivider)
            Divider(
              color: const Color(0xFF013236).withOpacity(0.08),
              height: 1,
              thickness: 0.5,
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: _buildActionButton(
        label: "Keluar dari Akun",
        bgColor: Colors.red.shade600,
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(fontFamily: 'Poppins')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
                (route) => false,
              );
            }
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Reusable: Section Container (iOS-style grouped card) ─────────
  // ═══════════════════════════════════════════════════════════════════
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
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            width: 1,
            color: Color(0xFF013236).withOpacity(0.1)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon + title
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
            // Thin divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                height: 0.5,
                color: const Color(0xFF013236).withValues(alpha: 0.08),
              ),
            ),
            // Body content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Reusable: Styled TextField ───────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF013236).withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF4EA771).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF013236),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withValues(alpha: 0.35),
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  prefixIcon,
                  size: 18,
                  color: const Color(0xFF4EA771),
                ),
              )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Reusable: Action Button ──────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    Color bgColor = const Color(0xFF013236),
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
