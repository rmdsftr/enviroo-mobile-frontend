import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/setoran_nasabah_model.dart';
import 'package:enviroo/models/setoran_model.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/providers/setoran_provider.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';

class DetailSetoranScreen extends StatefulWidget {
  final String setoranId;
  const DetailSetoranScreen({super.key, required this.setoranId});

  @override
  State<DetailSetoranScreen> createState() => _DetailSetoranScreenState();
}

class _DetailSetoranScreenState extends State<DetailSetoranScreen> {

  SetoranDetailHeader? _header;
  List<SetoranItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  Future<void> _fetchDetail() async {
    final prov = context.read<SetoranProvider>();
    await prov.fetchDetail(widget.setoranId);
    if (!mounted) return;
    if (prov.detailStatus == FetchStatus.success) {
      setState(() {
        _header = prov.detailHeader;
        _items = prov.detailItems;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = prov.detailError ?? 'Gagal memuat detail setoran';
        _isLoading = false;
      });
    }
  }

  String _fmtQty(double v) => AppNumber.desimal(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBarBack(title: 'Detail Setoran'),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                    : _error != null
                        ? _buildError()
                        : _buildStruk(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStruk() {
    final h = _header!;
    const statusColor = AppColors.green;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: statusColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Setoran Berhasil',
                style: AppText.w700(17, statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                AppDate.tanggalPenuhJam(h.transaksiTimestamp),
                textAlign: TextAlign.center,
                style: AppText.r(11, AppColors.dark.withValues(alpha: 0.5)),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildInfoCard(h),
          const SizedBox(height: 16),
          _buildItemsCard(),
          if (h.buktiViaManual.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFotoCard(h.buktiViaManual),
          ],
        ],
      ),
    );
  }

  Widget _buildFotoCard(String url) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 15, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Text(
                'Bukti Foto Nasabah',
                style: AppText.w700(13, AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LihatFotoScreen(
                  photoUrl: url,
                  nama: 'Bukti Foto Nasabah',
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: AppColors.green)),
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.divider,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.grey, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoCard(SetoranDetailHeader h) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.receipt_long_rounded, 'ID Setoran', h.setoranId),
          _divider(),
          _infoRow(Icons.person_rounded, 'Nasabah', h.namaNasabah),
          _divider(),
          _infoRow(Icons.badge_rounded, 'Petugas', h.namaPetugas),
          _divider(),
          _infoRow(Icons.inventory_2_rounded, 'Jumlah Item', '${h.totalItem} item sampah'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
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
                  style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                ),
                Text(
                  value,
                  style: AppText.w600(12, AppColors.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: AppColors.dark.withValues(alpha: 0.06), height: 1);

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Detail Item Sampah',
                style: AppText.w700(13, AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dark.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Nama Sampah',
                    style: AppText.w600(10, AppColors.dark),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: AppText.w600(10, AppColors.dark),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    'Satuan',
                    textAlign: TextAlign.right,
                    style: AppText.w600(10, AppColors.dark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isEven = i % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? Colors.transparent : AppColors.dark.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      item.namaSampah,
                      style: AppText.w500(11, AppColors.dark),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      _fmtQty(item.qty),
                      textAlign: TextAlign.center,
                      style: AppText.r(11, AppColors.dark.withValues(alpha: 0.7)),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      item.satuan,
                      textAlign: TextAlign.right,
                      style: AppText.r(11, AppColors.dark.withValues(alpha: 0.55)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error ?? 'Terjadi kesalahan',
        action: StateRetryButton(onPressed: _fetchDetail),
      );
}
