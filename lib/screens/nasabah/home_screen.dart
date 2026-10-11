import 'package:enviroo/core/format/app_number.dart';
import 'package:enviroo/layouts/balance.dart';
import 'package:enviroo/screens/bagi_hasil/list_bagi_hasil_nasabah_screen.dart';
import 'package:enviroo/layouts/informasi_layouts.dart';
import 'package:enviroo/layouts/jadwal_layouts.dart';
import 'package:enviroo/layouts/menu_layouts.dart';
import 'package:enviroo/core/network/network_status.dart';
import 'package:enviroo/models/bagi_hasil_bank_model.dart';
import 'package:enviroo/providers/auth_provider.dart';
import 'package:enviroo/providers/dashboard_provider.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/providers/penjualan_provider.dart' show FetchStatus;
import 'package:enviroo/providers/reward_provider.dart';
import 'package:enviroo/layouts/transaksi_layouts.dart';
import 'package:enviroo/widgets/navbar.dart';
import 'package:enviroo/widgets/topbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final _jadwalKey = GlobalKey<JadwalSetoranSectionState>();
  


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        if (auth.bankId != null) {
          Provider.of<KontenProvider>(context, listen: false).fetchKonten(
            auth.bankId!,
            published: true,
          );
        }
      }

      if (!mounted) return;
      _net = context.read<NetworkStatus>();
      _lastRecoveryToken = _net!.recoveryToken;
      _net!.addListener(_onNetworkRecovered);
    });
  }

  NetworkStatus? _net;
  int _lastRecoveryToken = 0;

  @override
  void dispose() {
    _net?.removeListener(_onNetworkRecovered);
    super.dispose();
  }

  void _onNetworkRecovered() {
    if (!mounted || _net == null) return;
    final token = _net!.recoveryToken;
    if (token == _lastRecoveryToken) return;
    _lastRecoveryToken = token;

    final auth = context.read<AuthProvider>();
    _jadwalKey.currentState?.refresh();
    context.read<DashboardProvider>().requestSaldoRefresh();
    if (auth.bankId != null) {
      context.read<KontenProvider>().fetchKonten(auth.bankId!, published: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: AppColors.mintSoft,
          body: SafeArea(
            child: Column(
              children: [
                const TopBarCustom(),
                MainNavbar(
                  selectedIndex: _selectedNavIndex,
                  onTabChanged: (index) {
                    setState(() => _selectedNavIndex = index);
                    if (index == 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _jadwalKey.currentState?.refresh();
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        if (auth.bankId != null) {
                          Provider.of<KontenProvider>(context, listen: false).fetchKonten(
                            auth.bankId!,
                            published: true,
                          );
                        }
                      });
                    } else if (index == 2 && _rewardFetched) {
                      _fetchRewardOverview();
                    }
                  },
                ),
                Expanded(
                  child: _selectedNavIndex == 0
                      ? RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            await Future.wait([
                              _jadwalKey.currentState?.refresh() ?? Future.value(),
                              if (auth.bankId != null)
                                Provider.of<KontenProvider>(context, listen: false).fetchKonten(
                                  auth.bankId!,
                                  published: true,
                                ),
                            ]);
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildHomeLayouts(),
                          ),
                        )
                      : _selectedNavIndex == 1
                      ? const TransaksiLayouts()
                      : _buildRewardLayouts(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeLayouts() {
    return Column(
      children: [
        SizedBox(height: 10),
        BalanceLayouts(),
        MainMenu(),
        JadwalSetoranSection(key: _jadwalKey),
        InformasiSection(),
        SizedBox(height: 50),
      ],
    );
  }

  bool _rewardLoading = true;
  String? _rewardError;
  List<PersenBagiHasilReward> _rewardUang = [];
  List<PersenBagiHasilReward> _rewardBarang = [];
  bool _rewardFetched = false;

  bool _rewardInFlight = false;

  Future<void> _fetchRewardOverview() async {
    if (_rewardInFlight) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId;

    if (bankId == null || bankId.isEmpty) {
      setState(() {
        _rewardError =
            'Data bank sampah kamu belum termuat. Coba lagi sebentar.';
        _rewardLoading = false;
        _rewardFetched = true;
      });
      return;
    }

    _rewardInFlight = true;
    setState(() {
      _rewardLoading = true;
      _rewardError = null;
    });

    final prov = context.read<RewardProvider>();
    await prov.fetchNilaiReward(bankId);

    if (!mounted) return;
    if (prov.nilaiStatus == FetchStatus.success) {
      final semua = prov.persenNasabah;
      setState(() {
        _rewardUang = semua
            .where((e) => e.namaReward.toLowerCase().contains('uang'))
            .toList();
        _rewardBarang = semua
            .where((e) => e.namaReward.toLowerCase().contains('barang'))
            .toList();
        _rewardLoading = false;
        _rewardFetched = true;
        _rewardInFlight = false;
      });
    } else {
      setState(() {
        _rewardError = prov.nilaiError ?? 'Gagal memuat data reward';
        _rewardLoading = false;
        _rewardFetched = true;
        _rewardInFlight = false;
      });
    }
  }

  Widget _buildRewardLayouts() {
    if (!_rewardFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRewardOverview());
    }

    if (_rewardLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (_rewardError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _rewardError!,
                textAlign: TextAlign.center,
                style: AppText.r(13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _fetchRewardOverview,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Program Bagi Hasil',
                style: AppText.w700(15, AppColors.dark),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih reward yang ingin kamu lihat riwayat bagi hasilnya.',
                style: AppText.p(12, color: AppColors.dark.withValues(alpha: 0.55), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._rewardUang.isNotEmpty
                      ? _rewardUang.map((r) => _RewardCard(reward: r, type: _RewardType.uang))
                      : [const _RewardCard(type: _RewardType.uang)],
                  ..._rewardBarang.isNotEmpty
                      ? _rewardBarang.map((r) => _RewardCard(reward: r, type: _RewardType.barang))
                      : [const _RewardCard(type: _RewardType.barang)],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _RewardType { uang, barang }

class _RewardCard extends StatelessWidget {
  final PersenBagiHasilReward? reward;
  final _RewardType type;
  const _RewardCard({
    this.reward,
    required this.type,
  });

  bool get notAvailable => reward == null;

  Color get _accent {
    switch (type) {
      case _RewardType.uang:
        return const Color(0xFF3A8C5C);
      case _RewardType.barang:
        return const Color(0xFF3A8C5C);
    }
  }


  String get _labelSaldo {
    final s = (reward?.satuan ?? '').toLowerCase();
    if (s.contains('poin')) return 'Saldo Poin';
    if (s.contains('rp') || s.contains('rupiah')) return 'Saldo Rupiah';
    return type == _RewardType.barang ? 'Saldo Poin' : 'Saldo Rupiah';
  }

  String get _labelInsentif {
    final n = reward?.namaReward ?? '';
    if (n.isEmpty) {
      return type == _RewardType.barang ? 'Insentif Barang' : 'Insentif Uang';
    }
    return 'Insentif ${n[0].toUpperCase()}${n.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final r = reward;
    final deskripsi = r?.deskripsi ?? '';
    final persen = r?.persenBagiHasil ?? 0.0;
    final isActive = r?.isActive ?? false;

    return GestureDetector(
      onTap: notAvailable
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListBagiHasilNasabahScreen(
                    initialTab: switch (type) {
                      _RewardType.uang => 0,
                      _RewardType.barang => 1,
                    },
                  ),
                ),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDEDED), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              Positioned(
                top: -45,
                right: -45,
                child: Container(
                  width: 130,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (notAvailable ? const Color(0xFFCCCCCC) : _accent)
                        .withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (notAvailable || !isActive)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9E9E9E)
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 22,
                              color: Color(0xFF9E9E9E),
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatPersen(persen),
                                style: AppText.p(30, weight: FontWeight.w800, color: _accent, height: 1, letterSpacing: -1.5),
                              ),
                              Text(
                                '%',
                                style: AppText.w700(16, _accent),
                              ),
                            ],
                          ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _labelSaldo,
                                style: AppText.p(16, weight: FontWeight.w700, color: notAvailable
                                      ? const Color(0xFF9E9E9E)
                                      : AppColors.dark, height: 1.25, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3A8C5C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child:
                                Text(
                                  _labelInsentif,
                                  style: AppText.p(11, weight: FontWeight.w500, color: AppColors.dark, height: 1.3),
                              ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        deskripsi,
                        style: AppText.p(11.5, color: Color(0xFF888888), height: 1.4),
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (notAvailable)
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bank sampah kamu belum menerapkan sistem reward ini untuk nasabah',
                              style: AppText.p(11, color: Colors.grey[500], height: 1.5),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lihat riwayat bagi hasil '
                              '${_labelSaldo.toLowerCase()}',
                              style: AppText.p(12, weight: FontWeight.w700, color: _accent, height: 1.4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 15, color: _accent),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPersen(double v) => AppNumber.desimal(v);
}
