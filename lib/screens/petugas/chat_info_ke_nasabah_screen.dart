import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/models/notifikasi_model.dart';
import 'package:enviroo/services/notifikasi_service.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class ChatInfoKeNasabahScreen extends StatefulWidget {
  const ChatInfoKeNasabahScreen({super.key});

  @override
  State<ChatInfoKeNasabahScreen> createState() =>
      _ChatInfoKeNasabahScreenState();
}

class _ChatInfoKeNasabahScreenState extends State<ChatInfoKeNasabahScreen> {

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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppText.r(13, Colors.red),
                              ),
                            ),
                          )
                        : _notifs.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada notifikasi yang dikirim',
                                  style: AppText.r(13, Color(0x66013236)),
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
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Notifikasi Jadwal',
              style: AppText.w600(15, AppColors.dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
                    color: AppColors.green.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(4),
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
                          color: AppColors.dark.withValues(alpha: 0.15),
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
                  padding: const EdgeInsets.only(right: 4, top: 4),
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
