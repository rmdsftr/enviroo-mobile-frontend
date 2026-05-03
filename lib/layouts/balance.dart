import 'package:enviroo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BalanceLayouts extends StatefulWidget {
  @override
  State<BalanceLayouts> createState() => _BalanceLayoutState();
}

class _BalanceLayoutState extends State<BalanceLayouts>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF014D52),
                Color(0xFF013236),
                Color(0xFF01252A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative background circle — top right
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
                // Decorative background circle — bottom left
                Positioned(
                  bottom: -30,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF94DF0C).withOpacity(0.06),
                    ),
                  ),
                ),

                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Top row: title + eye toggle ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Saldo Kamu",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFFFFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                key: ValueKey(_isBalanceVisible),
                                color: const Color(0xFF94DF0C),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Divider ──
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Dual balance: Saldo Poin & No. Rekening ──
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final fPoin = NumberFormat.decimalPattern('id');
                          return Row(
                            children: [
                              Expanded(
                                child: _PrimaryBalanceTile(
                                  icon: Icons.stars_rounded,
                                  label: "Saldo Poin",
                                  value: fPoin.format(auth.saldoPoin).replaceAll(',', '.'),
                                  isVisible: _isBalanceVisible,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _PrimaryBalanceTile(
                                  icon: Icons.credit_card_rounded,
                                  label: "No. Rekening",
                                  value: auth.nomorRekening,
                                  isVisible: true,
                                  alignment: CrossAxisAlignment.end,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBalanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isVisible;
  final CrossAxisAlignment alignment;

  const _PrimaryBalanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isVisible,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = alignment == CrossAxisAlignment.end;

    return Padding(
      padding: EdgeInsets.only(
        left: isRight ? 20 : 0,
        right: isRight ? 0 : 20,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Icon + label row
          Row(
            mainAxisAlignment:
            isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF94DF0C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF94DF0C), size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFFFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Primary value
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              isVisible ? value : "••••••",
              key: ValueKey(isVisible),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
