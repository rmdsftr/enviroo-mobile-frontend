class ApiConfig {
  // static const String baseUrl = 'http://10.0.2.2:8080';
  static const String baseUrl = 'http://192.168.1.60:8080';

  // Auth Endpoints
  static const String authBase = '$baseUrl/auth';
  static const String cekUserMobileUrl = '$authBase/cek-user-mobile';
  static const String loginUrl = '$authBase/login';
  static const String logoutUrl = '$authBase/logout';
  static const String refreshUrl = '$authBase/refresh';
  static const String switchRoleUrl = '$authBase/switch-role';
  static const String aktivasiUrl = '$authBase/aktivasi-akun';
  static const String reactivateUrl = '$authBase/reactivate-akun';
  static const String changePasswordUrl = '$authBase/change-password';
  static const String forgetPasswordSendEmailUrl = '$authBase/forget-password/send-email';
  static const String forgetPasswordVerifikasiOtpUrl = '$authBase/forget-password/verifikasi-otp';
  static const String forgetPasswordResetPasswordUrl = '$authBase/forget-password/reset-password';

  // Profil Endpoints
  static const String profilBase = '$baseUrl/profil';
  static const String profilNasabahUrl = '$profilBase/nasabah'; // usage: $profilNasabahUrl/$nasabahId
  static const String getDetailNasabahUrl = '$profilBase/detail-nasabah'; // usage: $getDetailNasabahUrl/$nasabahId
  static const String getDetailBankUrl = '$profilBase/detail-bank'; // usage: $getDetailBankUrl/$bankId
  static const String getDetailPetugasUrl = '$profilBase/detail-petugas'; // usage: $getDetailPetugasUrl/$petugasId
  static const String changePhotoProfileUrl = '$profilBase/change-photo-profile';
  static const String updateProfilUrl = '$baseUrl/users/update-profil'; // usage: $updateProfilUrl/$userId
  static const String logAkunUrl = '$baseUrl/users/log'; // usage: $logAkunUrl/$userId
  static const String activePetugasUrl = '$baseUrl/users/active-petugas'; // usage: $activePetugasUrl/$adminId
  static const String activeUserUrl = '$baseUrl/users/active-user'; // usage: $activeUserUrl/$userId
  static const String updateFcmTokenUrl = '$baseUrl/users/update-fcm-token'; // PATCH body: {fcm_token}

  // Katalog Endpoints
  static const String katalogBase = '$baseUrl/katalog';
  static const String getKatalogSampahUrl = '$katalogBase/get-sampah'; // usage: $getKatalogSampahUrl/$bankId
  static const String getDetailSampahUrl = '$katalogBase/get-detail'; // usage: $getDetailSampahUrl/$sampahId
  static const String getKategoriUrl = '$katalogBase/get-kategori';
  static const String getKatalogHistoryUrl = '$katalogBase/get-history'; // usage: $getKatalogHistoryUrl/$sampahId

  // Sembako Endpoints
  static const String sembakoBase = '$baseUrl/sembako';
  static const String getKatalogSembakoUrl = '$sembakoBase/get-sembako'; // usage: $getKatalogSembakoUrl/$bankId
  static const String detailSembakoBsuUrl = '$sembakoBase/detail-sembako-bsu'; // usage: $detailSembakoBsuUrl/$sembakoId
  static const String previewDistribusiBsuUrl = '$sembakoBase/preview-distribusi-bsu'; // usage: POST $previewDistribusiBsuUrl/$bsiId/$bsuId
  static const String addDistribusiBsuUrl = '$sembakoBase/add-distribusi-bsu'; // usage: POST $addDistribusiBsuUrl/$bsiId/$bsuId

  // Konten Endpoints
  static const String kontenBase = '$baseUrl/konten';
  static const String getKontenUrl = '$kontenBase/all-konten'; // usage: $getKontenUrl/$bankId
  static const String getKontenDetailUrl = '$kontenBase/get-konten'; // usage: $getKontenDetailUrl/$kontenId

  // Penimbangan Endpoints
  static const String penimbanganBase = '$baseUrl/penimbangan';
  static const String checkPenimbanganUrl = '$penimbanganBase/check'; // usage: $checkPenimbanganUrl/$bankId
  static const String checkActivePenimbanganUrl = '$penimbanganBase/check-active'; // usage: $checkActivePenimbanganUrl/$bankId
  static const String addPenimbanganUrl = '$penimbanganBase/add'; // usage: $addPenimbanganUrl/$bankId/$adminId
  static const String updatePenimbanganUrl = '$penimbanganBase/update'; // usage: $updatePenimbanganUrl/$penimbanganId/$adminId
  static const String getPenimbanganUrl = '$penimbanganBase/get'; // usage: $getPenimbanganUrl/$bankId
  static const String getSesiAktifUrl = '$penimbanganBase/get-sesi-aktif'; // usage: $getSesiAktifUrl/$penimbanganId

  // Admin Endpoints
  static const String adminBase = '$baseUrl/admin';
  static const String getAdminBankUrl = '$adminBase/get-admin'; // GET $getAdminBankUrl/:bank_id

  // Bank Endpoints
  static const String bankBase = '$baseUrl/bank';
  static const String getNasabahBankUrl = '$bankBase/get-nasabah'; // usage: $getNasabahBankUrl/$bankId
  static const String getAllBankUrl = '$bankBase/get-all'; // usage: $getAllBankUrl

  // Jadwal Endpoints
  static const String jadwalBase = '$baseUrl/jadwal';
  static const String getJadwalUrl = '$jadwalBase/get-jadwal'; // usage: $getJadwalUrl/$bankId

  // Dashboard Endpoints
  static const String dashboardBase = '$baseUrl/dashboard';
  static const String getDashboardPetugasUrl = '$dashboardBase/petugas'; // usage: $getDashboardPetugasUrl/$bankId
  static const String getSaldoBankUrl = '$dashboardBase/saldo-bank'; // usage: $getSaldoBankUrl/$bankId
  static const String getMutasiNasabahUrl = '$dashboardBase/mutasi-nasabah'; // GET $getMutasiNasabahUrl/:nasabah_id

  // Setoran Endpoints
  static const String setoranBase = '$baseUrl/setoran';
  static const String verifikasiSetoranUrl = '$setoranBase/verifikasi'; // usage: $verifikasiSetoranUrl/$penimbanganId/$nasabahId/$adminId
  static const String previewSetoranUrl = '$setoranBase/preview'; // POST $previewSetoranUrl/$penimbanganId/$nasabahId (form: items)
  static const String inputSetoranUrl = '$setoranBase/input'; // usage: $inputSetoranUrl/$penimbanganId/$nasabahId/$adminId
  static const String listSetoranPenimbanganUrl = '$penimbanganBase/list-setoran'; // usage: $listSetoranPenimbanganUrl/$penimbanganId
  static const String detailSetoranNasabahUrl = '$setoranBase/detail-setoran-nasabah'; // usage: $detailSetoranNasabahUrl/$setoranId
  static const String listSetoranNasabahUrl = '$setoranBase/list-setoran-nasabah'; // usage: $listSetoranNasabahUrl/$nasabahId

  // Pengangkutan Endpoints
  static const String pengangkutanBase = '$baseUrl/pengangkutan';
  static const String checkPengangkutanUrl = '$pengangkutanBase/check'; // usage: $checkPengangkutanUrl/$bsiId/$bsuId
  static const String startPengangkutanUrl = '$pengangkutanBase/start'; // POST body: {bsi_id, bsu_id, admin_bsi_id, status_dadakan}
  static const String getAllPengangkutanUrl = '$pengangkutanBase/get-all'; // usage: $getAllPengangkutanUrl/$bankId
  static const String getAllActivePengangkutanUrl = '$pengangkutanBase/get-all-active'; // GET $getAllActivePengangkutanUrl/$bsiId/$adminId
  static const String updatePengangkutanUrl = '$pengangkutanBase/update'; // usage: $updatePengangkutanUrl/$pengangkutanId/$adminBsiId
  static const String requestPengangkutanUrl = '$pengangkutanBase/request'; // POST $requestPengangkutanUrl/$bsuId/$adminBsuId
  static const String listSampahPengangkutanUrl = '$pengangkutanBase/list-sampah'; // GET $listSampahPengangkutanUrl/$bsiId
  static const String inputSampahPengangkutanUrl = '$pengangkutanBase/input'; // POST $inputSampahPengangkutanUrl/$pengangkutanId/$adminBsiId/$adminBsuId (multipart: items, bukti_foto?)
  static const String detailSampahPengangkutanUrl = '$pengangkutanBase/detail-sampah'; // GET $detailSampahPengangkutanUrl/$pengangkutanId
  static const String previewPengangkutanUrl = '$pengangkutanBase/preview'; // POST $previewPengangkutanUrl/$pengangkutanId (form: items)

  // BSI Endpoints
  static const String bsiBase = '$baseUrl/bsi';
  static const String getUnitBsiUrl = '$bsiBase/get-unit'; // usage: $getUnitBsiUrl/$bankId

  // Reward Endpoints
  static const String rewardBase = '$baseUrl/reward';
  static const String getAllRewardUrl = '$rewardBase/get-all';

  // Nilai Reward Endpoints
  static const String nilaiRewardBase = '$baseUrl/nilai-reward';
  static const String getNilaiRewardUrl = '$nilaiRewardBase/get'; // usage: $getNilaiRewardUrl/$bankId

  // Dashboard Nasabah Endpoints
  static const String getSaldoNasabahUrl = '$dashboardBase/saldo-nasabah'; // GET $getSaldoNasabahUrl/:nasabah_id

  // Penjualan Eksternal Endpoints
  static const String penjualanBase = '$baseUrl/penjualan';
  static const String previewPenjualanEksternalUrl = '$penjualanBase/preview'; // usage: $previewPenjualanEksternalUrl/$bankId
  static const String addPenjualanEksternalUrl = '$penjualanBase/add-eksternal'; // usage: $addPenjualanEksternalUrl/$bankId/$adminId
  static const String getRiwayatPenjualanEksternalUrl = '$penjualanBase/riwayat-eksternal'; // usage: $getRiwayatPenjualanEksternalUrl/$bankId
  static const String getDetailPenjualanEksternalUrl = '$penjualanBase/detail-eksternal'; // usage: $getDetailPenjualanEksternalUrl/$penjualanId
  static const String getListMitraEksternalUrl = '$penjualanBase/mitra'; // usage: $getListMitraEksternalUrl/$bankId
  
  // Bagi Hasil Endpoints
  static const String bagiHasilBase = '$baseUrl/bagi-hasil';
  static const String previewBagiHasilUrl = '$bagiHasilBase/preview'; // POST /$penjualanId/$bankId
  static const String submitBagiHasilUrl = '$bagiHasilBase/submit'; // POST /$penjualanId/$bankId
  static const String detailBagiHasilUrl = '$bagiHasilBase/detail'; // GET /$penjualanId
  static const String listBagiHasilNasabahUrl = '$bagiHasilBase/list-bh-nasabah'; // GET /$nasabahId
  static const String detailBagiHasilNasabahUrl = '$bagiHasilBase/detail-bh-nasabah'; // GET /$penerimaId
  static const String listBagiHasilBsuUrl = '$bagiHasilBase/list-bh-bsu'; // GET /$bsuId
  static const String detailBagiHasilBsuUrl = '$bagiHasilBase/detail-bh-bsu'; // GET /$penerimaId
  static const String listBagiHasilBankUrl = '$bagiHasilBase/list-bh-bank'; // GET /$bankId?start_date=&end_date=
  static const String detailBagiHasilBankUrl = '$bagiHasilBase/detail-bh-bank'; // GET /$bagiHasilId

  // Tabungan Sampah Endpoints
  static const String tabunganSampahBase = '$baseUrl/tabungan-sampah';
  static const String getBukuTabunganUrl = '$tabunganSampahBase/buku-tabungan'; // GET $getBukuTabunganUrl/:nasabah_id
  static const String getBukuTabunganBsuUrl = '$tabunganSampahBase/buku-tabungan-bsu'; // GET $getBukuTabunganBsuUrl/:bsu_id

  // Info Mobile Endpoints
  static const String infoMobileBase = '$baseUrl/info-mobile';
  static const String getJadwalNasabahUrl = '$infoMobileBase/jadwal-penimbangan'; // usage: $getJadwalNasabahUrl/:nasabah_id
  static const String getRewardOverviewNasabahUrl = '$infoMobileBase/reward-overview'; // usage: $getRewardOverviewNasabahUrl/:nasabah_id

  // Notifikasi Endpoints
  static const String notifikasiBase = '$baseUrl/notifikasi';
  static const String registerFcmTokenUrl = '$notifikasiBase/register-token'; // POST body: {user_id, fcm_token}
  static const String getNotifikasiUrl = '$notifikasiBase/list'; // GET /$userId
  static const String markReadUrl = '$notifikasiBase/read'; // PATCH /$notifId
  static const String markAllReadUrl = '$notifikasiBase/read-all'; // PATCH /$userId

  // Distribusi Sisa Bagi Hasil Endpoints
  static const String distribusiSisaBase = '$baseUrl/distribusi-sisa';
  static const String listBhBankBsuUrl    = '$distribusiSisaBase/list-bh-bank';   // usage: $listBhBankBsuUrl/$bsuId
  static const String detailBhBankBsuUrl  = '$distribusiSisaBase/detail-bh-bank'; // usage: $detailBhBankBsuUrl/$penerimaSisaId

  // Penarikan Nasabah (New Backend) Endpoints
  static const String penarikanBase = '$baseUrl/penarikan';
  static const String listPenarikanUrl = '$penarikanBase/list'; // GET $listPenarikanUrl/:nasabah_id ?reward_id=&start_date=&end_date=&page=&limit=
  static const String detailPenarikanUrl = '$penarikanBase/detail'; // GET $detailPenarikanUrl/:penarikan_id
  static const String previewPenarikanUrl = '$penarikanBase/preview'; // POST $previewPenarikanUrl/:nasabah_id
  static const String ajukanPenarikanUrl = '$penarikanBase/ajukan'; // POST $ajukanPenarikanUrl/:nasabah_id
  static const String batalPenarikanUrl = '$penarikanBase/batal'; // PATCH $batalPenarikanUrl/:penarikan_id
  static const String listPenarikanByBankUrl = '$penarikanBase/list-bank'; // GET $listPenarikanByBankUrl/:bank_id
  static const String konfirmasiPenarikanUrl = '$penarikanBase/konfirmasi'; // POST $konfirmasiPenarikanUrl/:penarikan_id
}
