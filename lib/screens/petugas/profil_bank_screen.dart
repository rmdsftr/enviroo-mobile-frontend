import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/detail_bank_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/providers/profil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/search.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/state_message.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ProfilBankScreen extends StatefulWidget {
  final String? bankId;
  final VoidCallback? onBack;

  final String judul;

  const ProfilBankScreen({
    super.key,
    this.bankId,
    this.onBack,
    this.judul = 'Profil Bank',
  });

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
    final bankId = widget.bankId ?? context.read<AuthProvider>().bankId;

    if (bankId == null || bankId.isEmpty) {
      setState(() => _error = 'Bank ID tidak ditemukan');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prov = context.read<ProfilProvider>();
    await prov.fetchBank(bankId);
    if (!mounted) return;
    if (prov.bankStatus == FetchStatus.success) {
      setState(() { _bank = prov.bank; _isLoading = false; });
    } else {
      setState(() { _error = prov.bankError ?? 'Gagal memuat data bank'; _isLoading = false; });
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
                TopBarBack(title: widget.judul, onBack: widget.onBack),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.green))
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
              child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: AppText.r(13, AppColors.dark.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBankDetail,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Coba Lagi', style: AppText.r(13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
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

  Widget _buildContent() {
    final bank = _bank!;
    final joinedAtStr = bank.joinedAt != null
        ? AppDate.tanggalPanjang(bank.joinedAt!)
        : '-';

    return RefreshIndicator(
      color: AppColors.green,
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

  Widget _buildHeroCard(DetailBankModel bank) {
    final borderColor = bank.isActive ? AppColors.green : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.dark,
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
              style: AppText.w700(17, Colors.white),
            ),
            const SizedBox(height: 10),
            _buildBadge(bank.jenisBank, AppColors.neon, AppColors.dark),
          ],
        ),
      ),
    );
  }

  Widget _defaultBankAvatar() {
    return Container(
      width: 90, height: 90,
      color: AppColors.green.withValues(alpha: 0.2),
      child: const Icon(Icons.account_balance_rounded, color: AppColors.green, size: 40),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: AppText.w600(10, textColor),
      ),
    );
  }

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

  Widget _buildDeskripsiCard(String deskripsi) {
    return _buildSectionCard(
      icon: CupertinoIcons.text_alignleft,
      title: 'Deskripsi',
      children: [
        Text(
          deskripsi,
          style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.75), height: 1.7),
        ),
      ],
    );
  }

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

  static const _jumlahPreview = 3;

  Widget _buildStaffCard(List<AdminBankModel> admins) {
    final pengurus = _urutkanPengurus(admins);
    final jumlahAdmin = pengurus.where((a) => _isAdmin(a.roleAdmin)).length;
    final jumlahPetugas = pengurus.where((a) => _isPetugas(a.roleAdmin)).length;
    final preview = pengurus.take(_jumlahPreview).toList();

    return _buildSectionCard(
      icon: Icons.people_alt_rounded,
      title: 'Pengurus Bank Sampah (${admins.length})',
      children: admins.isEmpty
          ? [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada staff terdaftar',
                    style: AppText.r(12, AppColors.dark.withValues(alpha: 0.45)),
                  ),
                ),
              ),
            ]
          : [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (jumlahAdmin > 0)
                    _RoleBadge(isAdmin: true, label: '$jumlahAdmin Admin'),
                  if (jumlahPetugas > 0)
                    _RoleBadge(isAdmin: false, label: '$jumlahPetugas Petugas'),
                ],
              ),
              const SizedBox(height: 6),
              ...preview.asMap().entries.map((entry) {
                final isLast = entry.key == preview.length - 1;
                return Column(
                  children: [
                    _StaffTile(admin: entry.value),
                    if (!isLast)
                      Divider(
                        color: AppColors.dark.withValues(alpha: 0.07),
                        height: 1, thickness: 0.5,
                      ),
                  ],
                );
              }),
              if (pengurus.length > _jumlahPreview) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _bukaDaftarPengurus(pengurus),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: BorderSide(color: AppColors.dark.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lihat Semua Pengurus (${pengurus.length})',
                          style: AppText.w600(12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ],
    );
  }

  void _bukaDaftarPengurus(List<AdminBankModel> pengurus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffListSheet(pengurus: pengurus),
    );
  }

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
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.1)),
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
                    decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 14),
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
              child: Container(height: 0.5, color: AppColors.dark.withValues(alpha: 0.08)),
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

