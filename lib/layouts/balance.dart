import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/services/dashboard_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum BalanceEntityType { nasabah, bank }

// ─── Data Model ─────────────────────────────────────────────────────────────

class _SaldoData {
  final double totalUang;
  final double totalPoin;
  final bool hasPoin;

  const _SaldoData({
    this.totalUang = 0,
    this.totalPoin = 0,
    this.hasPoin = true,
  });

  factory _SaldoData.fromJson(Map<String, dynamic> json) {
    final uang = json['uang'] as Map<String, dynamic>? ?? {};
    final poin = json['poin'] as Map<String, dynamic>?;
    return _SaldoData(
      totalUang: (uang['total_uang'] as num?)?.toDouble() ?? 0,
      totalPoin: (poin?['total_poin'] as num?)?.toDouble() ?? 0,
      hasPoin: poin != null,
    );
  }
}

// ─── Card Config ─────────────────────────────────────────────────────────────

class _CardConfig {
  final String label;
  final String Function(_SaldoData) primaryValue;
  final String primaryUnit;
  final IconData icon;
  final String bgImage;
  final Color accentColor;

  const _CardConfig({
    required this.label,
    required this.primaryValue,
    required this.primaryUnit,
    required this.icon,
    required this.bgImage,
    required this.accentColor,
  });
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class BalanceLayouts extends StatefulWidget {
  final BalanceEntityType entityType;

  const BalanceLayouts({super.key, this.entityType = BalanceEntityType.nasabah});

  @override
  State<BalanceLayouts> createState() => _BalanceLayoutState();
}

class _BalanceLayoutState extends State<BalanceLayouts>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  _SaldoData _saldo = const _SaldoData();
  bool _isLoading = true;
  int _currentPage = 0;
  final PageController _pageCtrl = PageController(viewportFraction: 1.0);

  DashboardProvider? _dashProvider;
  int _lastRefreshToken = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSaldo();
      _dashProvider = context.read<DashboardProvider>();
      _lastRefreshToken = _dashProvider!.saldoRefreshToken;
      _dashProvider!.addListener(_onSaldoRefresh);
    });
  }

  @override
  void dispose() {
    _dashProvider?.removeListener(_onSaldoRefresh);
    _animController.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onSaldoRefresh() {
    if (!mounted || _dashProvider == null) return;
    final token = _dashProvider!.saldoRefreshToken;
    if (token != _lastRefreshToken) {
      _lastRefreshToken = token;
      _fetchSaldo();
    }
  }

  Future<void> _fetchSaldo() async {
    final auth = context.read<AuthProvider>();
    final entityId = auth.identityId ?? '';
    if (entityId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final Map<String, dynamic> res;
    if (widget.entityType == BalanceEntityType.bank) {
      final bankId = auth.bankId ?? '';
      if (bankId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      res = await DashboardService.getSaldoBank(bankId);
    } else {
      res = await DashboardService.getSaldoNasabah(entityId);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true && res['data'] != null) {
          _saldo = _SaldoData.fromJson(res['data'] as Map<String, dynamic>);
        }
      });
      _animController.forward();
    }
  }

  static final _rupiah = NumberFormat.decimalPattern('id');
  static final _poin = NumberFormat.decimalPattern('id');

  List<_CardConfig> get _cards {
    final isBank = widget.entityType == BalanceEntityType.bank;
    final cards = <_CardConfig>[
      _CardConfig(
        label: isBank ? 'Kas Uang' : 'Saldo Uang',
        primaryValue: (s) => 'Rp ${_rupiah.format(s.totalUang)}',
        primaryUnit: '',
        icon: Icons.account_balance_wallet_rounded,
        bgImage: 'assets/images/bg_uang.webp',
        accentColor: const Color(0xFF94DF0C),
      ),
    ];
    if (_saldo.hasPoin) {
      cards.add(_CardConfig(
        label: isBank ? 'Kas Poin' : 'Saldo Poin',
        primaryValue: (s) => _poin.format(s.totalPoin),
        primaryUnit: 'poin',
        icon: Icons.stars_rounded,
        bgImage: 'assets/images/bg_poin.webp',
        accentColor: const Color(0xFF94DF0C),
      ));
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Swipeable card area ──────────────────────────
          AspectRatio(
            aspectRatio: 1200 / 380,
            child: _isLoading
                ? _buildSkeleton()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _cards.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (_, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _BalanceCard(
                            config: _cards[i],
                            saldo: _saldo,
                            isVisible: _isBalanceVisible,
                            onToggleVisibility: () {
                              setState(
                                  () => _isBalanceVisible = !_isBalanceVisible);
                              _fetchSaldo();
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // ── Page indicator ───────────────────────────────
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_cards.length, (i) {
              final isActive = i == _currentPage;
              final color = _cards[i].accentColor;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? color : color.withValues(alpha:0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFEEF0EF),
        ),
      ),
    );
  }
}

// ─── Individual Card ─────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final _CardConfig config;
  final _SaldoData saldo;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const _BalanceCard({
    required this.config,
    required this.saldo,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText = isVisible ? config.primaryValue(saldo) : '••••••';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(config.bgImage),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: config.accentColor.withValues(alpha:0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(config.icon,
                            color: config.accentColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        config.label,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onToggleVisibility,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        key: ValueKey(isVisible),
                        color: config.accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // ── Divider ──
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha:0.0),
                      Colors.white.withValues(alpha:0.10),
                      Colors.white.withValues(alpha:0.0),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Primary Value + Unit (satu baris) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      primaryText,
                      key: ValueKey('$isVisible-${config.label}'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (config.primaryUnit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        config.primaryUnit,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
