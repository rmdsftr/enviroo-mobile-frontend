import 'package:enviroo/models/penarikan_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PenarikanPoinCard extends StatefulWidget {
  final PenarikanPoin penarikan;

  const PenarikanPoinCard({Key? key, required this.penarikan}) : super(key: key);

  @override
  State<PenarikanPoinCard> createState() => _PenarikanPoinCardState();
}

class _PenarikanPoinCardState extends State<PenarikanPoinCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month]} ${date.year}  ${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###', 'id_ID').format(number);
  }

  Color _getStatusColor() {
    switch (widget.penarikan.status) {
      case PenarikanPoinStatus.selesai:
        return const Color(0xFF4EA771);
      case PenarikanPoinStatus.menungguPersetujuan:
        return const Color(0xFFFF9800);
      case PenarikanPoinStatus.menungguPenjemputan:
        return Colors.blue;
      case PenarikanPoinStatus.ditolak:
        return Colors.red;
      case PenarikanPoinStatus.dibatalkan:
        return const Color(0xFF7C41CF);
    }
  }

  String _getStatusText() {
    switch (widget.penarikan.status) {
      case PenarikanPoinStatus.selesai:
        return 'Selesai';
      case PenarikanPoinStatus.menungguPersetujuan:
        return 'Menunggu Persetujuan';
      case PenarikanPoinStatus.menungguPenjemputan:
        return 'Menunggu Penjemputan';
      case PenarikanPoinStatus.ditolak:
        return 'Ditolak';
      case PenarikanPoinStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.penarikan.status) {
      case PenarikanPoinStatus.selesai:
        return Icons.check_rounded;
      case PenarikanPoinStatus.menungguPersetujuan:
        return Icons.access_time_rounded;
      case PenarikanPoinStatus.menungguPenjemputan:
        return Icons.local_shipping_rounded;
      case PenarikanPoinStatus.ditolak:
        return Icons.close_rounded;
      case PenarikanPoinStatus.dibatalkan:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: const Color(0xFF4EA771).withOpacity(0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Status & total poin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatNumber(widget.penarikan.totalPoin)} Poin',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isExpanded ? 0.5 : 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF013236).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF013236).withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Expanded content
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: const Color(0xFF013236).withOpacity(0.08),
                  ),
                  _buildExpandedContent(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final penarikan = widget.penarikan;
    
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal Diajukan
          _buildInfoRow(Icons.calendar_today_rounded, 'Tanggal Diajukan', _formatDate(penarikan.tanggalDiajukan)),
          
          // Tanggal Disetujui (untuk status selesai & menunggu penjemputan)
          if ((penarikan.status == PenarikanPoinStatus.selesai || 
               penarikan.status == PenarikanPoinStatus.menungguPenjemputan) && 
               penarikan.tanggalDisetujui != null)
            _buildInfoRow(Icons.check_circle_outline, 'Tanggal Disetujui', _formatDate(penarikan.tanggalDisetujui!)),
          
          // Tanggal Ditolak (untuk status ditolak)
          if (penarikan.status == PenarikanPoinStatus.ditolak && penarikan.tanggalDitolak != null)
            _buildInfoRow(Icons.cancel_outlined, 'Tanggal Ditolak', _formatDate(penarikan.tanggalDitolak!)),
          
          // Tanggal Dibatalkan (untuk status dibatalkan)
          if (penarikan.status == PenarikanPoinStatus.dibatalkan && penarikan.tanggalDibatalkan != null)
            _buildInfoRow(Icons.cancel_outlined, 'Tanggal Dibatalkan', _formatDate(penarikan.tanggalDibatalkan!)),
          
          const SizedBox(height: 12),
          
          // Detail Barang Sembako
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Barang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF013236).withOpacity(0.6),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF013236).withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Poin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF013236).withOpacity(0.6),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                // Items
                ...penarikan.items.map((item) => _buildSembakoItemRow(item)),
                // Total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF013236).withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Poin',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF013236),
                        ),
                      ),
                      Text(
                        _formatNumber(penarikan.totalPoin),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF013236),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Pesan untuk Menunggu Penjemputan
          if (penarikan.status == PenarikanPoinStatus.menungguPenjemputan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                // border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: const Color(0xFF4CAF50).withOpacity(0.8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tunjukkan bukti transaksi ini ketika menjemput barang ke BSI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: const Color(0xFF013236).withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Alasan Penolakan (untuk status ditolak)
          if (penarikan.status == PenarikanPoinStatus.ditolak && penarikan.pesanAdmin != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                // border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.red.withOpacity(0.8)),
                      const SizedBox(width: 8),
                      Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    penarikan.pesanAdmin!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: const Color(0xFF013236).withOpacity(0.7),
                    ),
                  ),
                  if (penarikan.adminName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '— ${penarikan.adminName}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF013236).withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF013236).withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: const Color(0xFF013236).withOpacity(0.6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSembakoItemRow(SembakoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.nama,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${item.qty}x',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: const Color(0xFF013236).withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              _formatNumber(item.qty * item.poin),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013236),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
