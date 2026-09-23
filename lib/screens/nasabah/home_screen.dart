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
    // Sengaja TIDAK memanggil auth.fetchNasabahProfile() di sini: keempat jalan
    // menuju HomeScreen (splash, login, role_options, switch role di profil)
    // baru saja menjalankan bootstrap yang mengambil profil sesi. initState juga
    // tidak jalan lagi saat layar di-pop, jadi panggilan di sini hanya menjadi
    // request kedua ke endpoint yang sama. Beranda pun tidak menampilkan apa pun
    // dari profil itu — saldo ditarik sendiri oleh BalanceLayouts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.role == 'nasabah') {
        // Fetch konten informasi
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

  // ─── Muat ulang otomatis saat jaringan pulih ───────────────────────────────
  //
  // Menutup NoConnectionScreen saja tidak cukup: layar ini di baliknya masih
  // menampilkan data gagal-muat dari waktu offline tadi. Tanpa bagian ini, user
  // balik ke beranda yang tampak kosong dan harus tarik-segarkan sendiri.

  NetworkStatus? _net;
  int _lastRecoveryToken = 0;

  @override
  void dispose() {
    // WAJIB — NetworkStatus itu singleton yang hidup seumur app; listener yang
    // bocor akan menembak di widget yang sudah mati.
    _net?.removeListener(_onNetworkRecovered);
    super.dispose();
  }

  void _onNetworkRecovered() {
    if (!mounted || _net == null) return;
    // Bandingkan token, jangan sekadar "ada notifikasi": NetworkStatus juga
    // notify saat offline MENYALA, dan itu tidak boleh memicu fetch.
    final token = _net!.recoveryToken;
    if (token == _lastRecoveryToken) return;
    _lastRecoveryToken = token;

    final auth = context.read<AuthProvider>();
    _jadwalKey.currentState?.refresh();
    // BalanceLayouts punya jalur refresh sendiri lewat saldoRefreshToken.
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
          backgroundColor: Color(0xFFEAF8E7),
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
                          color: const Color(0xFF4EA771),
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
  // New structure: separate lists per reward type
  List<PersenBagiHasilReward> _rewardUang = [];
  List<PersenBagiHasilReward> _rewardBarang = [];
  bool _rewardFetched = false;

  /// Penjaga permintaan ganda.
  ///
  /// `build()` menjadwalkan fetch lewat post-frame callback selama
  /// [_rewardFetched] masih false, sementara tombol "Coba lagi" juga memanggil
  /// langsung. Karena [_rewardFetched] baru jadi true di AKHIR fetch, sekali
  /// tekan tombol itu dulu berangkat dua permintaan sekaligus.
  bool _rewardInFlight = false;

  /// Persentase bagi hasil per jenis insentif, diambil dari
  /// `GET /nilai-reward/get/:bank_id`. Datanya per-BANK, bukan per-nasabah —
  /// provider sudah menyaring `level_user == 'nasabah'` ke [persenNasabah].
  Future<void> _fetchRewardOverview() async {
    if (_rewardInFlight) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId;

    // Dulu di sini cuma `return` kosong. Akibatnya _rewardLoading tidak pernah
    // turun: spinner berputar selamanya, dan karena _rewardFetched juga tetap
    // false, build() menjadwalkan fetch baru tiap frame -- yang langsung
    // return lagi. Nasabah terjebak tanpa pesan apa pun dan tanpa jalan keluar.
    // Sekarang diperlakukan sebagai error biasa yang punya tombol coba lagi.
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
        // Dipisah lewat namaReward, bukan rewardId — pola yang sama dengan
        // NilaiRewardBank.isUang/isBarang, jadi tidak patah kalau id berubah.
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
        child: CircularProgressIndicator(color: Color(0xFF4EA771)),
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
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EA771),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                // Jangan reset _rewardFetched di sini: itu justru membuat
                // build() menjadwalkan fetch kedua di frame berikutnya.
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
              const Text(
                'Program Bagi Hasil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF013236),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih reward yang ingin kamu lihat riwayat bagi hasilnya.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: const Color(0xFF013236).withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Panel putih yang manjang sampai bawah layar
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
                  // reward == null berarti bank belum mengatur jenis itu —
                  // kartunya tetap tampil, tapi dalam keadaan terkunci.
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

// ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ Reward Card Widget ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚ÂÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬

enum _RewardType { uang, barang }

class _RewardCard extends StatelessWidget {
  /// Null = bank belum mengatur jenis insentif ini.
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


  /// Baris atas kolom kanan: jenis SALDO-nya.
  ///
  /// Backend mengirim satuan mentah ("Rp", "poin") yang bukan kalimat untuk
  /// dibaca nasabah. Kalau satuannya kosong atau tak dikenal -- misalnya bank
  /// belum mengatur jenis ini -- jatuh ke jenis kartunya sendiri.
  String get _labelSaldo {
    final s = (reward?.satuan ?? '').toLowerCase();
    if (s.contains('poin')) return 'Saldo Poin';
    if (s.contains('rp') || s.contains('rupiah')) return 'Saldo Rupiah';
    return type == _RewardType.barang ? 'Saldo Poin' : 'Saldo Rupiah';
  }

  /// Baris bawah kolom kanan: nama insentifnya ("Uang" / "Barang" dari
  /// backend). Kapitalisasinya diseragamkan supaya "UANG" tidak bocor apa
  /// adanya kalau backend berubah.
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
              // Satu blob halus di pojok kanan card
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
                    // Persentase (angka besar) di kiri, identitas reward di
                    // kanan. Dulu ketiganya bertumpuk ke bawah satu baris
                    // masing-masing, jadi angka bagi hasil -- yang paling
                    // dicari nasabah -- tampil sekecil label biasa.
                    Row(
                      children: [
                        // Kolom 1 -- persentase bagi hasil level 'nasabah'.
                        if (notAvailable)
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
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -1.5,
                                  color: _accent,
                                ),
                              ),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(width: 14),

                        // Kolom 2 -- jenis saldo sebagai judul, nama
                        // insentif sebagai keterangan di bawahnya.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Jenis saldo yang jadi judulnya -- itu yang
                              // dicari nasabah. Nama insentif di bawahnya
                              // cuma keterangan.
                              Text(
                                _labelSaldo,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  letterSpacing: -0.3,
                                  color: notAvailable
                                      ? const Color(0xFF9E9E9E)
                                      : const Color(0xFF013236),
                                ),
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
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                    color: Color(0xFF013236),
                                  ),
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
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: Color(0xFF888888),
                          height: 1.4,
                        ),
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
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Expanded, bukan Spacer: teksnya sekarang ikut
                          // menyebut jenis saldo, jadi bisa panjang dan harus
                          // boleh melipat daripada jebol lewat tepi kartu.
                          Expanded(
                            child: Text(
                              'Lihat riwayat bagi hasil '
                              '${_labelSaldo.toLowerCase()}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: _accent,
                              ),
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

  String _formatPersen(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
