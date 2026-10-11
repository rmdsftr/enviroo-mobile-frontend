import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/profil_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class LogAkunScreen extends StatefulWidget {
  const LogAkunScreen({super.key});

  @override
  State<LogAkunScreen> createState() => _LogAkunScreenState();
}

class _LogAkunScreenState extends State<LogAkunScreen> {

  bool _isLoading = true;
  String _error = '';
  List<dynamic> _akunNasabah = [];
  List<dynamic> _akunAdmin   = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final auth   = context.read<AuthProvider>();
    final userId = auth.userId;

    setState(() { _isLoading = true; _error = ''; });
    final prov = context.read<ProfilProvider>();
    await prov.fetchLogAkun(userId);
    if (!mounted) return;

    if (prov.logStatus == FetchStatus.success) {
      final data = prov.log ?? <String, dynamic>{};
      setState(() {
        _akunNasabah = (data['akun_nasabah'] ?? []) as List<dynamic>;
        _akunAdmin   = (data['akun_admin']   ?? []) as List<dynamic>;
        _isLoading   = false;
      });
    } else {
      setState(() {
        _error     = prov.logError ?? 'Gagal memuat data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: "Log Aktivasi Akun"),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: AppText.r(13, AppColors.dark.withValues(alpha:0.5)),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(title: 'Akun Nasabah',        icon: Icons.person_rounded,               items: _akunNasabah, isNasabah: true),
          if (_akunAdmin.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(title: 'Akun Petugas / Admin', icon: Icons.admin_panel_settings_rounded, items: _akunAdmin,   isNasabah: false),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<dynamic> items,
    required bool isNasabah,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.dark.withValues(alpha:0.4)),
              const SizedBox(width: 7),
              Text(
                title,
                style: AppText.w600(12, AppColors.dark.withValues(alpha:0.4)),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tidak ada data',
              style: AppText.r(12, AppColors.dark.withValues(alpha:0.3)),
            ),
          )
        else
          ...List.generate(items.length, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
            child: _buildCard(items[i] as Map<String, dynamic>, isNasabah: isNasabah),
          )),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item, {required bool isNasabah}) {
    final String id       = isNasabah ? (item['nasabah_id'] ?? '-') : (item['admin_id'] ?? '-');
    final String afiliasi = item['afiliasi'] ?? '-';
    final String status   = (item['status'] ?? '').toString().toLowerCase();
    final String role     = isNasabah ? 'Nasabah' : (item['role'] ?? '-');

    DateTime? joinedAt;
    try { joinedAt = DateTime.parse(item['joined_at'].toString()); } catch (_) {}
    final String tglGabung = joinedAt != null
        ? AppDate.tanggalPanjang(joinedAt)
        : '-';

    Color statusColor;
    Color statusBg;
    if (status == 'aktif') {
      statusColor = AppColors.cyan;
      statusBg    = const Color(0xFFD6F4F6);
    } else if (status == 'pending') {
      statusColor = const Color(0xFFFFA726);
      statusBg    = const Color(0xFFFFF3E0);
    } else {
      statusColor = const Color(0xFFFF5A36);
      statusBg    = const Color(0xFFFFEEEA);
    }
    final String statusLabel = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark.withValues(alpha:0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role,
                style: AppText.w600(13, AppColors.dark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  statusLabel,
                  style: AppText.w600(10, statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.dark.withValues(alpha:0.06), height: 1),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.location_city_rounded,  afiliasi),
          const SizedBox(height: 5),
          _buildInfoRow(Icons.badge_outlined,          id),
          const SizedBox(height: 5),
          _buildInfoRow(Icons.calendar_today_outlined, 'Bergabung $tglGabung'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.dark.withValues(alpha:0.35)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.r(11.5, AppColors.dark.withValues(alpha:0.6)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
