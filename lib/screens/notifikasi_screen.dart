import 'package:enviroo/core/messaging/notif_router.dart';
import 'package:enviroo/models/notifikasi_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/widgets/filter_chip_row.dart';
import 'package:enviroo/widgets/pagination.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  String _filterType = 'semua';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final auth = context.read<AuthProvider>();
    context.read<NotifikasiProvider>().fetchNotifikasi(
          role: auth.role,
        );
  }

  void _markAllRead() {
    context.read<NotifikasiProvider>().markAllAsRead();
  }

  Future<void> _onTapNotif(NotifikasiModel notif) async {
    if (!notif.isRead) {
      await context.read<NotifikasiProvider>().markAsRead(
            notifId: notif.id,
          );
    }

    if (!mounted) return;

    final refType = notif.refType;
    final refId = notif.refId;
    if (refType == null || refId == null) return;
    NotifRouter.open(Navigator.of(context), refType: refType, refId: refId);
  }

  bool _isJadwal(String? refType) =>
      refType == 'jadwal_penimbangan' || refType == 'jadwal_pengangkutan';


  IconData _getIcon(String? refType) {
    switch (refType) {
      case 'setoran':             return CupertinoIcons.arrow_up_circle_fill;
      case 'penarikan':           return CupertinoIcons.arrow_down_circle_fill;
      case 'bagi_hasil':          return CupertinoIcons.money_dollar_circle_fill;
      case 'kontrak':             return CupertinoIcons.clock_fill;
      case 'pengajuan':           return CupertinoIcons.doc_text_fill;
      case 'pengangkutan':           return CupertinoIcons.cube_box_fill;
      case 'pengajuan_pengangkutan': return CupertinoIcons.cube_box_fill;
      case 'distribusi_barang':   return CupertinoIcons.cart_fill;
      case 'penimbangan':         return Icons.scale_rounded;
      case 'jadwal_penimbangan':  return Icons.scale_rounded;
      case 'jadwal_pengangkutan': return Icons.local_shipping_rounded;
      default:                    return CupertinoIcons.bell_fill;
    }
  }

  Color _getColor(String? refType) {
    switch (refType) {
      case 'setoran':             return AppColors.green;
      case 'penarikan':           return const Color(0xFF3B82C4);
      case 'bagi_hasil':          return const Color(0xFF7C5CBF);
      case 'kontrak':             return const Color(0xFFE07B39);
      case 'pengajuan':           return const Color(0xFF546E7A);
      case 'pengangkutan':           return const Color(0xFF0D8A8A);
      case 'pengajuan_pengangkutan': return const Color(0xFF0D8A8A);
      case 'distribusi_barang':   return const Color(0xFFE07B39);
      case 'penimbangan':         return AppColors.warning;
      case 'jadwal_penimbangan':  return AppColors.warning;
      case 'jadwal_pengangkutan': return const Color(0xFF0EA5E9);
      default:                    return AppColors.dark;
    }
  }

  bool _isPenimbanganBsm(String? refType) =>
      refType == 'jadwal_penimbangan' || refType == 'penimbangan';

  bool _isTappable(String? refType, String? refId, String role) =>
      NotifRouter.hasDestination(refType: refType, refId: refId, role: role);

  String _formatWaktu(String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF0),
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: 'Notifikasi'),
            Expanded(
              child: Consumer<NotifikasiProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 40,
                                color: Colors.red.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppText.r(13, AppColors.dark),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Coba Lagi',
                                  style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final role = context.watch<AuthProvider>().role;
                  final isNasabah = role == 'nasabah';
                  final isPetugasBsm = role == 'petugas_bsm';

                  final allNotifs = isNasabah
                      ? provider.notifikasi.where((n) => !n.isChatInfoBank).toList()
                      : provider.notifikasi;
                  final notifs = _filterType == 'semua'
                      ? allNotifs
                      : isNasabah
                          ? allNotifs.where((n) => n.refType == _filterType).toList()
                          : isPetugasBsm
                              ? (_filterType == 'penimbangan'
                                  ? allNotifs.where((n) => _isPenimbanganBsm(n.refType)).toList()
                                  : allNotifs.where((n) => n.refType == 'penarikan').toList())
                              : _filterType == 'jadwal'
                                  ? allNotifs.where((n) => _isJadwal(n.refType)).toList()
                                  : allNotifs.where((n) => !_isJadwal(n.refType)).toList();
                  final unread = allNotifs.where((n) => !n.isRead).length;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                        child: FilterChipRow<String>(
                          items: isNasabah
                              ? const [
                                  FilterChipItem(value: 'semua', label: 'Semua'),
                                  FilterChipItem(value: 'setoran', label: 'Setoran'),
                                  FilterChipItem(value: 'bagi_hasil', label: 'Bagi Hasil'),
                                  FilterChipItem(value: 'penarikan', label: 'Penarikan'),
                                ]
                              : isPetugasBsm
                                  ? const [
                                      FilterChipItem(value: 'semua', label: 'Semua'),
                                      FilterChipItem(value: 'penimbangan', label: 'Penimbangan'),
                                      FilterChipItem(value: 'penarikan', label: 'Penarikan'),
                                    ]
                                  : const [
                                      FilterChipItem(value: 'semua', label: 'Semua'),
                                      FilterChipItem(value: 'transaksi', label: 'Transaksi'),
                                      FilterChipItem(value: 'jadwal', label: 'Jadwal'),
                                    ],
                          selectedValue: _filterType,
                          onSelected: (v) => setState(() => _filterType = v),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      if (allNotifs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            unread > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$unread belum dibaca',
                                      style: AppText.w500(11, Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Semua sudah dibaca',
                                    style: AppText.r(11, AppColors.dark),
                                  ),
                            if (unread > 0)
                              GestureDetector(
                                onTap: _markAllRead,
                                child: Text(
                                  'Tandai semua dibaca',
                                  style: AppText.w600(11, AppColors.green),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (allNotifs.isNotEmpty) const SizedBox(height: 10),
                      Expanded(
                        child: notifs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.bell_slash,
                                        size: 48,
                                        color: AppColors.dark
                                            .withValues(alpha: 0.2)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada notifikasi',
                                      style: AppText.r(13, AppColors.dark),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                                      itemCount: notifs.length,
                                      itemBuilder: (context, index) =>
                                          _buildNotifCard(notifs[index], role),
                                    ),
                                  ),
                                  if (provider.totalPages > 1) ...[
                                    const SizedBox(height: 12),
                                    Pagination(
                                      currentPage: provider.currentPage,
                                      totalPages: provider.totalPages,
                                      onPageChanged: (page) => provider.goToPage(page),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(NotifikasiModel notif, String role) {
    if (_isJadwal(notif.refType)) return _buildJadwalCard(notif);

    final color = _getColor(notif.refType);
    final tappable = _isTappable(notif.refType, notif.refId, role);

    return GestureDetector(
      onTap: () => _onTapNotif(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFDFF4DA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : AppColors.green.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_getIcon(notif.refType), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.judul,
                          style: AppText.p(13, weight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w700, color: AppColors.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatWaktu(notif.createdAt),
                        style: AppText.r(10, AppColors.dark.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.pesan,
                    style: AppText.p(11, color: AppColors.dark.withValues(alpha: 0.6), height: 1.5),
                  ),
                  if (tappable) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Lihat detail',
                          style: AppText.w600(10, color),
                        ),
                        const SizedBox(width: 2),
                        Icon(CupertinoIcons.chevron_right,
                            size: 10, color: color),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!notif.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(NotifikasiModel notif) {
    final color = _getColor(notif.refType);
    final isHariIni = notif.judul.contains('Hari Ini');
    final isBesok = notif.judul.contains('Besok');
    final badgeLabel = isHariIni ? 'Hari Ini' : (isBesok ? 'Besok' : null);

    return GestureDetector(
      onTap: () => _onTapNotif(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: notif.isRead ? 0.18 : 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(_getIcon(notif.refType),
                              color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.judul,
                                      style: AppText.p(13, weight: notif.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700, color: AppColors.dark),
                                    ),
                                  ),
                                  if (badgeLabel != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: AppText.w700(9, color),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                notif.pesan,
                                style: AppText.p(11, color: AppColors.dark.withValues(alpha: 0.6), height: 1.5),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.clock,
                                      size: 10,
                                      color: AppColors.dark
                                          .withValues(alpha: 0.35)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatWaktu(notif.createdAt),
                                    style: AppText.r(10, AppColors.dark
                                          .withValues(alpha: 0.35)),
                                  ),
                                  if (!notif.isRead) ...[
                                    const Spacer(),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
