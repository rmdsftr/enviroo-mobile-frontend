import 'package:enviroo/providers/katalog_provider.dart';
import 'package:enviroo/screens/penarikan_screen.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg     = Color(0xFFFFFFFF); // Clean white background
  static const dark   = Color(0xFF013236); // Primary Dark
  static const green  = Color(0xFF4EA771); // Primary Green
  static const lime   = Color(0xFF94DF0C); // Secondary Lime
  static const card   = Color(0xFFFFFFFF);
  static const mute   = Color(0xFF64748B);
}

class KonversiScreen extends StatelessWidget {
  const KonversiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            const TopBarBack(title: "Konversi Poin"),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero text ──────────────────────────────────────────
                    _buildHeroSection(),
                    const SizedBox(height: 28),

                    // ── Konversi Uang ──────────────────────────────────────
                    _buildUangCard(context),
                    const SizedBox(height: 16),

                    // ── Konversi Sembako ───────────────────────────────────
                    _buildSembakoCard(context),
                    const SizedBox(height: 16),

                    // ── Konversi Emas ──────────────────────────────────────
                    _buildEmasCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pilih jenis konversi sesuai kebutuhan kamu",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: _C.mute,
          ),
        ),
      ],
    );
  }

  // ── Uang Card ───────────────────────────────────────────────────────────────
  Widget _buildUangCard(BuildContext context) {
    return _ConversionCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PenarikanScreen(type: PenarikanType.uang)));
      },
      accentColor: _C.dark,
      icon: Icons.account_balance_wallet_rounded,
      tag: "Pencairan Dana",
      title: "Konversi ke Uang",
      subtitle: "Cairkan poin ke saldo uang via transfer bank atau e-wallet",
      rate: "1.000 poin = Rp 10.000",
      rateIcon: Icons.monetization_on_rounded,
      actionLabel: "Cairkan Sekarang",
    );
  }

  // ── Sembako Card ─────────────────────────────────────────────────────────────
  Widget _buildSembakoCard(BuildContext context) {
    return Consumer<KatalogProvider>(
      builder: (context, katalog, _) {
        final sembakoList = katalog.katalogSembako;
        return _ConversionCard(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PenarikanScreen(type: PenarikanType.sembako)));
          },
          accentColor: _C.green,
          icon: Icons.shopping_basket_rounded,
          tag: "Penukaran Sembako",
          title: "Konversi ke Sembako",
          subtitle: "Tukar poin dengan kebutuhan pokok — beras, minyak, gula & lebih",
          rate: "${sembakoList.isEmpty ? '0' : sembakoList.length} item tersedia",
          rateIcon: Icons.storefront_rounded,
          actionLabel: "Lihat Katalog",
          previewItems: sembakoList.take(4).map((s) => s.photoUrl).toList(),
        );
      },
    );
  }

  // ── Emas Card ────────────────────────────────────────────────────────────────
  Widget _buildEmasCard(BuildContext context) {
    return _ConversionCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PenarikanScreen(type: PenarikanType.emas)));
      },
      accentColor: const Color(0xFFD4A017), // A bit of gold for Emas
      icon: Icons.auto_awesome_rounded,
      tag: "Segera Hadir",
      title: "Konversi ke Emas",
      subtitle: "Investasi emas digital dari poin tabungan sampahmu",
      rate: "1 gram = 50.000 poin",
      rateIcon: Icons.diamond_rounded,
      actionLabel: "Lihat Detail",
      comingSoon: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable white conversion card
// ─────────────────────────────────────────────────────────────────────────────
class _ConversionCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final IconData icon;
  final String tag;
  final String title;
  final String subtitle;
  final String rate;
  final IconData rateIcon;
  final String actionLabel;
  final bool comingSoon;
  final List<String> previewItems;

  const _ConversionCard({
    required this.onTap,
    required this.accentColor,
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.rate,
    required this.rateIcon,
    required this.actionLabel,
    this.comingSoon = false,
    this.previewItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.dark.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: _C.dark.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle background accent
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.03),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: comingSoon ? Colors.amber.withOpacity(0.12) : _C.lime.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: comingSoon ? const Color(0xFFB48A00) : _C.dark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Info Section ───────────────────────────────────────
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _C.dark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: _C.mute,
                        height: 1.4,
                      ),
                    ),

                    // ── Sembako items list ─────────────────────────────────
                    if (previewItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: previewItems.length,
                          itemBuilder: (context, i) {
                            final url = previewItems[i];
                            return Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.dark.withOpacity(0.05)),
                                color: _C.bg,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: url.isNotEmpty
                                    ? Image.network(url, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.shopping_basket_rounded, color: _C.mute, size: 20))
                                    : const Icon(Icons.shopping_basket_rounded, color: _C.mute, size: 20),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    
                    // Divider
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: _C.dark.withOpacity(0.05),
                    ),
                    const SizedBox(height: 16),

                    // ── Rate row ───────────────────────────────────────────
                    Row(
                      children: [
                        Icon(rateIcon, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rate,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _C.dark,
                            ),
                          ),
                        ),
                        Text(
                          actionLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: comingSoon ? _C.mute.withOpacity(0.5) : _C.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: comingSoon ? _C.mute.withOpacity(0.5) : _C.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
