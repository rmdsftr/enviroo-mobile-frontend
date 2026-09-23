import 'package:flutter/material.dart';

/// Lebar yang dituju untuk tiap item menu. Dipakai apa adanya selama masih
/// muat; kalau item-nya banyak sampai melebihi lebar layar, tiap item menyusut
/// rata supaya bar tidak pernah jebol lewat tepi.
///
/// Naikkan angka ini kalau menu terasa terlalu sempit.
const double _lebarItemIdeal = 100;

const double _kTinggiBar = 66;
const double _kMarginBawahBar = 15;

/// Ruang vertikal yang ditempati bar ini, **di luar** safe area.
///
/// Bar dipasang melayang di atas konten — lihat `Positioned(bottom: 0)` di
/// beranda petugas — jadi layar tab yang tampil di baliknya harus menambahkan
/// nilai ini, plus `MediaQuery.of(context).padding.bottom`, ke padding bawah
/// area scroll-nya. Tanpa itu, isi paling bawah tertutup bar.
const double kRuangBottomBar = _kTinggiBar + _kMarginBawahBar;

/// Model untuk merepresentasikan satu item pada [BottomBarCustom].
class BottomBarItem {
  final IconData icon;
  final String label;

  const BottomBarItem({
    required this.icon,
    required this.label,
  });
}


class BottomBarCustom extends StatelessWidget {
  /// Daftar item yang ditampilkan pada bottom bar.
  final List<BottomBarItem> items;

  /// Index item yang sedang aktif.
  final int currentIndex;

  /// Callback saat user menekan salah satu item.
  final ValueChanged<int> onTap;

  /// Warna utama untuk icon, label, dan highlight.
  final Color primaryColor;

  /// Warna background bar.
  final Color backgroundColor;

  /// Margin dari tepi layar (untuk efek floating).
  final EdgeInsetsGeometry margin;

  /// Tinggi konten di dalam bar.
  final double height;

  /// Ukuran icon.
  final double iconSize;

  const BottomBarCustom({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.primaryColor = const Color(0xFF013236),
    this.backgroundColor = Colors.white,
    this.margin = const EdgeInsets.fromLTRB(15, 0, 15, _kMarginBawahBar),
    this.height = _kTinggiBar,
    this.iconSize = 23,
  })  : assert(items.length >= 2, 'Minimal harus ada 2 item'),
        assert(currentIndex >= 0, 'currentIndex tidak valid');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: Center(
          // Center + Row(mainAxisSize.min) membuat lebar bar mengikuti jumlah
          // item, bukan selebar layar. Dulu tiap item dibungkus Expanded, jadi
          // bar selalu melar penuh — menu 2 item pun tampil selebar menu 4 item.
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
              border : Border.all(
                color: const Color(0xFF013236).withOpacity(0.1),
                width: 1,
              )
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Lebar item dipatok eksplisit, bukan dibiarkan mengikuti isi
                  // (yang cuma ~46px — terlalu sempit). Tapi dibatasi ruang yang
                  // ada, supaya menu 4 item di BSI/BSU tidak jebol lewat tepi
                  // layar sempit. Menu 2 item dapat lebar penuh _lebarItemIdeal.
                  final muat = constraints.maxWidth / items.length;
                  final lebarItem =
                      _lebarItemIdeal < muat ? _lebarItemIdeal : muat;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (index) {
                      final isActive = index == currentIndex;
                      return SizedBox(
                        width: lebarItem,
                        child: _BottomBarItemWidget(
                          item: items[index],
                          isActive: isActive,
                          color: primaryColor,
                          iconSize: iconSize,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItemWidget extends StatelessWidget {
  final BottomBarItem item;
  final bool isActive;
  final Color color;
  final double iconSize;
  final VoidCallback onTap;

  const _BottomBarItemWidget({
    required this.item,
    required this.isActive,
    required this.color,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Background highlight untuk item aktif.
    final Color activeBg = color.withOpacity(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          // Lebar item ditentukan SizedBox di induknya, jadi padding ini cuma
          // jarak aman supaya label tidak menempel tepi saat ter-ellipsis.
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: iconSize,
                color: color,
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.0,
                  fontFamily: 'Poppins',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}