import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        _emailController.text = auth.nasabahProfile?.email ?? "";
      } else if (auth.role.startsWith('petugas_')) {
        _emailController.text = auth.petugasProfile?.email ?? "";
      } else {
        _emailController.text = auth.currentUser?.email ?? "";
      }
    });
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
                      const SizedBox(height: 25),
                      if(auth.role == "nasabah")
                        _buildRewardHistorySection(),
                      _buildEmailSection(),
                      const SizedBox(height: 16),
                      _buildPasswordSection(),
                      const SizedBox(height: 16),
                      if(auth.role == "nasabah") _buildPemindahanBsuSection(),
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

  // ═══════════════════════════════════════════════════════════════════
  // ─── Profile Card ─────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  // ─── Dummy statistik data ──────────────────────────────────────
  final int _jumlahReward = 4;
  final int _jumlahSetoran = 12;
  final int _jumlahPenarikan = 8;

  // ─── Dummy reward history ─────────────────────────────────────
  final List<Map<String, dynamic>> _rewardHistory = [
    {'bulan': 'Januari', 'tahun': 2026, 'rank': 2, 'berat': '18.5 kg'},
    {'bulan': 'Desember', 'tahun': 2025, 'rank': 1, 'berat': '24.2 kg'},
    {'bulan': 'Oktober', 'tahun': 2025, 'rank': 1, 'berat': '21.8 kg'},
    {'bulan': 'Agustus', 'tahun': 2025, 'rank': 3, 'berat': '15.3 kg'},
  ];

  Widget _buildCardProfile() {
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
              onTap: () => _showPhotoOptions(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4EA771),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      String? photoUrl;
                      if (auth.role == 'nasabah') {
                        photoUrl = auth.nasabahProfile?.foto;
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
            ),
            const SizedBox(height: 14),

            // ── Name ──
            Consumer<AuthProvider>(
              builder: (context, auth, _) => Text(
                auth.nama,
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
                          bankName = auth.nasabahProfile?.namaBsu ?? auth.nasabahProfile?.namaBsi ?? '-';
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
  // ─── Reward History Section ────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRewardHistorySection() {
    if (_rewardHistory.isEmpty) return const SizedBox.shrink();

    final rankLabels = {1: 'Gold', 2: 'Silver', 3: 'Bronze'};
    final rankEmojis = {1: '👑', 2: '🥈', 3: '🥉'};
    final rankGradients = {
      1: [const Color(0xFFD4F55A), const Color(0xFF94C91A)],
      2: [const Color(0xFF8ECAE6), const Color(0xFF4A9FBF)],
      3: [const Color(0xFF6BD4A0), const Color(0xFF2E9F6A)],
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Text(
                'Reward Saya',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF013236),
                ),
              ),
              const Spacer(),
              Text(
                '${_rewardHistory.length} reward',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: const Color(0xFF013236).withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal scrollable cards
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 2 cards visible: subtract separator, divide by 2
                final cardWidth = (constraints.maxWidth - 12) / 2;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _rewardHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final reward = _rewardHistory[index];
                    final rank = reward['rank'] as int;
                    final gradientColors = rankGradients[rank]!;

                    return Container(
                      width: cardWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Glossy top highlight
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.30),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Decorative circle
                        Positioned(
                          bottom: -15,
                          right: -15,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                        // Card content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Medal emoji
                              Text(
                                rankEmojis[rank]!,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 8),
                              // Rank label
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  rankLabels[rank]!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Month & year
                              Text(
                                '${reward['bulan']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF013236),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                '${reward['tahun']}  •  ${reward['berat']}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: const Color(0xFF013236).withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return _buildSectionContainer(
      icon: CupertinoIcons.mail_solid,
      iconBgColor: const Color(0xFF013236),
      title: "Ubah Email",
      children: [
        _buildTextField(
          controller: _emailController,
          label: "Email Baru",
          hint: "Masukkan email baru",
          prefixIcon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          label: "Simpan Email",
          onPressed: () {
            // TODO: Handle ubah email
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Section: Ubah Password ───────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPasswordSection() {
    return _buildSectionContainer(
      icon: CupertinoIcons.lock_fill,
      iconBgColor: const Color(0xFF013236),
      title: "Ubah Password",
      children: [
        _buildTextField(
          controller: _oldPasswordController,
          label: "Password Lama",
          hint: "Masukkan password lama",
          prefixIcon: CupertinoIcons.lock,
          obscure: _obscureOld,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureOld ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 18,
              color: const Color(0xFF013236).withValues(alpha: 0.4),
            ),
            onPressed: () => setState(() => _obscureOld = !_obscureOld),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _newPasswordController,
          label: "Password Baru",
          hint: "Masukkan password baru",
          prefixIcon: CupertinoIcons.lock_rotation,
          obscure: _obscureNew,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNew ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 18,
              color: const Color(0xFF013236).withValues(alpha: 0.4),
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _confirmPasswordController,
          label: "Konfirmasi Password",
          hint: "Ulangi password baru",
          prefixIcon: CupertinoIcons.checkmark_shield,
          obscure: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 18,
              color: const Color(0xFF013236).withValues(alpha: 0.4),
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          label: "Ubah Password",
          onPressed: () {
            // TODO: Handle ubah password
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ─── Section: Pengajuan Pemindahan BSU ────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPemindahanBsuSection() {
    return _buildSectionContainer(
      icon: CupertinoIcons.arrow_right_arrow_left,
      iconBgColor: const Color(0xFF013236),
      iconColor: Colors.white,
      title: "Pengajuan Pemindahan BSU",
      children: [
        // Info current BSU
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF4EA771).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4EA771).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.building_2_fill,
                  size: 18,
                  color: Color(0xFF4EA771),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BSU Saat Ini",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: const Color(0xFF013236).withValues(alpha: 0.5),
                      ),
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => Text(
                        auth.nasabahProfile?.namaBsu ?? "BSU Tidak Terikat",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Dropdown BSU tujuan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                "BSU Tujuan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBsu,
                  hint: Text(
                    "Pilih BSU tujuan",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: const Color(0xFF013236).withValues(alpha: 0.35),
                    ),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: const Color(0xFF013236).withValues(alpha: 0.4),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF013236),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  items: _daftarBsu.map((bsu) {
                    return DropdownMenuItem<String>(
                      value: bsu,
                      child: Text(bsu),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBsu = value);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Alasan pemindahan
        _buildTextField(
          controller: _alasanController,
          label: "Alasan Pemindahan",
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          label: "Ajukan Pemindahan",
          bgColor: const Color(0xFF013236),
          onPressed: () {
            // TODO: Handle pengajuan pemindahan BSU
          },
        ),
      ],
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

  // ═══════════════════════════════════════════════════════════════════
  // ─── Bottom Sheet: Photo Options ──────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Foto Profil",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF013236),
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                // Option: Lihat Foto
                _buildSheetOption(
                  icon: CupertinoIcons.eye,
                  iconColor: const Color(0xFF4EA771),
                  label: "Lihat Foto",
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Buka foto profil full screen
                  },
                ),
                Divider(height: 1, indent: 60, color: Colors.grey.shade100),
                // Option: Ubah Foto
                _buildSheetOption(
                  icon: CupertinoIcons.camera,
                  iconColor: const Color(0xFF013236),
                  label: "Ubah Foto",
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: image picker
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom Sheet option item ───────────────────────────────────
  Widget _buildSheetOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF013236),
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
