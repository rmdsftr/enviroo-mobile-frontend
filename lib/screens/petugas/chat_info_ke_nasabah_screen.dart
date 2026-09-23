import 'package:enviroo/models/notifikasi_model.dart';
import 'package:enviroo/services/notifikasi_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Screen ───────────────────────────────────────────────────────────────────
// Chat room notifikasi jadwal/penimbangan yang dikirim ke nasabah — dilihat
// dari POV petugas_bsm sebagai pengirim, jadi bubble-nya rata kanan.
// Sumber datanya sama persis kayak ChatInfoBankSampahScreen (notifikasi
// role_target=nasabah, ref_type 'penimbangan' / 'jadwal_penimbangan'),
// cuma di sini kita fetch langsung lewat service (bukan NotifikasiProvider
// yang shared) biar gak numpuk/nabrak sama notifikasi role_target=admin
// milik petugas sendiri yang udah ke-load di provider itu. Dan gak ada
// mark-as-read di sini — status baca itu milik nasabah, bukan petugas yang
// cuma nonton log kiriman.
class ChatInfoKeNasabahScreen extends StatefulWidget {
  const ChatInfoKeNasabahScreen({super.key});

  @override
  State<ChatInfoKeNasabahScreen> createState() =>
      _ChatInfoKeNasabahScreenState();
}

class _ChatInfoKeNasabahScreenState extends State<ChatInfoKeNasabahScreen> {
  static const _dark = Color(0xFF013236);
  static const _accent = Color(0xFF4EA771);

  bool _isLoading = true;
  String? _error;
  List<NotifikasiModel> _notifs = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Chat room = defaultnya harus langsung nampilin notifikasi paling baru
  // (paling bawah), bukan mulai dari atas.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await NotifikasiService.getNotifikasi('nasabah', limit: 100);

    if (!mounted) return;
    if (result['success'] == true) {
      final list = (result['data'] as List<NotifikasiModel>? ?? [])
          .where((n) => n.isChatInfoBank)
          .toList();
      // Kayak chat room: paling bawah = notifikasi paling baru.
      list.sort((a, b) {
        final ta = DateTime.tryParse(a.createdAt) ?? DateTime(0);
        final tb = DateTime.tryParse(b.createdAt) ?? DateTime(0);
        return ta.compareTo(tb);
      });
      setState(() {
        _notifs = list;
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message']?.toString() ?? 'Gagal memuat notifikasi';
      });
    }
  }

  DateTime _parseTime(NotifikasiModel n) =>
      DateTime.tryParse(n.createdAt)?.toLocal() ?? DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _accent),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          )
                        : _notifs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada notifikasi yang dikirim',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0x66013236),
                                  ),
                                ),
                              )
                            : _buildChatList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: back + judul ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(5, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: _dark,
            ),
          ),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              'Notifikasi Jadwal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat list: bubble "outgoing" doang, petugas sebagai pengirim ────────────
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _notifs.length,
      itemBuilder: (ctx, i) {
        final notif = _notifs[i];
        final time = _parseTime(notif);
        final prevTime = i == 0 ? null : _parseTime(_notifs[i - 1]);
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

  String _dateSeparatorLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(time.year, time.month, time.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('d MMMM yyyy', 'id_ID').format(time);
  }

  Widget _buildDateSeparator(DateTime time) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _dark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          _dateSeparatorLabel(time),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _dark.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(NotifikasiModel notif, DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.88,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _dark.withValues(alpha: 0.06),
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
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: _dark.withValues(alpha: 0.85),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: _dark.withValues(alpha: 0.15),
                        ),
                      ),
                      Text(
                        notif.pesan,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          height: 1.5,
                          color: _dark.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4),
                  child: Text(
                    DateFormat('HH:mm', 'id_ID').format(time),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9.5,
                      color: _dark.withValues(alpha: 0.35),
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
}
