import 'package:enviroo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class JadwalBsuMendatangScreen extends StatefulWidget {
  @override
  State<JadwalBsuMendatangScreen> createState() => _JadwalMendatangState();
}

class _JadwalMendatangState extends State<JadwalBsuMendatangScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(auth.role == "admin_bsu")
            Column(
              children: [
                _buildSectionHeader(
                  title: "Penimbangan",
                ),
                const SizedBox(height: 10),
                _buildGroupCard(
                  items: [
                    _ScheduleItem(
                      date: "Senin, 18 Februari 2026",
                      time: "08:00 - 10:00",
                      status: "Terjadwal",
                      statusColor: const Color(0xFF4EA771),
                    ),
                    _ScheduleItem(
                      date: "Kamis, 21 Februari 2026",
                      time: "08:00 - 10:00",
                      status: "Terjadwal",
                      statusColor: const Color(0xFF4EA771),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Header 2
          _buildSectionHeader(
            title: "Pengangkutan",
          ),
          const SizedBox(height: 10),

          // Card 2
          _buildGroupCard(
            items: [
              _ScheduleItem(
                date: "Hari ini",
                time: "10.00 - 11.00",
                status: "Dalam Perjalanan",
                statusColor: const Color(0xFFFF9800),
                isActive: true,
              ),
              _ScheduleItem(
                date: "Senin, 20 Februari 2026",
                time: "14:00 - 16:00",
                status: "Mendatang",
                statusColor: const Color(0xFF4EA771),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard({required List<_ScheduleItem> items}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF013236).withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 4),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFF013236).withOpacity(0.06),
                  indent: 18,
                  endIndent: 18,
                ),
                itemBuilder: (context, index) =>
                    _buildScheduleRow(items[index]),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(_ScheduleItem item) {
    return Container(
      color: item.isActive
          ? item.statusColor.withOpacity(0.04)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 3.5,
            height: 36,
            decoration: BoxDecoration(
              color: item.isActive
                  ? item.statusColor
                  : item.statusColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 13),

          // Date & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013236),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: const Color(0xFF013236).withOpacity(0.38),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF013236).withOpacity(0.42),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  item.status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.statusColor,
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

class _ScheduleItem {
  final String date;
  final String time;
  final String status;
  final Color statusColor;
  final bool isActive;

  const _ScheduleItem({
    required this.date,
    required this.time,
    required this.status,
    required this.statusColor,
    this.isActive = false,
  });
}