bool _isAdmin(String role) => role.toLowerCase().contains('admin');

bool _isPetugas(String role) => role.toLowerCase().contains('petugas');

String _roleLabel(String role) {
  if (_isAdmin(role)) return 'Admin';
  if (_isPetugas(role)) return 'Petugas';
  return role;
}

List<AdminBankModel> _urutkanPengurus(List<AdminBankModel> admins) {
  return [...admins]..sort((a, b) {
      final rankA = _isAdmin(a.roleAdmin) ? 0 : 1;
      final rankB = _isAdmin(b.roleAdmin) ? 0 : 1;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.namaAdmin.toLowerCase().compareTo(b.namaAdmin.toLowerCase());
    });
}

class _RoleBadge extends StatelessWidget {
  final bool isAdmin;
  final String label;

  const _RoleBadge({required this.isAdmin, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.neon : AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppText.w600(10, isAdmin ? AppColors.dark : AppColors.green),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final AdminBankModel admin;

  const _StaffTile({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green.withValues(alpha: 0.4), width: 1.5),
            ),
            child: ClipOval(
              child: admin.photoUrl.isNotEmpty
                  ? Image.network(
                      admin.photoUrl, width: 42, height: 42, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.namaAdmin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.w600(13, AppColors.dark),
                ),
                const SizedBox(height: 2),
                Text(
                  admin.adminId,
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoleBadge(
            isAdmin: _isAdmin(admin.roleAdmin),
            label: _roleLabel(admin.roleAdmin),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 42, height: 42,
      color: AppColors.dark.withValues(alpha: 0.08),
      child: Icon(Icons.person_rounded, color: AppColors.dark.withValues(alpha: 0.4), size: 22),
    );
  }
}

class _StaffListSheet extends StatefulWidget {
  final List<AdminBankModel> pengurus;

  const _StaffListSheet({required this.pengurus});

  @override
  State<_StaffListSheet> createState() => _StaffListSheetState();
}

class _StaffListSheetState extends State<_StaffListSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filterRole = 'semua';

  List<AdminBankModel> get _filtered {
    final q = _query.toLowerCase();
    return widget.pengurus.where((a) {
      final cocokRole = _filterRole == 'semua' ||
          (_filterRole == 'admin' && _isAdmin(a.roleAdmin)) ||
          (_filterRole == 'petugas' && _isPetugas(a.roleAdmin));
      final cocokCari = q.isEmpty ||
          a.namaAdmin.toLowerCase().contains(q) ||
          a.adminId.toLowerCase().contains(q);
      return cocokRole && cocokCari;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengurus Bank Sampah',
                        style: AppText.w700(15, AppColors.dark),
                      ),
                      Text(
                        '${widget.pengurus.length} pengurus terdaftar',
                        style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.dark),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: CustomSearchBar(
              controller: _searchCtrl,
              hintText: 'Cari nama atau ID pengurus...',
              searchQuery: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),
          FilterChipRow<String>(
            items: const [
              FilterChipItem(value: 'semua', label: 'Semua'),
              FilterChipItem(value: 'admin', label: 'Admin'),
              FilterChipItem(value: 'petugas', label: 'Petugas'),
            ],
            selectedValue: _filterRole,
            onSelected: (v) => setState(() => _filterRole = v),
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildList()),
          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;

    if (list.isEmpty) {
      return const StateMessage(
        illustration: StateArt.error,
        message: 'Pengurus tidak ditemukan',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        color: AppColors.dark.withValues(alpha: 0.07),
        height: 1, thickness: 0.5,
      ),
      itemBuilder: (_, i) => _StaffTile(admin: list[i]),
    );
  }
}
