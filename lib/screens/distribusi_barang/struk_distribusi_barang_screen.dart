import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/services/barang_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _C {
  static const dark  = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const cardBg = Color(0xFFF7FBF5);
  static const danger = Color(0xFFD94848);
}

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
      backgroundColor: const Color(0xFFF5F7F5),
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
                        child: CircularProgressIndicator(color: _C.green))
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

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: _C.danger.withValues(alpha:0.5)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withValues(alpha:0.5),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
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

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    final d = _detail!;
    final status = d.statusDistribusi.toLowerCase();

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = _C.green;
        statusLabel = status == 'diterima' ? 'Diterima BSU' : 'Selesai';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Menunggu Konfirmasi';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusLabel = d.statusDistribusi;
        statusIcon = Icons.info_outline_rounded;
    }

    final fmt = NumberFormat('#,##0.##', 'id_ID');
    final tanggal =
        '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d.createdAt)} WIB';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          // ── Hero Header ──────────────────────────────────────────────────
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
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${d.disbaId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: _C.dark.withValues(alpha:0.45),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.dark.withValues(alpha:0.06),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    tanggal,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: _C.dark.withValues(alpha:0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info Card ────────────────────────────────────────────────────
          _buildInfoCard(d),
          const SizedBox(height: 16),

          // ── Total Poin Card ──────────────────────────────────────────────
          _buildTotalCard(d, fmt),
          const SizedBox(height: 16),

          // ── Items Card ───────────────────────────────────────────────────
          _buildItemsCard(d, fmt),
        ],
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard(DetailDistribusiBarangModel d) {
    final status = d.statusDistribusi.toLowerCase();
    final Color statusColor;
    final String statusLabel;

    switch (status) {
      case 'selesai':
      case 'diterima':
        statusColor = _C.green;
        statusLabel = status == 'diterima' ? 'Diterima' : 'Selesai';
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
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
                  color: _C.green.withValues(alpha:0.08),
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _C.dark.withValues(alpha:0.45),
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: statusColor,
                      ),
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
              color: _C.green.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: _C.dark.withValues(alpha:0.45),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _C.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: _C.dark.withValues(alpha:0.06), height: 1);

  // ── Total Poin Card ────────────────────────────────────────────────────────
  Widget _buildTotalCard(DetailDistribusiBarangModel d, NumberFormat fmt) {
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
            valueColor: _C.green,
            fmt: null,
          ),
          Divider(color: _C.dark.withValues(alpha:0.06), height: 1),
          _totalRow(
            icon: Icons.stars_rounded,
            label: 'Total Poin Distribusi',
            value: '${fmt.format(d.totalPoin)} poin',
            valueColor: _C.green,
            fmt: null,
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
    NumberFormat? fmt,
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
                  color: _C.green.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _C.green, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Items Card ─────────────────────────────────────────────────────────────
  Widget _buildItemsCard(DetailDistribusiBarangModel d, NumberFormat fmt) {
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
            children: const [
              Icon(Icons.list_alt_rounded, color: _C.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Item Barang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (d.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Tidak ada item.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _C.dark.withValues(alpha:0.4),
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.dark.withValues(alpha:0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Nama Barang',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      'Qty × Poin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Subtotal',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Table rows
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
                      : _C.dark.withValues(alpha:0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.namaBarang,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _C.dark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${fmt.format(item.item)} × ${fmt.format(item.nilaiPoin)} poin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          color: _C.dark.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${fmt.format(item.subtotalPoin)} poin',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.green,
                        ),
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
