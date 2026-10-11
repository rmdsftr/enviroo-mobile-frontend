import 'package:enviroo/core/format/app_number.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class StatistikSection extends StatelessWidget {
  final int jumlahJenisSampah = 4;
  final double totalBeratKg = 12.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statistik Bulan Ini",
            style: AppText.w600(15),
          ),
          SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [AppColors.green, AppColors.dark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "$jumlahJenisSampah",
                          style: AppText.w700(28, Colors.white),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Jenis Sampah",
                        style: AppText.r(11, Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [AppColors.green, AppColors.dark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          AppNumber.desimal(totalBeratKg),
                          style: AppText.w700(28, Colors.white),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Kg Disetorkan",
                        style: AppText.r(11, Colors.grey[600]),
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
}


