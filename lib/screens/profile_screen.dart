import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/detail_petugas_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/petugas/home_bsi_screen.dart';
import 'package:enviroo/screens/petugas/home_bsm_screen.dart';
import 'package:enviroo/screens/petugas/home_bsu_screen.dart';
import 'package:enviroo/screens/edit_profil_screen.dart';
import 'package:enviroo/screens/nasabah/home_screen.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:enviroo/screens/log_akun_screen.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/screens/splash_screen.dart';
import 'package:enviroo/screens/ubah_password_screen.dart';
import 'package:enviroo/providers/profil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
  Map<String, dynamic>? _detailNasabah;
  DetailPetugasModel? _detailPetugas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        _emailController.text = auth.nasabahProfile?.email ?? '';
        _fetchDetailNasabah(auth.identityId);
      } else if (auth.role.startsWith('petugas_')) {
        _emailController.text = auth.petugasProfile?.email ?? '';
        _fetchDetailPetugas(auth.identityId);
      } else {
        _emailController.text = auth.currentUser?.email ?? '';
      }
    });
  }

  Future<void> _fetchDetailNasabah(String? nasabahId) async {
    if (nasabahId == null) return;
    setState(() => _isLoadingDetail = true);
    final prov = context.read<ProfilProvider>();
    await prov.fetchNasabah(nasabahId);
    if (!mounted) return;
    if (prov.nasabahStatus == FetchStatus.success) {
      setState(() {
        _detailNasabah = prov.nasabah;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
      debugPrint('Gagal mengambil detail nasabah: ${prov.nasabahError}');
    }
  }

  Future<void> _fetchDetailPetugas(String? petugasId) async {
    if (petugasId == null) return;
    setState(() => _isLoadingDetail = true);
    final prov = context.read<ProfilProvider>();
    await prov.fetchPetugas(petugasId);
    if (!mounted) return;
    if (prov.petugasStatus == FetchStatus.success) {
      setState(() {
        _detailPetugas = prov.petugas;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
      debugPrint('Gagal mengambil detail petugas: ${prov.petugasError}');
    }
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

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
                TopBarBack(title: "Profil", onBack: widget.onBack),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildCardProfile(),
                        if (auth.role == 'nasabah') _buildAsosiasiCard(),
                        if (auth.role.startsWith('petugas_')) _buildAsosiasiCardPetugas(),
                        const SizedBox(height: 25),
                        if (auth.role == 'nasabah') _buildInformasiPribadiSection(),
                        if (auth.role.startsWith('petugas_')) _buildInformasiPribadiPetugas(),
                        _buildPengaturanSection(),
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
    final auth = context.read<AuthProvider>();
    
    Color borderColor = AppColors.green;
    if (auth.role == 'nasabah' && _detailNasabah != null) {
      final status = _detailNasabah!['status_nasabah']?.toString().toLowerCase();
      if (status == 'nonaktif') {
        borderColor = Colors.red;
      } else if (status == 'pending') {
        borderColor = Colors.orange;
      }
    } else if (auth.role.startsWith('petugas_') && _detailPetugas != null) {
      final status = _detailPetugas!.statusPetugas.toLowerCase();
      if (status == 'nonaktif') borderColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                final auth = context.read<AuthProvider>();
                String? photoUrl;
                if (auth.role == 'nasabah') {
                  photoUrl = _detailNasabah?['photo_url'] ?? auth.nasabahProfile?.foto;
                } else if (auth.role.startsWith('petugas_')) {
                  photoUrl = _detailPetugas?.photoUrl ?? auth.petugasProfile?.photoUrl;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LihatFotoScreen(photoUrl: photoUrl, nama: auth.nama),
                  ),
                );
              },
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  String? photoUrl;
                  if (auth.role == 'nasabah') {
                    photoUrl = _detailNasabah?['photo_url'] ?? auth.nasabahProfile?.foto;
                  } else if (auth.role.startsWith('petugas_')) {
                    photoUrl = _detailPetugas?.photoUrl ?? auth.petugasProfile?.photoUrl;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 3),
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              width: 100, height: 100, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                "assets/images/profile.png",
                                width: 100, height: 100, fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              "assets/images/profile.png",
                              width: 100, height: 100, fit: BoxFit.cover,
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            Consumer<AuthProvider>(
              builder: (context, auth, _) => Text(
                auth.role == 'nasabah' && _detailNasabah != null
                    ? (_detailNasabah!['nama'] ?? auth.nama)
                    : auth.role.startsWith('petugas_') && _detailPetugas != null
                        ? _detailPetugas!.nama
                        : auth.nama,
                style: AppText.w700(17, Colors.white),
              ),
            ),
            const SizedBox(height: 2),

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
                  style: AppText.r(12, Colors.white),
                );
              },
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neon,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.dark),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        String bankName = '-';
                        if (auth.role == 'nasabah') {
                          bankName = _detailNasabah?['nama_bank'] ?? auth.nasabahProfile?.namaBsu ?? auth.nasabahProfile?.namaBsi ?? '-';
                        } else if (auth.role.startsWith('petugas_')) {
                          bankName = _detailPetugas?.namaBank ?? auth.petugasProfile?.namaBank ?? '-';
                        }

                        return Text(
                          bankName,
                          style: AppText.w600(10, AppColors.dark),
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
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: AppColors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppText.p(10, color: AppColors.dark.withValues(alpha: 0.8), height: 1.6),
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

  Widget _buildAsosiasiCardPetugas() {
    if (_detailPetugas == null || !_detailPetugas!.isNasabah) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFBF0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_pin_rounded, color: AppColors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppText.p(10, color: AppColors.dark.withValues(alpha: 0.8), height: 1.6),
                  children: [
                    const TextSpan(text: 'Akun Anda juga terdaftar sebagai '),
                    const TextSpan(
                      text: 'Nasabah',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' di '),
                    TextSpan(
                      text: _detailPetugas!.namaBankNasabah.isNotEmpty
                          ? _detailPetugas!.namaBankNasabah
                          : '-',
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

  Widget _buildInformasiPribadiPetugas() {
    if (_isLoadingDetail) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      );
    }

    if (_detailPetugas == null) return const SizedBox.shrink();

    final joinedAtStr = _detailPetugas!.joinedAt != null
        ? AppDate.tanggalPanjang(_detailPetugas!.joinedAt!)
        : '-';

    return Column(
      children: [
        _buildSectionContainer(
          icon: CupertinoIcons.person_solid,
          iconBgColor: AppColors.dark,
          title: 'Informasi Pribadi',
          children: [
            _buildInfoRow('ID Petugas', _detailPetugas!.petugasId.isNotEmpty ? _detailPetugas!.petugasId : '-'),
            const SizedBox(height: 12),
            _buildInfoRow('ID Pengguna', _detailPetugas!.userId.isNotEmpty ? _detailPetugas!.userId : '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Email', _detailPetugas!.email.isNotEmpty ? _detailPetugas!.email : '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Nomor WhatsApp', _detailPetugas!.noWhatsapp.isNotEmpty ? _detailPetugas!.noWhatsapp : '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Bergabung Sejak', joinedAtStr),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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
        joinedAtStr = AppDate.tanggalPanjang(dt);
      } catch (_) {}
    }

    return Column(
      children: [
        _buildSectionContainer(
          icon: CupertinoIcons.person_solid,
          iconBgColor: AppColors.dark,
          title: "Informasi Pribadi",
          children: [
            _buildInfoRow("ID Nasabah", _detailNasabah!['nasabah_id'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow("ID Pengguna", _detailNasabah!['user_id'] ?? '-'),
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
          style: AppText.r(10, AppColors.dark.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.w600(13, AppColors.dark),
        ),
      ],
    );
  }

  void _showSwitchRoleSheet() {
    final auth = context.read<AuthProvider>();
    final currentIsNasabah = auth.role == 'nasabah';

    String roleLabel(String r) => r == 'nasabah' ? 'Akun Nasabah' : 'Akun Petugas';
    IconData roleIcon(String r) => r == 'nasabah' ? Icons.person_rounded : Icons.shield_rounded;
    bool isCurrent(String r) => currentIsNasabah ? r == 'nasabah' : r == 'admin';

    final preSelected = auth.availableRoles.firstWhere(
      (r) => !isCurrent(r),
      orElse: () => '',
    );

    String selected = preSelected;
    bool isSwitching = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Pilih akun yang ingin kamu gunakan',
                    textAlign: TextAlign.center,
                    style: AppText.r(13, AppColors.dark.withValues(alpha: 0.55)),
                  ),
                ),
                ...auth.availableRoles.map((r) {
                  final isSelected = r == selected;
                  final isCurrentRole = isCurrent(r);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: isCurrentRole || isSwitching
                          ? null
                          : () => setSheetState(() => selected = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.green.withValues(alpha: 0.08)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.green
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.green.withValues(alpha: 0.15)
                                    : AppColors.dark.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                roleIcon(r),
                                size: 18,
                                color: isSelected
                                    ? AppColors.green
                                    : AppColors.dark.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              roleLabel(r),
                              style: AppText.w600(13, isSelected
                                    ? AppColors.dark
                                    : AppColors.dark.withValues(alpha: 0.45)),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Container(
                                width: 17, height: 17,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSwitching ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dark,
                          side: BorderSide(color: AppColors.dark.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text('Batal', style: AppText.w600(13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSwitching || selected.isEmpty
                            ? null
                            : () async {
                                setSheetState(() => isSwitching = true);
                                final targetRole = selected;
                                final success = await auth.switchRole(targetRole);
                                if (!mounted) return;
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (success) {
                                  final newRole = auth.role;
                                  Widget dest;
                                  if (newRole == 'nasabah') {
                                    dest = const HomeScreen();
                                  } else if (newRole.contains('bsu')) {
                                    dest = const HomeBsuScreen();
                                  } else if (newRole.contains('bsm')) {
                                    dest = const HomeBsmScreen();
                                  } else {
                                    dest = const HomeBsiScreen();
                                  }
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => dest),
                                    (route) => false,
                                  );
                                } else {
                                  showCustomSnackBar(context, auth.errorMessage ?? 'Gagal pindah akun');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: isSwitching
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Konfirmasi', style: AppText.w600(13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutSheet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, size: 28, color: AppColors.dark),
            ),
            const SizedBox(height: 16),
            Text(
              'Keluar dari Akun?',
              style: AppText.w700(16, AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu akan keluar dari sesi ini.\nKamu bisa login kembali kapan saja.',
              textAlign: TextAlign.center,
              style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.5), height: 1.6),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Batal', style: AppText.w600(13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => SplashScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: BorderSide(color: AppColors.dark.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Keluar', style: AppText.w600(13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPengaturanSection() {
    return _buildSectionContainer(
      icon: CupertinoIcons.settings_solid,
      iconBgColor: AppColors.dark,
      title: "Pengaturan",
      children: [
        _buildListMenuTile(
          title: "Edit Profil",
          onTap: () async {
            final auth = context.read<AuthProvider>();
            String nama = '';
            String noWa = '';
            String? photoUrl;
            bool hasOtherAccount = false;

            if (auth.role == 'nasabah') {
              nama = _detailNasabah?['nama'] ?? auth.nama;
              noWa = _detailNasabah?['no_whatsapp'] ?? '';
              photoUrl = _detailNasabah?['photo_url'];
              hasOtherAccount = _detailNasabah?['is_admin'] == true;
            } else if (auth.role.startsWith('petugas_')) {
              nama = _detailPetugas?.nama ?? auth.nama;
              noWa = _detailPetugas?.noWhatsapp ?? '';
              photoUrl = _detailPetugas?.photoUrl;
              hasOtherAccount = _detailPetugas?.isNasabah == true;
            }

            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfilScreen(
                  userId: auth.userId,
                  role: auth.role,
                  initialNama: nama,
                  initialNoWhatsapp: noWa,
                  initialPhotoUrl: photoUrl,
                  hasOtherAccount: hasOtherAccount,
                ),
              ),
            );

            if (updated == true && mounted) {
              if (auth.role == 'nasabah') {
                _fetchDetailNasabah(auth.identityId);
              } else if (auth.role.startsWith('petugas_')) {
                _fetchDetailPetugas(auth.identityId);
              }
            }
          },
        ),
        _buildListMenuTile(
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
          title: "Log Aktivasi Akun",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogAkunScreen()),
          ),
        ),
        if (context.read<AuthProvider>().availableRoles.length > 1)
          _buildListMenuTile(
            title: "Pindah Akun",
            onTap: () => _showSwitchRoleSheet(),
          ),
        _buildListMenuTile(
          title: "Keluar dari Akun",
          titleColor: Colors.red.shade400,
          hideDivider: true,
          onTap: () => _showLogoutSheet(),
        ),
      ],
    );
  }

  Widget _buildListMenuTile({
    required String title,
    required VoidCallback onTap,
    bool hideDivider = false,
    Color titleColor = AppColors.dark,
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
                Text(
                  title,
                  style: AppText.w500(13, titleColor),
                ),
                const Spacer(),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          if (!hideDivider)
            Divider(
              color: AppColors.dark.withValues(alpha: 0.08),
              height: 1,
              thickness: 0.5,
            ),
        ],
      ),
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
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1)
          ),
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
                    style: AppText.w600(13, AppColors.dark),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                height: 0.5,
                color: AppColors.dark.withValues(alpha: 0.08),
              ),
            ),
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

}
