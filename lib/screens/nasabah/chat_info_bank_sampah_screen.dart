import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/jadwal_model.dart';
import 'package:enviroo/models/notifikasi_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/notifikasi_provider.dart';
import 'package:enviroo/providers/jadwal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ChatInfoBankSampahScreen extends StatefulWidget {
  final String bankId;
  final String namaBank;
  final String photoUrl;

  const ChatInfoBankSampahScreen({
    super.key,
    required this.bankId,
    required this.namaBank,
    this.photoUrl = '',
  });

  @override
  State<ChatInfoBankSampahScreen> createState() =>
      _ChatInfoBankSampahScreenState();
}

class _ChatInfoBankSampahScreenState extends State<ChatInfoBankSampahScreen> {

  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      await context.read<NotifikasiProvider>().fetchNotifikasi(role: auth.role);
      if (!mounted) return;
      await _markAllChatAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottomOnce() {
    if (_scrolledToBottom) return;
    _scrolledToBottom = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _markAllChatAsRead() async {
    final provider = context.read<NotifikasiProvider>();
    final unread = provider.notifikasi.where((n) => n.isChatInfoBank && !n.isRead);
    for (final n in unread) {
      await provider.markAsRead(notifId: n.id);
    }
  }

  List<NotifikasiModel> _chatNotifs(NotifikasiProvider provider) {
    final list = provider.notifikasi.where((n) => n.isChatInfoBank).toList();
    list.sort((a, b) {
      final ta = DateTime.tryParse(a.createdAt) ?? DateTime(0);
      final tb = DateTime.tryParse(b.createdAt) ?? DateTime(0);
      return ta.compareTo(tb);
    });
    return list;
  }

  void _openJadwalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JadwalPenimbanganSheet(bankId: widget.bankId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk2.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<NotifikasiProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.notifikasi.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      );
                    }
                    final chatNotifs = _chatNotifs(provider);
                    if (chatNotifs.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada percakapan',
                          style: AppText.r(13, Color(0x66013236)),
                        ),
                      );
                    }
                    return _buildChatList(chatNotifs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.fromLTRB(5, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: AppColors.dark,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neon.withValues(alpha: 0.12),
            ),
            child: ClipOval(
              child: widget.photoUrl.isNotEmpty
                  ? Image.network(
                      widget.photoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _headerAvatarFallback(),
                    )
                  : _headerAvatarFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.namaBank,
              style: AppText.w700(14.5, AppColors.dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openJadwalSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neon,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAvatarFallback() {
    return Icon(Icons.recycling_rounded, color: AppColors.neon, size: 18);
  }

  DateTime _parseTime(NotifikasiModel n) =>
      DateTime.tryParse(n.createdAt)?.toLocal() ?? DateTime.now();

  Widget _buildChatList(List<NotifikasiModel> notifs) {
    _scrollToBottomOnce();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: notifs.length,
      itemBuilder: (ctx, i) {
        final notif = notifs[i];
        final time = _parseTime(notif);
        final prevTime = i == 0 ? null : _parseTime(notifs[i - 1]);
        final showDateSeparator = prevTime == null || !_isSameDay(prevTime, time);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateSeparator) _buildDateSeparator(time),
            _buildBubble(notif, time),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime time) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.dark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          AppDate.labelRelatif(time),
          style: AppText.w600(10.5, AppColors.dark.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _buildBubble(NotifikasiModel notif, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.88,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notif.judul,
                        style: AppText.p(12.5, weight: FontWeight.w600, color: AppColors.dark.withValues(alpha: 0.85), height: 1.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.dark.withValues(alpha: 0.08),
                        ),
                      ),
                      Text(
                        notif.pesan,
                        style: AppText.p(12.5, color: AppColors.dark.withValues(alpha: 0.85), height: 1.5),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    AppDate.jam(time),
                    style: AppText.r(9.5, AppColors.dark.withValues(alpha: 0.35)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JadwalPenimbanganSheet extends StatefulWidget {
  final String bankId;

  const _JadwalPenimbanganSheet({required this.bankId});

  @override
  State<_JadwalPenimbanganSheet> createState() =>
      _JadwalPenimbanganSheetState();
}

class _JadwalPenimbanganSheetState extends State<_JadwalPenimbanganSheet> {

  static const _visibleStatus = {'pending', 'upcoming'};

  List<JadwalPenimbanganItem> _jadwalList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchJadwal());
  }

  Future<void> _fetchJadwal() async {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final merged = <JadwalPenimbanganItem>[];
    bool anySuccess = false;
    String? lastError;

    for (final cursor in [DateTime(now.year, now.month), nextMonth]) {
      final result = await context.read<JadwalProvider>().fetchPenimbanganBsm(
        widget.bankId,
        month: cursor.month,
        year: cursor.year,
      );
      if (result['success'] == true) {
        anySuccess = true;
        merged.addAll((result['data'] as List<JadwalPenimbanganItem>?) ?? []);
      } else {
        lastError = result['message']?.toString();
      }
    }

    if (!mounted) return;

    final todayNorm = DateTime(now.year, now.month, now.day);
    final filtered = merged.where((j) {
      final tglNorm = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      return j.isActive &&
          _visibleStatus.contains(j.statusJadwal) &&
          !tglNorm.isBefore(todayNorm);
    }).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    setState(() {
      _isLoading = false;
      if (anySuccess) {
        _jadwalList = filtered;
      } else {
        _error = lastError ?? "Gagal memuat jadwal.";
      }
    });
  }

  String _formatTanggal(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 4, 25, 20),
            child: Text(
              'Di sini kamu bisa lihat jadwal penimbangan bank sampah untuk satu bulan ke depan',
              style: AppText.w500(12, AppColors.dark.withValues(alpha: 0.75)),
            ),
          ),
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        child: Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(fontFamily: 'Poppins', color: Colors.red),
                          ),
                        ),
                      )
                    : _jadwalList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            child: Center(
                              child: Text(
                                "Belum ada jadwal penimbangan.",
                                style: AppText.r(12, AppColors.dark.withValues(alpha: 0.5)),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: _jadwalList.length,
                            itemBuilder: (_, i) {
                              final isLast = i == _jadwalList.length - 1;
                              return _buildJadwalRow(_jadwalList[i], isLast: isLast);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalRow(JadwalPenimbanganItem jadwal, {bool isLast = false}) {
    final String tanggal = _formatTanggal(jadwal.tanggal);
    final String namaJadwal = jadwal.namaJadwal.isNotEmpty ? jadwal.namaJadwal : '-';
    final String jam = jadwal.formattedJam;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggal,
                    style: AppText.w600(12, AppColors.dark),
                  ),
                  Text(
                    namaJadwal,
                    style: AppText.w500(11, AppColors.dark.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: AppColors.dark.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jam,
                    style: AppText.w600(11, AppColors.dark.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            height: 20,
            thickness: 1,
            color: AppColors.dark.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
