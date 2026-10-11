import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/services/barang_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';
import 'package:enviroo/widgets/state_message.dart';


class StrukDistribusiBarangScreen extends StatefulWidget {
  final String disbaId;
  const StrukDistribusiBarangScreen({super.key, required this.disbaId});

  @override
  State<StrukDistribusiBarangScreen> createState() =>
      _StrukDistribusiBarangScreenState();
}

class _StrukDistribusiBarangScreenState
    extends State<StrukDistribusiBarangScreen> {
  bool _loading = true;
  String? _error;
  DetailDistribusiBarangModel? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await BarangService.getDetailDistribusi(widget.disbaId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _detail = DetailDistribusiBarangModel.fromJson(
            res['data'] as Map<String, dynamic>);
        _loading = false;
      });
    } else {
      setState(() { _error = res['message']; _loading = false; });
    }
  }

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
              const TopBarBack(title: 'Detail Distribusi Barang'),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.green))
                    : _error != null
                        ? _buildError()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() => StateMessage(
        illustration: StateArt.error,
        message: _error!,
        action: StateRetryButton(onPressed: _load),
      );

  Widget _buildContent() {
    final d = _detail!;
    final status = d.statusDistribusi.toLowerCase();

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = AppColors.green;
        statusLabel = status == 'diterima' ? 'Diterima BSU' : 'Selesai';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'Menunggu Konfirmasi';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusLabel = d.statusDistribusi;
        statusIcon = Icons.info_outline_rounded;
    }

    final tanggal = '${AppDate.tanggalSingkatJam(d.createdAt)} WIB';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  statusLabel,
                  style: AppText.w700(17, statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${d.disbaId}',
                  textAlign: TextAlign.center,
                  style: AppText.r(11, AppColors.dark.withValues(alpha:0.45)),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha:0.06),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    tanggal,
                    style: AppText.r(10, AppColors.dark.withValues(alpha:0.45)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildInfoCard(d),
          const SizedBox(height: 16),

          _buildTotalCard(d),
          const SizedBox(height: 16),

          _buildItemsCard(d),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DetailDistribusiBarangModel d) {
    final status = d.statusDistribusi.toLowerCase();
    final Color statusColor;
    final String statusLabel;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = AppColors.green;
        statusLabel = status == 'diterima' ? 'Diterima' : 'Selesai';
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'Menunggu';
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusLabel = d.statusDistribusi;
    }

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
          _infoRow(Icons.store_rounded, 'BSI Pengirim', d.namaBsi),
          _divider(),
          _infoRow(Icons.house_rounded, 'BSU Penerima', d.namaBsu),
          _divider(),
          _infoRow(Icons.manage_accounts_rounded, 'Admin BSI', d.namaAdminBsi),
          _divider(),
          _infoRow(Icons.manage_accounts_rounded, 'Admin BSU', d.namaAdminBsu),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  status == 'selesai' || status == 'diterima'
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size: 15,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: AppText.r(10, AppColors.dark.withValues(alpha:0.45)),
                    ),
                    Text(
                      statusLabel,
                      style: AppText.w600(12, statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
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
              color: AppColors.green.withValues(alpha:0.08),
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
                  style: AppText.r(10, AppColors.dark.withValues(alpha:0.45)),
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

  Widget _divider() => Divider(color: AppColors.dark.withValues(alpha:0.06), height: 1);

  Widget _buildTotalCard(DetailDistribusiBarangModel d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _totalRow(
            icon: Icons.inventory_2_rounded,
            label: 'Total Item',
            value: '${d.totalItem.toInt()} item',
            valueColor: AppColors.green,
          ),
          Divider(color: AppColors.dark.withValues(alpha:0.06), height: 1),
          _totalRow(
            icon: Icons.stars_rounded,
            label: 'Total Poin Distribusi',
            value: AppNumber.denganSatuan(d.totalPoin, 'poin'),
            valueColor: AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _totalRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.green, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppText.w600(13, AppColors.dark),
              ),
            ],
          ),
          Text(
            value,
            style: AppText.w800(15, valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(DetailDistribusiBarangModel d) {
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
                'Item Barang',
                style: AppText.w700(13, AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (d.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Tidak ada item.',
                style: AppText.r(12, AppColors.dark.withValues(alpha:0.4)),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha:0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Nama Barang',
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      'Qty × Poin',
                      textAlign: TextAlign.center,
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Subtotal',
                      textAlign: TextAlign.right,
                      style: AppText.w600(10, AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            ...d.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isEven = i % 2 == 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : AppColors.dark.withValues(alpha:0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.namaBarang,
                        style: AppText.w500(11, AppColors.dark),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${AppNumber.desimal(item.item)} × ${AppNumber.desimal(item.nilaiPoin)} poin',
                        textAlign: TextAlign.center,
                        style: AppText.r(9.5, AppColors.dark.withValues(alpha: 0.6)),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${AppNumber.desimal(item.subtotalPoin)} poin',
                        textAlign: TextAlign.right,
                        style: AppText.w600(11, AppColors.green),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
