import 'package:enviroo/models/transaksi_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransaksiCard extends StatefulWidget {
  final Transaksi transaksi;

  const TransaksiCard({Key? key, required this.transaksi}) : super(key: key);

  @override
  State<TransaksiCard> createState() => _TransaksiCardState();
}

class _TransaksiCardState extends State<TransaksiCard> {
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

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.transaksi.isSuccess;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Color(0xFF013236).withOpacity(0.5)
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
                        color: isSuccess 
                            ? const Color(0xFF06C0C9).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_rounded : Icons.close_rounded,
                        color: isSuccess ? const Color(0xFF06C0C9) : Colors.red,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Date & status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(widget.transaksi.tanggal),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF013236),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSuccess ? 'Berhasil' : 'Gagal',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSuccess 
                                  ? const Color(0xFF06C0C9)
                                  : Colors.red,
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
    final transaksi = widget.transaksi;
    
    if (transaksi.type == 'penarikan') {
      return _buildPenarikanContent();
    }
    
    if (!transaksi.isSuccess) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Transaksi gagal diproses',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    final uangItems = transaksi.items.where((i) => i.nilaiType == NilaiType.uang).toList();
    final poinItems = transaksi.items.where((i) => i.nilaiType == NilaiType.poin).toList();
    
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Petugas
          if (transaksi.petugasName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: const Color(0xFF013236).withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Dilayani oleh ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: const Color(0xFF013236).withOpacity(0.6),
                  ),
                ),
                Text(
                  transaksi.petugasName!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          
          // Items container
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Uang items
                if (uangItems.isNotEmpty) ...[
                  ...uangItems.asMap().entries.map((e) => 
                    _buildItemRow(e.value, isLast: e.key == uangItems.length - 1 && poinItems.isEmpty)),
                  _buildTotalRow('Total uang', _formatCurrency(transaksi.totalUang), const Color(0xFF013236)),
                ],
                
                // Poin items
                if (poinItems.isNotEmpty) ...[
                  if (uangItems.isNotEmpty)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFF013236).withOpacity(0.06),
                    ),
                  ...poinItems.asMap().entries.map((e) => 
                    _buildItemRow(e.value, isLast: e.key == poinItems.length - 1)),
                  _buildTotalRow('Total poin', _formatCurrency(transaksi.totalPoin), const Color(0xFF013236)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenarikanContent() {
    final transaksi = widget.transaksi;
    final amount = getPenarikanAmount(transaksi);
    
    if (!transaksi.isSuccess) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Penarikan gagal diproses',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF013236).withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (transaksi.petugasName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: const Color(0xFF013236).withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Diproses oleh ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: const Color(0xFF013236).withOpacity(0.6),
                  ),
                ),
                Text(
                  transaksi.petugasName!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF013236).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah Penarikan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: const Color(0xFF013236).withOpacity(0.7),
                  ),
                ),
                Text(
                  'Rp${_formatCurrency(amount)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF013236),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(TransaksiItem item, {bool isLast = false}) {
    final isUang = item.nilaiType == NilaiType.uang;
    
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
            width: 60,
            child: Text(
              item.jumlah,
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
              _formatCurrency(item.nilai),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUang ? const Color(0xFF013236) : const Color(0xFF013236),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
