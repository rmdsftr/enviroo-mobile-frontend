import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/models/detail_bank_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/services/profil_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';

class ProfilBankScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfilBankScreen({super.key, this.onBack});

  @override
  State<ProfilBankScreen> createState() => _ProfilBankScreenState();
}

class _ProfilBankScreenState extends State<ProfilBankScreen> {
  bool _isLoading = false;
  String _error = '';
  DetailBankModel? _bank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchBankDetail());
  }

  Future<void> _fetchBankDetail() async {
    final auth = context.read<AuthProvider>();
    final bankId = auth.bankId;

    if (bankId == null || bankId.isEmpty) {
      setState(() => _error = 'Bank ID tidak ditemukan');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final bank = await ProfilService.getDetailBank(bankId);
      if (mounted) setState(() { _bank = bank; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
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
                TopBarBack(title: 'Profil Bank', onBack: widget.onBack),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4EA771)))
                      : _error.isNotEmpty
                          ? _buildErrorState()
                          : _bank == null
                              ? const Center(child: Text('Tidak ada data'))
                              : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: const Color(0xFF013236).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBankDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EA771),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Content ───────────────────────────────────────────────────────────

  Widget _buildContent() {
    final bank = _bank!;
    final joinedAtStr = bank.joinedAt != null
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(bank.joinedAt!)
        : '-';

    return RefreshIndicator(
      color: const Color(0xFF4EA771),
      onRefresh: _fetchBankDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          children: [
            _buildHeroCard(bank),
            const SizedBox(height: 16),
            _buildInfoCard(bank, joinedAtStr),
            if (bank.deskripsi.isNotEmpty) _buildDeskripsiCard(bank.deskripsi),
            if (bank.alamat.isNotEmpty || bank.wilayah.isNotEmpty) _buildLokasiCard(bank),
            _buildStaffCard(bank.admins),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(DetailBankModel bank) {
    final borderColor = bank.isActive ? const Color(0xFF4EA771) : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF013236),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LihatFotoScreen(
                    photoUrl: bank.photoUrl.isNotEmpty ? bank.photoUrl : null,
                    nama: bank.namaBank,
                  ),
                ),
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: ClipOval(
                  child: bank.photoUrl.isNotEmpty
                      ? Image.network(
                          bank.photoUrl,
                          width: 90, height: 90, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultBankAvatar(),
                        )
                      : _defaultBankAvatar(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              bank.namaBank,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildBadge(bank.jenisBank, const Color(0xFF94DF0C), const Color(0xFF013236)),
          ],
        ),
      ),
    );
  }

  Widget _defaultBankAvatar() {
    return Container(
      width: 90, height: 90,
      color: const Color(0xFF4EA771).withValues(alpha: 0.2),
      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF4EA771), size: 40),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  // ─── Info Card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(DetailBankModel bank, String joinedAtStr) {
    return _buildSectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Informasi Bank',
      children: [
        _buildInfoRow(icon: Icons.business_rounded, label: 'Jenis Bank', value: bank.jenisBank),
        if (bank.isBsu && bank.bankIndukNama.isNotEmpty)
          _buildInfoRow(icon: Icons.account_tree_rounded, label: 'Bank Induk', value: bank.bankIndukNama),
        _buildInfoRow(icon: Icons.calendar_today_rounded, label: 'Bergabung Sejak', value: joinedAtStr),
        _buildInfoRow(icon: Icons.tag_rounded, label: 'ID Bank', value: bank.bankId, isLast: true),
      ],
    );
  }

  // ─── Deskripsi Card ─────────────────────────────────────────────────────────

  Widget _buildDeskripsiCard(String deskripsi) {
    return _buildSectionCard(
      icon: CupertinoIcons.text_alignleft,
      title: 'Deskripsi',
      children: [
        Text(
          deskripsi,
          style: TextStyle(
            fontFamily: 'Poppins', fontSize: 12,
            color: const Color(0xFF013236).withValues(alpha: 0.75),
            height: 1.7,
          ),
        ),
      ],
    );
  }

  // ─── Lokasi Card ────────────────────────────────────────────────────────────

  Widget _buildLokasiCard(DetailBankModel bank) {
    return _buildSectionCard(
      icon: Icons.location_on_rounded,
      title: 'Lokasi',
      children: [
        if (bank.alamat.isNotEmpty)
          _buildInfoRow(
            icon: Icons.home_rounded, label: 'Alamat', value: bank.alamat,
            isLast: bank.wilayah.isEmpty,
          ),
        if (bank.wilayah.isNotEmpty)
          _buildInfoRow(icon: Icons.map_rounded, label: 'Wilayah', value: bank.wilayah, isLast: true),
      ],
    );
  }

  // ─── Staff Card ─────────────────────────────────────────────────────────────

  Widget _buildStaffCard(List<AdminBankModel> admins) {
    return _buildSectionCard(
      icon: Icons.people_alt_rounded,
      title: 'Tim Staff (${admins.length})',
      children: admins.isEmpty
          ? [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada staff terdaftar',
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: const Color(0xFF013236).withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ]
          : admins.asMap().entries.map((entry) {
              final isLast = entry.key == admins.length - 1;
              return Column(
                children: [
                  _buildStaffTile(entry.value),
                  if (!isLast)
                    Divider(
                      color: const Color(0xFF013236).withValues(alpha: 0.07),
                      height: 1, thickness: 0.5,
                    ),
                ],
              );
            }).toList(),
    );
  }

  Widget _buildStaffTile(AdminBankModel admin) {
    Color roleTextColor;
    Color roleBg;
    if (admin.roleAdmin == 'Admin') {
      roleTextColor = const Color(0xFF013236);
      roleBg = const Color(0xFF94DF0C);
    } else if (admin.roleAdmin == 'Superadmin') {
      roleTextColor = Colors.white;
      roleBg = const Color(0xFF013236);
    } else {
      roleTextColor = const Color(0xFF4EA771);
      roleBg = const Color(0xFF4EA771).withValues(alpha: 0.12);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4EA771).withValues(alpha: 0.4), width: 1.5),
            ),
            child: ClipOval(
              child: admin.photoUrl.isNotEmpty
                  ? Image.network(
                      admin.photoUrl, width: 42, height: 42, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultStaffAvatar(),
                    )
                  : _defaultStaffAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.namaAdmin,
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  admin.adminId,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: const Color(0xFF013236).withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              admin.roleAdmin,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: roleTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultStaffAvatar() {
    return Container(
      width: 42, height: 42,
      color: const Color(0xFF013236).withValues(alpha: 0.08),
      child: Icon(Icons.person_rounded, color: const Color(0xFF013236).withValues(alpha: 0.4), size: 22),
    );
  }

  // ─── Reusable Widgets ───────────────────────────────────────────────────────

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4EA771).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF4EA771)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: const Color(0xFF013236).withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF013236).withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  Container(
                    width: 25, height: 25,
                    decoration: BoxDecoration(color: const Color(0xFF013236), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF013236)),
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
