import 'package:enviroo/models/detail_bank_model.dart';
import 'package:enviroo/screens/nasabah/chat_info_bank_sampah_screen.dart';
import 'package:enviroo/services/profil_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifikasi_provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class JadwalSetoranSection extends StatefulWidget {
  const JadwalSetoranSection({super.key});

  @override
  State<JadwalSetoranSection> createState() => JadwalSetoranSectionState();
}

class JadwalSetoranSectionState extends State<JadwalSetoranSection> {
  DetailBankModel? _bank;
  bool _isLoading = true;
  String? _error;

  late final AppLifecycleListener _lifecycleListener;


  @override
  void initState() {
    super.initState();
    _fetchBankDetail();
    _lifecycleListener = AppLifecycleListener(onResume: _fetchBankDetail);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> refresh() => _fetchBankDetail();

  Future<void> _fetchBankDetail() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bankId = auth.bankId;

    if (bankId == null || bankId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = "Sesi tidak valid.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bank = await ProfilService.getDetailBank(bankId);
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27),
            child: Text(
              "Info Bank Sampah",
              style: AppText.w600(15, AppColors.dark),
            ),
          ),

          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.red),
                  ),
                ),
              ),
            )
          else if (_bank != null)
            _buildBankCard(_bank!),
        ],
      ),
    );
  }

  Widget _buildBankCard(DetailBankModel bank) {
    final lokasi = [
      bank.alamat,
      bank.kelurahan,
      bank.kecamatan,
      bank.kabupatenKota,
      bank.provinsi,
    ].where((s) => s.isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.12),
                  ),
                  child: ClipOval(
                    child: bank.photoUrl.isNotEmpty
                        ? Image.network(
                            bank.photoUrl,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatar(),
                          )
                        : _defaultAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.namaBank,
                        style: AppText.w700(13, AppColors.dark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bank.bankId,
                        style: AppText.r(10, AppColors.dark.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<NotifikasiProvider>(
                  builder: (context, notifProvider, _) {
                    final unread = notifProvider.notifikasi
                        .where((n) => n.isChatInfoBank && !n.isRead)
                        .length;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatInfoBankSampahScreen(
                            bankId: bank.bankId,
                            namaBank: bank.namaBank,
                            photoUrl: bank.photoUrl,
                          ),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.dark,
                            ),
                            child: const Icon(
                              Icons.chat_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neon,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 18),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: AppText.p(9, weight: FontWeight.w700, color: AppColors.dark, height: 1.2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            if (bank.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bank.deskripsi,
                style: AppText.p(11.5, color: AppColors.dark.withValues(alpha: 0.65), height: 1.5),
              ),
            ],

            if (bank.deskripsi.isNotEmpty && lokasi.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dark.withValues(alpha: 0.08),
              ),
            ],

            if (lokasi.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.green.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lokasi,
                      style: AppText.p(11, color: AppColors.green.withValues(alpha: 0.75), height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Icon(Icons.account_balance_rounded, color: AppColors.green, size: 22);
  }
}
