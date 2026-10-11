class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'ENVIROO_API_BASE_URL',
    defaultValue: 'http://172.20.10.3:8080',
  );

  static const String authBase = '$baseUrl/auth';
  static const String cekUserMobileUrl = '$authBase/cek-user-mobile';
  static const String loginUrl = '$authBase/login';
  static const String logoutUrl = '$authBase/logout';
  static const String refreshUrl = '$authBase/refresh';
  static const String switchRoleUrl = '$authBase/switch-role';
  static const String aktivasiUrl = '$authBase/aktivasi-akun';
  static const String changePasswordUrl = '$authBase/change-password';
  static const String forgetPasswordSendEmailUrl = '$authBase/forget-password/send-email';
  static const String forgetPasswordVerifikasiOtpUrl = '$authBase/forget-password/verifikasi-otp';
  static const String forgetPasswordResetPasswordUrl = '$authBase/forget-password/reset-password';

  static const String profilBase = '$baseUrl/profil';
  static const String profilNasabahUrl = '$profilBase/nasabah';
  static const String getDetailNasabahUrl = '$profilBase/detail-nasabah';
  static const String getDetailBankUrl = '$profilBase/detail-bank';
  static const String getDetailPetugasUrl = '$profilBase/detail-petugas';
  static const String updateProfilUrl = '$baseUrl/users/update-profil';
  static const String logAkunUrl = '$baseUrl/users/log';
  static const String activePetugasUrl = '$baseUrl/users/active-petugas';
  static const String activeUserUrl = '$baseUrl/users/active-user';
  static const String updateFcmTokenUrl = '$baseUrl/users/update-fcm-token';

  static const String katalogBase = '$baseUrl/katalog';
  static const String getKatalogSampahUrl = '$katalogBase/get-sampah';
  static const String getDetailSampahUrl = '$katalogBase/get-detail';
  static const String getKategoriUrl = '$katalogBase/get-kategori';

  static const String barangBase = '$baseUrl/barang';
  static const String getKatalogBarangUrl = '$barangBase/get';
  static const String detailBarangUrl = '$barangBase/detail-bsu';
  static const String previewDistribusiBsuUrl = '$barangBase/preview-distribusi-bsu';
  static const String addDistribusiBsuV2Url = '$barangBase/add-distribusi-bsu';
  static const String qrDistribusiUrl = '$barangBase/qr-distribusi';
  static const String listDistribusiBarangUrl = '$barangBase/list-distribusi';
  static const String detailDistribusiBarangUrl = '$barangBase/detail-distribusi';

  static const String kontenBase = '$baseUrl/konten';
  static const String getKontenUrl = '$kontenBase/all-konten';
  static const String getKontenDetailUrl = '$kontenBase/get-konten';

  static const String penimbanganBase = '$baseUrl/penimbangan';
  static const String checkPenimbanganUrl = '$penimbanganBase/check';
  static const String checkActivePenimbanganUrl = '$penimbanganBase/check-active';
  static const String updatePenimbanganUrl = '$penimbanganBase/update';
  static const String getPenimbanganUrl = '$penimbanganBase/get';
  static const String batalPenimbanganUrl = '$penimbanganBase/batal';
  static const String listSetoranPenimbanganUrl = '$penimbanganBase/list-setoran';

  static const String adminBase = '$baseUrl/admin';
  static const String getAdminBankUrl = '$adminBase/get-admin';

  static const String bankBase = '$baseUrl/bank';
  static const String getNasabahBankUrl = '$bankBase/get-nasabah';
  static const String getAllBankUrl = '$bankBase/get-all';

  static const String jadwalBase = '$baseUrl/jadwal';
  static const String getJadwalUrl = '$jadwalBase/get-jadwal';
  static const String getJadwalPenimbanganBsmUrl = '$jadwalBase/penimbangan';

  static const String dashboardBase = '$baseUrl/dashboard';
  static const String getDashboardPetugasUrl = '$dashboardBase/petugas';
  static const String getSaldoBankUrl = '$dashboardBase/saldo-bank';
  static const String getMutasiNasabahUrl = '$dashboardBase/mutasi-nasabah';

  static const String setoranBase = '$baseUrl/setoran';
  static const String verifikasiSetoranUrl = '$setoranBase/verifikasi';
  static const String previewSetoranUrl = '$setoranBase/preview';
  static const String inputSetoranUrl = '$setoranBase/input';
  static const String detailSetoranNasabahUrl = '$setoranBase/detail';
  static const String listSetoranNasabahUrl = '$setoranBase/riwayat';

  static const String pengangkutanBase = '$baseUrl/pengangkutan';
  static const String checkPengangkutanUrl = '$pengangkutanBase/check';
  static const String startPengangkutanUrl = '$pengangkutanBase/start';
  static const String getAllPengangkutanUrl = '$pengangkutanBase/get-all';
  static const String getAllActivePengangkutanUrl = '$pengangkutanBase/get-all-active';
  static const String updatePengangkutanUrl = '$pengangkutanBase/update';
  static const String requestPengangkutanUrl = '$pengangkutanBase/request';
  static const String listSampahPengangkutanUrl = '$pengangkutanBase/list-sampah';
  static const String inputSampahPengangkutanUrl = '$pengangkutanBase/input';
  static const String detailSampahPengangkutanUrl = '$pengangkutanBase/detail-sampah';
  static const String previewPengangkutanUrl = '$pengangkutanBase/preview';

  static const String bsiBase = '$baseUrl/bsi';
  static const String getUnitBsiUrl = '$bsiBase/get-unit';

  static const String rewardBase = '$baseUrl/reward';
  static const String getAllRewardUrl = '$rewardBase/get-all';

  static const String nilaiRewardBase = '$baseUrl/nilai-reward';
  static const String getNilaiRewardUrl = '$nilaiRewardBase/get';

  static const String getSaldoNasabahUrl = '$dashboardBase/saldo-nasabah';

  static const String penjualanBase = '$baseUrl/penjualan';
  static const String previewPenjualanEksternalUrl = '$penjualanBase/preview';
  static const String addPenjualanEksternalUrl = '$penjualanBase/add-eksternal';
  static const String getRiwayatPenjualanEksternalUrl = '$penjualanBase/riwayat-eksternal';
  static const String getDetailPenjualanEksternalUrl = '$penjualanBase/detail-eksternal';
  static const String getListMitraEksternalUrl = '$penjualanBase/mitra';
  
  static const String bagiHasilBase = '$baseUrl/bagi-hasil';
  static const String previewBagiHasilUrl = '$bagiHasilBase/preview';
  static const String submitBagiHasilUrl = '$bagiHasilBase/submit';
  static const String detailBagiHasilUrl = '$bagiHasilBase/detail';
  static const String listBagiHasilNasabahUrl = '$bagiHasilBase/list-bh-nasabah';
  static const String detailBagiHasilNasabahUrl = '$bagiHasilBase/detail-bh-nasabah';
  static const String listBagiHasilBankUrl = '$bagiHasilBase/list-bh-bank';
  static const String detailBagiHasilBankUrl = '$bagiHasilBase/detail-bh-bank';

  static const String tabunganSampahBase = '$baseUrl/tabungan-sampah';
  static const String getBukuTabunganUrl = '$tabunganSampahBase/buku-tabungan';
  static const String getBukuTabunganBsuUrl = '$tabunganSampahBase/buku-tabungan-bsu';


  static const String notifikasiBase = '$baseUrl/notifikasi';
  static const String getNotifikasiUrl = '$notifikasiBase/list';
  static const String markReadUrl = '$notifikasiBase/read';
  static const String markAllReadUrl = '$notifikasiBase/read-all';
  static const String unreadCountUrl = '$notifikasiBase/unread-count';

  static const String distribusiSisaBase = '$baseUrl/distribusi-sisa';
  static const String listBhBankBsuUrl    = '$distribusiSisaBase/list-bh-bank';
  static const String detailBhBankBsuUrl  = '$distribusiSisaBase/detail-bh-bank';

  static const String penarikanBase = '$baseUrl/penarikan';
  static const String listPenarikanUrl = '$penarikanBase/list';
  static const String detailPenarikanUrl = '$penarikanBase/detail';
  static const String previewPenarikanUrl = '$penarikanBase/preview';
  static const String ajukanPenarikanUrl = '$penarikanBase/ajukan';
  static const String batalPenarikanUrl = '$penarikanBase/batal';
  static const String listPenarikanByBankUrl = '$penarikanBase/list-bank';
  static const String konfirmasiPenarikanUrl = '$penarikanBase/konfirmasi';
  static const String selesaiPenarikanUrl = '$penarikanBase/selesai';
}
