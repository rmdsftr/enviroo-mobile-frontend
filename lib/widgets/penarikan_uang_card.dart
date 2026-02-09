import 'package:enviroo/models/penarikan_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PenarikanUangCard extends StatefulWidget {
  final PenarikanUang penarikan;

  const PenarikanUangCard({Key? key, required this.penarikan}) : super(key: key);

  @override
  State<PenarikanUangCard> createState() => _PenarikanUangCardState();
}

class _PenarikanUangCardState extends State<PenarikanUangCard> {
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

  String _formatCurrency(int amount) {
    return NumberFormat('#,###', 'id_ID').format(amount);
  }

  Color _getStatusColor() {
    switch (widget.penarikan.status) {
      case PenarikanUangStatus.selesai:
        return const Color(0xFF06C0C9);
      case PenarikanUangStatus.menungguPersetujuan:
        return const Color(0xFFFF9800);
      case PenarikanUangStatus.ditolak:
        return Colors.red;
      case PenarikanUangStatus.dibatalkan:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusText() {
    switch (widget.penarikan.status) {
      case PenarikanUangStatus.selesai:
        return 'Selesai';
      case PenarikanUangStatus.menungguPersetujuan:
        return 'Menunggu Persetujuan';
      case PenarikanUangStatus.ditolak:
        return 'Ditolak';
      case PenarikanUangStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  IconData _getStatusIcon() {
    switch (widget.penarikan.status) {
      case PenarikanUangStatus.selesai:
        return Icons.check_rounded;
      case PenarikanUangStatus.menungguPersetujuan:
        return Icons.access_time_rounded;
      case PenarikanUangStatus.ditolak:
        return Icons.close_rounded;
      case PenarikanUangStatus.dibatalkan:
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Status & amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp${_formatCurrency(widget.penarikan.saldoDicairkan)}',
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
          
          // Tanggal Disetujui (untuk status selesai)
          if (penarikan.status == PenarikanUangStatus.selesai && penarikan.tanggalDisetujui != null)
            _buildInfoRow(Icons.check_circle_outline, 'Tanggal Disetujui', _formatDate(penarikan.tanggalDisetujui!)),
          
          // Tanggal Ditolak (untuk status ditolak)
          if (penarikan.status == PenarikanUangStatus.ditolak && penarikan.tanggalDitolak != null)
            _buildInfoRow(Icons.cancel_outlined, 'Tanggal Ditolak', _formatDate(penarikan.tanggalDitolak!)),
          
          // Tanggal Dibatalkan (untuk status dibatalkan)
          if (penarikan.status == PenarikanUangStatus.dibatalkan && penarikan.tanggalDibatalkan != null)
            _buildInfoRow(Icons.cancel_outlined, 'Tanggal Dibatalkan', _formatDate(penarikan.tanggalDibatalkan!)),
          
          const SizedBox(height: 12),
          
          // Detail Saldo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Saldo Dicairkan', 'Rp${_formatCurrency(penarikan.saldoDicairkan)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Metode Transfer', penarikan.metodeTransfer),
              ],
            ),
          ),
          
          // Bukti Transfer (untuk status selesai)
          if (penarikan.status == PenarikanUangStatus.selesai && penarikan.buktiTransfer != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Show bukti transfer image
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Lihat Bukti Transfer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06C0C9),
                  side: const BorderSide(color: Color(0xFF06C0C9)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          
          // Alasan Penolakan (untuk status ditolak)
          if (penarikan.status == PenarikanUangStatus.ditolak && penarikan.alasanPenolakan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
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
                    penarikan.alasanPenolakan!,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: const Color(0xFF013236).withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF013236),
          ),
        ),
      ],
    );
  }
}
