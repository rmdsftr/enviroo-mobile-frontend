import 'package:enviroo/models/pengangkutan_bsu_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:enviroo/widgets/filter_month_year.dart';
import 'package:enviroo/services/pengangkutan_service.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/pengangkutan_provider.dart';
import 'package:enviroo/screens/pengangkutan/detail_pengangkutan_screen.dart';
import 'package:enviroo/screens/pengangkutan/sesi_pengangkutan_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class PengangkutanBsuScreen extends StatefulWidget {
  const PengangkutanBsuScreen({super.key});

  @override
  State<PengangkutanBsuScreen> createState() => _PengangkutanBsuScreenState();
}

class _PengangkutanBsuScreenState extends State<PengangkutanBsuScreen> {
  bool _isLoading = true;
  List<PengangkutanBsuData> _riwayat = [];
  SesiActiveData? _sesiAktif;

  PengangkutanProvider? _pengangkutanProvider;
  int _lastRefreshToken = -1;

  DateTime _filterStart = DateTime(DateTime.now().year, DateTime.now().month - 2);
  DateTime _filterEnd = DateTime(DateTime.now().year, DateTime.now().month);

  static const _terminalStatuses = {'completed', 'canceled', 'rejected'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _pengangkutanProvider = context.read<PengangkutanProvider>();
      _lastRefreshToken = _pengangkutanProvider!.refreshToken;
      _pengangkutanProvider!.addListener(_onPengangkutanRefresh);
    });
  }

  @override
  void dispose() {
    _pengangkutanProvider?.removeListener(_onPengangkutanRefresh);
    super.dispose();
  }

  void _onPengangkutanRefresh() {
    if (!mounted || _pengangkutanProvider == null) return;
    final token = _pengangkutanProvider!.refreshToken;
    if (token != _lastRefreshToken) {
      _lastRefreshToken = token;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId ?? '';

    if (bankId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final sesiRes = await PengangkutanService.checkSesiActive(bankId);

    final startDate = '${_filterStart.year}-${_filterStart.month.toString().padLeft(2, '0')}-01';
    final endDate = '${_filterEnd.year}-${_filterEnd.month.toString().padLeft(2, '0')}-${DateTime(_filterEnd.year, _filterEnd.month + 1, 0).day.toString().padLeft(2, '0')}';
    final riwayatRes = await PengangkutanService.getAllPengangkutan(bankId, startDate: startDate, endDate: endDate);

    if (!mounted) return;

    SesiActiveData? sesiAktif;
    if (sesiRes['success'] == true) {
      final data = sesiRes['data'] as Map<String, dynamic>? ?? {};
      final parsed = SesiActiveData.fromJson(data);
      if (parsed.isActive) sesiAktif = parsed;
    }

    final List<PengangkutanBsuData> riwayat = [];
    if (riwayatRes['success'] == true) {
      final List data = riwayatRes['data'] ?? [];
      for (final item in data) {
        final p = PengangkutanBsuData.fromJson(item);
        if (_terminalStatuses.contains(p.status)) riwayat.add(p);
      }
    }

    setState(() {
      _sesiAktif = sesiAktif;
      _riwayat = riwayat;
      _isLoading = false;
    });
  }

  List<PengangkutanBsuData> get _filteredRiwayat {
    return _riwayat.where((s) {
      if (s.rawDate == null) return true;
      final d = DateTime(s.rawDate!.year, s.rawDate!.month);
      final start = DateTime(_filterStart.year, _filterStart.month);
      final end = DateTime(_filterEnd.year, _filterEnd.month);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCool,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk2.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const TopBarBack(title: 'Pengangkutan'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.cyan,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _sesiAktif != null
                                ? _buildAktifCard(_sesiAktif!)
                                : _infoCard(),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height,
                            ),
                            decoration: const BoxDecoration(color: Colors.white),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Riwayat Pengangkutan', style: AppText.w600(14, AppColors.dark)),
                              const SizedBox(height: 12),
                              MonthYearFilterRow(
                                filterStart: _filterStart,
                                filterEnd: _filterEnd,
                                onChanged: (start, end) {
                                  setState(() {
                                    _filterStart = start;
                                    _filterEnd = end;
                                  });
                                  _loadData();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildRiwayatList(),
                            ]),
                          ),
                        ]),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAktifCard(SesiActiveData sesi) {
    final statusColor = _statusColor(sesi.statusTerkini);
    final statusLabel = _statusLabel(sesi.statusTerkini);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pengangkutan Aktif',
                style: AppText.w700(14, Colors.white),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 16),

          _infoDetailRowDark(
            Icons.info_outline_rounded,
            'Status Terkini',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: AppText.w700(10, statusColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _infoDetailRowDark(
            Icons.business_rounded,
            'BSI',
            Text(
              sesi.namaBsi,
              style: AppText.w600(12, Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          _infoDetailRowDark(
            Icons.tag_rounded,
            'ID Pengangkutan',
            Text(
              sesi.pengangkutanId,
              style: AppText.w600(12, Colors.white),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SesiPengangkutanScreen(
                      pengangkutanId: sesi.pengangkutanId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                'Lihat Detail Pengangkutan',
                style: AppText.w600(13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.dark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDetailRowDark(IconData icon, String label, Widget valueWidget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.r(10, Colors.white60),
              ),
              const SizedBox(height: 2),
              valueWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            Icon(Icons.history_toggle_off_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Belum ada riwayat pengangkutan', style: AppText.r(13, Colors.grey[400])),
          ]),
        ),
      );
    }

    final filtered = _filteredRiwayat;
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            Icon(Icons.search_off_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Tidak ada riwayat di rentang waktu ini', style: AppText.r(13, Colors.grey[400])),
          ]),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRiwayatTile(filtered[i]),
    );
  }

  Widget _buildRiwayatTile(PengangkutanBsuData s) {
    final color = _statusColor(s.status);
    final bgColor = color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        if (s.status == 'completed' || s.status == 'canceled') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPengangkutanScreen(
                pengangkutanId: s.id,
                namaBsu: s.namaBsu,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            width: 1,
            color: AppColors.dark.withValues(alpha: 0.1),
          ),
        ),
        child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: AppColors.dark.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_statusIcon(s.status), color: AppColors.dark, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.tanggal, style: AppText.w600(13, AppColors.dark)),
          const SizedBox(height: 3),
          Text(s.id, style: AppText.r(11.5, Colors.grey[500])),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
          child: Text(_statusLabel(s.status), style: AppText.w600(10.5, color)),
        ),
      ]),
    ));
  }

  Widget _infoCard() {
    const teal = AppColors.dark;

    Widget infoItem(String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppText.p(11, color: teal.withValues(alpha: 0.6), height: 1.55),
                ),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: teal.withValues(alpha: 0.5)),
              const SizedBox(width: 7),
              Text(
                'Informasi',
                style: AppText.w600(11, teal.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          infoItem(
              'Fitur penyetoran baru akan muncul jika sesi pengangkutan sudah dibuka oleh petugas BSI.'),
          infoItem(
              'Pengajuan penjemputan di luar jadwal rutin dapat diajukan melalui menu Jadwal.'),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'requested': return 'Diajukan';
      case 'approved':  return 'Disetujui';
      case 'rejected':  return 'Ditolak';
      case 'otw':       return 'Dalam Perjalanan';
      case 'canceled':  return 'Dibatalkan';
      case 'completed': return 'Selesai';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return AppColors.green;
      case 'canceled': case 'rejected': return Colors.red.shade400;
      case 'otw':       return AppColors.cyan;
      case 'approved':  return const Color(0xFF8BC34A);
      case 'requested': return AppColors.warningAlt;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle_outline_rounded;
      case 'canceled': case 'rejected': return Icons.cancel_outlined;
      case 'otw':       return Icons.local_shipping_rounded;
      case 'approved':  return Icons.thumb_up_alt_rounded;
      case 'requested': return Icons.hourglass_top_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}
