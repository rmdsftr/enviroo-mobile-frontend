class ApiConfig {
  // static const String baseUrl = 'http://10.0.2.2:8080';
  static const String baseUrl = 'http://192.168.15.166:8080';

  // Auth Endpoints
  static const String authBase = '$baseUrl/auth';
  static const String cekUserMobileUrl = '$authBase/cek-user-mobile';
  static const String loginUrl = '$authBase/login';
  static const String logoutUrl = '$authBase/logout';
  static const String refreshUrl = '$authBase/refresh';
  static const String aktivasiUrl = '$authBase/aktivasi-akun';
  static const String reactivateUrl = '$authBase/reactivate-akun';
  static const String changePasswordUrl = '$authBase/change-password';

  // Profil Endpoints
  static const String profilBase = '$baseUrl/profil';
  static const String profilNasabahUrl = '$profilBase/nasabah'; // usage: $profilNasabahUrl/$nasabahId
  static const String getDetailNasabahUrl = '$profilBase/detail-nasabah'; // usage: $getDetailNasabahUrl/$nasabahId
  static const String changePhotoProfileUrl = '$profilBase/change-photo-profile';
  static const String activePetugasUrl = '$baseUrl/users/active-petugas'; // usage: $activePetugasUrl/$adminId
  static const String activeUserUrl = '$baseUrl/users/active-user'; // usage: $activeUserUrl/$userId

  //Nasabah endpoints
  static const String nasabahBase = '$baseUrl/nasabah';
  static const String getRiwayatTransaksiNasabahUrl = '$nasabahBase/riwayat-transaksi'; // usage: $getRiwayatTransaksiNasabahUrl/:nasabah_id
  // Katalog Endpoints
  static const String katalogBase = '$baseUrl/katalog';
  static const String getKatalogSampahUrl = '$katalogBase/get-sampah'; // usage: $getKatalogSampahUrl/$bankId
  static const String getKategoriUrl = '$katalogBase/get-kategori';
  static const String getKatalogHistoryUrl = '$katalogBase/get-history'; // usage: $getKatalogHistoryUrl/$sampahId

  // Sembako Endpoints
  static const String sembakoBase = '$baseUrl/sembako';
  static const String getKatalogSembakoUrl = '$sembakoBase/get-sembako'; // usage: $getKatalogSembakoUrl/$bankId

  // Konten Endpoints
  static const String kontenBase = '$baseUrl/konten';
  static const String getKontenUrl = '$kontenBase/all-konten'; // usage: $getKontenUrl/$bankId

  // Penimbangan Endpoints
  static const String penimbanganBase = '$baseUrl/penimbangan';
  static const String checkPenimbanganUrl = '$penimbanganBase/check'; // usage: $checkPenimbanganUrl/$bankId
  static const String addPenimbanganUrl = '$penimbanganBase/add'; // usage: $addPenimbanganUrl/$bankId/$adminId
  static const String updatePenimbanganUrl = '$penimbanganBase/update'; // usage: $updatePenimbanganUrl/$penimbanganId/$adminId
  static const String getPenimbanganUrl = '$penimbanganBase/get'; // usage: $getPenimbanganUrl/$bankId

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

  // Setoran Endpoints
  static const String setoranBase = '$baseUrl/setoran';
  static const String verifikasiSetoranUrl = '$setoranBase/verifikasi'; // usage: $verifikasiSetoranUrl/$penimbanganId/$nasabahId/$adminId
  static const String inputSetoranUrl = '$setoranBase/input'; // usage: $inputSetoranUrl/$penimbanganId/$nasabahId/$adminId
  static const String listSetoranPenimbanganUrl = '$penimbanganBase/list-setoran'; // usage: $listSetoranPenimbanganUrl/$penimbanganId
  static const String detailSetoranNasabahUrl = '$setoranBase/detail-setoran-nasabah'; // usage: $detailSetoranNasabahUrl/$setoranId
  static const String listSetoranNasabahUrl = '$setoranBase/list-setoran-nasabah'; // usage: $listSetoranNasabahUrl/$nasabahId

  // Pengangkutan Endpoints
  static const String pengangkutanBase = '$baseUrl/pengangkutan';
  static const String checkPengangkutanUrl = '$pengangkutanBase/check'; // usage: $checkPengangkutanUrl/$bsiId/$bsuId
  static const String startPengangkutanUrl = '$pengangkutanBase/start'; // POST body: {bsi_id, bsu_id, admin_bsi_id, status_dadakan}
  static const String getAllPengangkutanUrl = '$pengangkutanBase/get-all'; // usage: $getAllPengangkutanUrl/$bankId
  static const String updatePengangkutanUrl = '$pengangkutanBase/update'; // usage: $updatePengangkutanUrl/$pengangkutanId/$adminBsiId
  static const String requestPengangkutanUrl = '$pengangkutanBase/request'; // POST $requestPengangkutanUrl/$bsuId/$adminBsuId
  static const String listSampahPengangkutanUrl = '$pengangkutanBase/list-sampah'; // GET $listSampahPengangkutanUrl/$bsiId
  static const String inputSampahPengangkutanUrl = '$pengangkutanBase/input'; // POST $inputSampahPengangkutanUrl/$pengangkutanId/$adminBsiId/$adminBsuId (multipart: items, bukti_foto?)
  static const String detailSampahPengangkutanUrl = '$pengangkutanBase/detail-sampah'; // GET $detailSampahPengangkutanUrl/$pengangkutanId

  // BSI Endpoints
  static const String bsiBase = '$baseUrl/bsi';
  static const String getUnitBsiUrl = '$bsiBase/get-unit'; // usage: $getUnitBsiUrl/$bankId

  // Reward Endpoints
  static const String rewardBase = '$baseUrl/reward';
  static const String getAllRewardUrl = '$rewardBase/get-all';

  // Nilai Reward Endpoints
  static const String nilaiRewardBase = '$baseUrl/nilai-reward';
  static const String getNilaiRewardUrl = '$nilaiRewardBase/get'; // usage: $getNilaiRewardUrl/$bankId

  // Redeem BSU Endpoints
  static const String redeemBsuBase = '$baseUrl/redeem-bsu';
  static const String requestRedeemBsuUrl = '$redeemBsuBase/request'; // POST $requestRedeemBsuUrl/$bsuId/$adminBsuId
  static const String confirmRedeemBsuUrl = '$redeemBsuBase/confirm'; // POST $confirmRedeemBsuUrl/$transaksiId/$adminBsiId
  static const String cancelRedeemBsuUrl = '$redeemBsuBase/cancel'; // PATCH $cancelRedeemBsuUrl/$transaksiId/$adminBsuId
  static const String listRedeemBsuUrl = '$redeemBsuBase/list-redeem'; // GET $listRedeemBsuUrl/$bankId
  static const String detailRedeemBsuUrl = '$redeemBsuBase/detail'; // GET $detailRedeemBsuUrl/$redeemId
  static const String verifikasiManualRedeemUrl = '$redeemBsuBase/verifikasi-manual'; // GET $verifikasiManualRedeemUrl/$transaksiId/$adminBsiId

  // Dashboard Nasabah Endpoints
  static const String getSaldoNasabahUrl = '$dashboardBase/saldo-nasabah'; // GET $getSaldoNasabahUrl/:nasabah_id
  static const String getRedeemOverviewNasabahUrl = '$dashboardBase/redeem-overview'; // GET $getRedeemOverviewNasabahUrl/:nasabah_id

  // Redeem Nasabah (Penarikan) Endpoints
  static const String redeemNasabahBase = '$baseUrl/redeem-nasabah';
  static const String requestRedeemNasabahUrl = '$redeemNasabahBase/request'; // POST $requestRedeemNasabahUrl/:nasabah_id
  static const String cancelRedeemNasabahUrl = '$redeemNasabahBase/cancel'; // PATCH $cancelRedeemNasabahUrl/:transaksi_id/:nasabah_id
  static const String verifikasiPenarikanUrl = '$redeemNasabahBase/verifikasi'; // GET $verifikasiPenarikanUrl/:transaksi_id/:petugas_id
  static const String confirmRedeemNasabahUrl = '$redeemNasabahBase/confirm'; // POST $confirmRedeemNasabahUrl/:transaksi_id/:petugas_id
  static const String listRedeemNasabahByBankUrl = '$redeemNasabahBase/list-by-bank'; // GET $listRedeemNasabahByBankUrl/:bank_id
  static const String listRedeemNasabahByNasabahUrl = '$redeemNasabahBase/list-by-nasabah'; // GET $listRedeemNasabahByNasabahUrl/:nasabah_id
  static const String detailRedeemNasabahUrl = '$redeemNasabahBase/detail'; // GET $detailRedeemNasabahUrl/:redeem_id

  // Penjualan Eksternal Endpoints
  static const String penjualanBase = '$baseUrl/penjualan';
  static const String addPenjualanEksternalUrl = '$penjualanBase/add-eksternal'; // usage: $addPenjualanEksternalUrl/$bankId
  static const String getRiwayatPenjualanEksternalUrl = '$penjualanBase/riwayat-eksternal'; // usage: $getRiwayatPenjualanEksternalUrl/$bankId
  static const String getDetailPenjualanEksternalUrl = '$penjualanBase/detail-eksternal'; // usage: $getDetailPenjualanEksternalUrl/$penjualanId
  
  // Info Mobile Endpoints
  static const String infoMobileBase = '$baseUrl/info-mobile';
  static const String getJadwalNasabahUrl = '$infoMobileBase/jadwal-penimbangan'; // usage: $getJadwalNasabahUrl/:nasabah_id
  static const String getRewardOverviewNasabahUrl = '$infoMobileBase/reward-overview'; // usage: $getRewardOverviewNasabahUrl/:nasabah_id
}
