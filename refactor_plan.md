# Refactor `lib/core/` — Ronde Fungsional

Dokumen kerja. Centang tiap step setelah gate verifikasinya lolos.

**Target struktur:**

```
lib/core/
  config/     ← api_config.dart          (dari lib/config/)
  network/    ← api_client.dart           (dari lib/services/)
                http_overrides.dart       (dari main.dart)
  messaging/  ← fcm_messaging.dart          (BARU — ekstrak dari main.dart)
                notif_payload.dart        (BARU)
  theme/      ← app_theme.dart            (pindah ThemeData dari main.dart)
```

**Hasil yang diharapkan:** FCM keluar dari bootstrap, duplikat blok login/role_options hilang, 3 postur TLS nyatu jadi 1, `main.dart` **~230 → ~115 baris**.

---

## ⛔ Di luar skop ronde ini

Semua refactor **tampilan** — plan-nya dibikin terpisah:

- design token / `app_colors.dart`
- `app_text_styles.dart`
- migrasi `lib/widgets/` (24 file) & `lib/layouts/` (14 file) — 247 color literal, 42 hex unik
- `fontFamily` di `ThemeData`
- fix weight font `pubspec.yaml` (3 font kedaftar tanpa `weight:` → 431 pakai w600 & 210 w700 di-faux-bold)
- migrasi `withOpacity` → `withValues` (368 sisa)
- `ColorScheme.secondary` = `#94DF0C` padahal praktiknya `#4EA771` (307 vs 79 penggunaan)

Satu-satunya sentuhan ke `core/theme/` di ronde ini cuma **Step 7** — mindahin `ThemeData` yang udah ada, byte-identical.

> **Konsekuensi penting: seluruh ronde ini NOL perubahan visual.** Nggak ada satu pun step yang boleh ngubah pixel. Itu yang bikin verifikasi gampang — jawaban benar buat "keliatan bener nggak?" selalu "identik kayak sebelumnya".

---

## Kenapa ini dikerjain

| Masalah | Detail |
|---|---|
| FCM numpuk di bootstrap | `_EnvirooAppState` megang 4 listener FCM + retry token + deep-link routing + lifecycle observer, padahal tugasnya cuma nyusun `MultiProvider` + `MaterialApp` |
| Blok FCM di-copy verbatim | `login_screen.dart:157-179` == `role_options_screen.dart:119-140`, cuma beda tag debugPrint |
| Subscription nggak pernah di-cancel | `dispose()` cuma remove observer. Di hot restart listener numpuk → satu push jadi N kali fetch |
| `api_client.dart` salah tempat | Infra HTTP lintas-fitur nyempil di `lib/services/` bareng 22 REST wrapper per-fitur |
| **BUG — TLS allowlist ke-overwrite** | `api_client.dart:14-16` set `badCertificateCallback => true` → nge-overwrite allowlist sempit `MyHttpOverrides` (`main.dart:29-37`). **Sertifikat invalid dari host mana pun diterima.** Ke-mask sekarang karena `baseUrl` masih `http://`, aktif begitu prod `https://` dipakai |
| **BUG — baseUrl hardcoded** | IP LAN + 3 alternatif di-comment → ganti environment = manual comment-swap. Risiko build release kelupaan ganti |
| **BUG — dead file** | `lib/services/tabunga_sampah_service.dart` 0 byte (typo dari `tabungan_sampah_service.dart`), nol referensi |

---

## Step 0 — Baseline

- [ ] **`git status` bersih.** Sekarang ada puluhan file uncommitted di branch `bersih-bersih` (termasuk `main.dart`, `api_config.dart`, `api_client.dart` — ketiganya file yang mau disentuh). **Commit atau stash dulu** — kalau nggak, `git revert` per-step nggak bisa dipakai.
- [ ] Catat titik rollback: `git rev-parse HEAD`
- [ ] Simpan baseline analyzer:

```powershell
flutter analyze > baseline_analyze.txt
```

Angka baseline yang harus dijaga:

```
Flutter 3.41.1 / Dart 3.11.0
489 issues: 0 errors, 60 warnings, 429 infos
```

> ⚠️ **`flutter test` udah gagal sekarang** — `test/widget_test.dart` mompa `EnvirooApp` tanpa `Firebase.initializeApp`, jadi `FirebaseMessaging.instance` di `initState` throw. **Bukan gate yang bisa dipakai.** Gate-nya `flutter analyze` (0 errors) + smoke test manual.

---

## Aturan commit

**Satu commit per step.** Jangan pernah gabungin `git mv` dengan rewrite konten di commit yang sama — itu yang bikin `git revert` viable dan `git log -p --follow` kebaca lintas pemindahan.

---

## Step 1 — Hapus dead file · risiko: nol

- [ ] `git rm lib/services/tabunga_sampah_service.dart`
- [ ] `flutter analyze` → 0 errors

0 byte, `grep -rn "tabunga_sampah" lib/` nol hit. ⚠️ Perhatikan typo-nya — `tabungan_sampah_service.dart` yang bener **jangan** disentuh.

---

## Step 2 — `api_config.dart` → `core/config/` · risiko: rendah

- [ ] Pindahkan:

```powershell
New-Item -ItemType Directory -Force lib/core/config
git mv lib/config/api_config.dart lib/core/config/api_config.dart
Remove-Item lib/config
```

- [ ] Replace di **22 file** `lib/services/` — semuanya string identik (100%):

```
FIND:    import '../config/api_config.dart';
REPLACE: import 'package:enviroo/core/config/api_config.dart';
```

- [ ] `flutter analyze` → 0 errors
- [ ] `Select-String -Path lib\**\*.dart -Pattern "config/api_config"` → 0 hit

**Kenapa config sebelum client:** ini kasus yang jelas lebih gampang — satu bentuk import, nol konsumer di luar `lib/services/`, dan `api_config.dart` nggak ngimport apa-apa sendiri. Buat mbuktiin mekanisme + konvensi `package:` sebelum nyentuh file yang ada hazard-nya. Dua file ini independen (`api_client.dart` **nggak** ngimport `ApiConfig`), jadi urutannya soal risiko, bukan kebenaran.

**Kenapa `package:` bukan relative:** sesuai preferensi codebase sendiri (504 `package:` vs 257 relative) **dan tahan-pindah** — kalau nanti file-nya digeser lagi, import-nya nggak ikut rusak.

---

## Step 3 — `baseUrl` → `--dart-define` · risiko: rendah

- [ ] Ganti `api_config.dart` baris 2-5:

```dart
class ApiConfig {
  /// Override saat build:
  ///   flutter run --dart-define=ENVIROO_API_BASE_URL=https://api.enviroo.tech
  ///   flutter run --dart-define=ENVIROO_API_BASE_URL=http://10.0.2.2:8080     # emulator
  ///   flutter run --dart-define=ENVIROO_API_BASE_URL=http://192.168.1.57:8080
  static const String baseUrl = String.fromEnvironment(
    'ENVIROO_API_BASE_URL',
    defaultValue: 'http://192.168.1.8:8080',
  );
  // …123 const turunan nggak berubah
}
```

- [ ] Benerin typo komentar baris 7: `// Auth Endpointstter` → `// Auth Endpoints`
- [ ] `flutter analyze` → 0 errors
- [ ] Round trip: tanpa define → traffic ke `192.168.1.8:8080`; dengan `--dart-define=ENVIROO_API_BASE_URL=https://api.enviroo.tech` → traffic ke host baru

`String.fromEnvironment` itu **const constructor**, jadi 123 `static const String xUrl = '$baseUrl/…'` di bawahnya tetep constant expression — nggak ada yang lain berubah di file ini. 3 baris alternatif yang di-comment jadi doc comment, bukan dead code.

---

## Step 4 — `api_client.dart` → `core/network/` · risiko: rendah

- [ ] Pindahkan:

```powershell
New-Item -ItemType Directory -Force lib/core/network
git mv lib/services/api_client.dart lib/core/network/api_client.dart
```

- [ ] Dua replacement:

```
FIND:    import 'api_client.dart';                            → 22 file (semua di lib/services/)
REPLACE: import 'package:enviroo/core/network/api_client.dart';

FIND:    import 'package:enviroo/services/api_client.dart';    → 1 file (auth_provider.dart:4)
REPLACE: import 'package:enviroo/core/network/api_client.dart';
```

- [ ] `flutter analyze` → **0 errors** (ini gate utamanya)
- [ ] `Select-String -Path lib\**\*.dart -Pattern "import 'api_client.dart'"` → 0 hit
- [ ] `Test-Path lib\services\api_client.dart` → False

**Soal hazard bare-import:** bentuk bare-nya adalah **baris penuh yang byte-identical** di 22 file, dan nggak ada file lain bernama `api_c*.dart` di repo — jadi string-nya nggak bisa nabrak. Full-line replace itu eksak dan total.

**Tanpa re-export shim**, karena:

1. 23 importer, dua bentuk, provably complete.
2. Kalau kelewat, itu **hard analyzer error** (`uri_does_not_exist` + `undefined_identifier: ApiClient` di tiap call site) — baseline "0 errors" nangkep 100% dalam 2 menit.
3. Shim ninggalin file yang harus dihapus di follow-up yang nggak akan dikerjain, dan lebih buruk: dia bikin bentuk bare-import **tetep legal**, jadi file service baru bakal nulis `import 'api_client.dart';` lagi dan hazard-nya regenerasi.

---

## Step 5 — Fix TLS + pindah `MyHttpOverrides` · risiko: **butuh negative test**

`HttpClient()` di `api_client.dart:14` **udah** lewat `MyHttpOverrides.createHttpClient` — diverifikasi di source dart-sdk (`_http/http.dart:1344-1350`, `factory HttpClient()` routing ke `HttpOverrides.current`), dan `HttpOverrides.global` dipasang di `main()` baris 42 **sebelum** `runApp`. Jadi client-nya udah nerima allowlist, terus baris 15–16 **nge-overwrite** jadi accept-all.

- [ ] Hapus override-nya:

```dart
static http.Client get _httpClient {
  if (_client != null) return _client!;
  // HttpOverrides.global (EnvirooHttpOverrides) yang nyediain allowlist bad-cert.
  // JANGAN set badCertificateCallback di sini — bakal ngeganti allowlist itu.
  _client = IOClient(HttpClient());
  return _client!;
}
```

- [ ] Pindahkan `MyHttpOverrides` → `lib/core/network/http_overrides.dart` sebagai `EnvirooHttpOverrides`
- [ ] `main.dart` tetep manggil `HttpOverrides.global = EnvirooHttpOverrides();` **sebagai baris pertama setelah `ensureInitialized()`** — harus dipasang sebelum ada request keluar
- [ ] `flutter analyze` → 0 errors

Ini nyatuin **3 postur TLS** yang sekarang beda-beda ke satu allowlist:

| Jalur | Sebelum | Sesudah |
|---|---|---|
| Verb `ApiClient` (get/post/patch/delete) | accept-all, host mana pun | host allowlist |
| `ApiClient.sendMultipart` | host allowlist (pakai client default `http`) | host allowlist |
| 11 raw call `auth_service.dart` | host allowlist | host allowlist |

Nol kode baru, murni perbaikan keamanan.

> ⚠️ **Jangan** paksa bypass `auth_service` lewat `ApiClient`: `refreshToken`/`logout` butuh header manual `Cookie: refresh_token=…` yang nggak bisa diekspresikan `ApiClient`, dan `refreshToken` **itu sendiri** callback `onUnauthorized` — ngeroutingnya lewat `ApiClient` bikin rekursi. Habis step ini mereka udah share postur TLS yang sama.

### Gate Step 5 — wajib, ini satu-satunya cara mbuktiin fix-nya

Bug-nya ke-mask sekarang karena `baseUrl` plain `http://`, jadi harus dites eksplisit:

- [ ] **Positif:** arahin ke `https://api.enviroo.tech` → login + upload foto harus tetep **SUKSES** (allowlist jalan)
- [ ] **Negatif:** arahin ke host https **lain** dengan sertifikat invalid → request harus **GAGAL**. Sebelum Step 5 dia sukses. **Tanpa test ini, Step 5 nggak terverifikasi.**

### Smoke API (Step 2–5)

`ApiClient` itu all-static dan dipakai 22 service — satu jalur rusak = semuanya rusak.

- [ ] satu GET list
- [ ] satu POST create
- [ ] satu PATCH
- [ ] satu DELETE
- [ ] satu `sendMultipart` (upload foto: setoran / penimbangan / avatar profil) — ⚠️ **jalur TLS-nya beda** dari verb biasa, wajib dites terpisah
- [ ] **401 → refresh → retry**: background lewatin masa expired access token, resume. Nggak boleh ada 401 nyampe user
- [ ] **403 `ACCOUNT_INACTIVE` → force logout ke SplashScreen** (`auth_provider._initApiClient` → `onDeactivated`)

---

## Step 6 — Ekstrak FCM → `core/messaging/` · risiko: **sedang (inti ronde ini)**

### 6a. `core/messaging/notif_payload.dart` — batas bertipe

```dart
class NotifPayload {
  final String refType;
  final String refId;
  final Map<String, dynamic> data;

  /// null kalau message nggak bawa ref_type/ref_id yang kepake.
  static NotifPayload? from(RemoteMessage m) { … }
}
```

Ini yang nyelesaiin `dynamic` di `_handleNotifDeepLink(dynamic msg, …)` — dia `dynamic` cuma karena ngelayanin `onMessageOpenedApp` **dan** `getInitialMessage`, padahal **dua-duanya `RemoteMessage`**. Ngasih tipe itu gratis.

Lebih bagus lagi: `FcmMessaging` jadi **satu-satunya** yang nyentuh `RemoteMessage`, dunia luar dikasih `NotifPayload`. Hasilnya **`main.dart` berhenti ngimport `firebase_messaging` sama sekali.**

### 6b. `core/messaging/fcm_messaging.dart` — instance class biasa

Bukan static, bukan singleton:

```dart
typedef NotifDeepLink = void Function(NotifPayload payload, {required bool navigate});

class FcmMessaging {
  FcmMessaging({
    required AuthProvider auth,
    required NotifikasiProvider notif,
    required NotifDeepLink onDeepLink,
    FirebaseMessaging? messaging,        // injectable → testable
  });

  void start();                          // attach 4 listener; idempotent
  Future<void> dispose();                // cancel subscription
  Future<void> onAppResumed();           // body lifecycle
  void onLogin({String tag = 'Auth'});   // blok login/role_options yang di-dedupe
  Future<void> sendToken({String? explicitToken});
  void refreshNotifikasi({int retryCount = 0});
}
```

### 6c. Dependency: `_auth`/`_notif` di-inject, `_navigatorKey`/`_pengangkutan` **TIDAK**

Alasan provider-provider itu jadi State field (`main.dart:63-65`) adalah supaya bisa dijangkau callback FCM tanpa `BuildContext` — ada komentar eksplisit di kodenya. **Constructor injection mempertahankan constraint itu persis**, sambil bikin dependency-nya eksplisit dan class-nya testable:

```dart
_fcm = FcmMessaging(auth: _auth, notif: _notif, onDeepLink: _routeDeepLink)..start();
```

`ChangeNotifierProvider.value` di baris 187/188/202 **nggak disentuh**.

**`_navigatorKey` dan `_pengangkutan` sengaja NGGAK di-inject** — ini keputusan struktural paling penting di ekstraksi ini. `FcmMessaging` cuma ngeluarin `NotifPayload` yang udah di-decode; `main.dart` yang mutusin mau **ngapain**:

```dart
void _routeDeepLink(NotifPayload p, {required bool navigate}) {
  if (p.refType != 'pengajuan_pengangkutan') return;
  _pengangkutan.setHighlight(p.refId);
  if (!navigate) return;
  _navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (_) => const PengangkutanBsiScreen(initialTab: 1, initialFilter: 'requested'),
  ));
}
```

Kalau `FcmMessaging` yang megang navigator key, dia harus ngimport `PengangkutanBsiScreen` — itu **nggak** benerin layer violation, cuma **mindahin ke dalam `core/`**, yang malah lebih buruk. Misahin *decode* (di `core/`) dari *act* (di `main.dart`) bikin **`core/` nggak pernah ngimport `screens/`**.

### 6d. Lifecycle observer: `main.dart` yang megang, body-nya didelegasi

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) _fcm.onAppResumed();
}
```

`WidgetsBindingObserver` itu urusan widget tree dan `_EnvirooAppState` udah implement. Kalau `FcmMessaging` jadi observer-nya, dia harus manggil `WidgetsBinding.instance.addObserver(this)` dari dalam `core/` — side effect global tersembunyi di constructor service, plus cara kedua bikin `start()` jadi non-idempotent.

Dua detail yang harus dipertahankan **persis**:

> ⚠️ `onAppResumed()` wajib tetep `await _auth.refreshToken();` **sebelum** `sendToken()` dan `refreshNotifikasi()`, beserta komentar yang jelasin kenapa (`main.dart:121-122`). **Ini baris load-bearing di seluruh file** — tanpa `await`-nya, request notifikasi keluar dengan token expired → 401.

- Guard `_auth.isLoggedIn` dipindah dari observer ke dalam `onAppResumed()` — perilaku sama, observer tetep one-liner.
- Signature `void … async` yang sekarang (async void) jadi `void` biasa yang ngedelegasi ke method async.

### 6e. Dedupe blok login / role_options

Dua blok itu duplikat verbatim dari **tiga** hal — `fetchNotifikasi` juga bagian duplikatnya, bukan cuma separuh FCM-nya:

```dart
void onLogin({String tag = 'Auth'}) {
  _notif.fetchNotifikasi(role: _auth.role);
  _messaging.requestPermission();   // sengaja TIDAK di-await — parity ronde ini
  sendToken(tag: tag);
}
```

Cuma butuh `_auth` (buat `role`) dan `_notif` — dua-duanya udah di-inject, nggak ada dependency baru.

Handle-nya diekspos lewat `MultiProvider` yang udah ada sebagai `Provider<FcmMessaging>.value(value: _fcm)` — **bukan** `ChangeNotifierProvider`, karena `FcmMessaging` nggak nyimpen state observable. Dua screen itu udah pakai idiom `Provider.of<NotifikasiProvider>(context, listen: false)`, jadi ini nyocok dan ngeganti ~14 baris jadi satu:

```dart
Provider.of<FcmMessaging>(context, listen: false).onLogin(tag: 'Login');
```

Param `tag` dipertahankan — itu **satu-satunya** beda antara dua blok (`[Login]` vs `[RoleOptions]`) dan satu-satunya cara ngebedain dua jalur login di log.

> ⚠️ **`requestPermission()` tetep nggak di-await.** Kalau di-await, navigasi ketunda sampai dialog permission Android 13+ kelar — user bakal liat dialog **sebelum** home screen, bukan di atasnya. Itu bisa diperdebatkan lebih bagus, tapi itu **perubahan perilaku** → follow-up.

### 6f. Simpan & cancel subscription

- [ ] `final List<StreamSubscription> _subs = []`, cancel di `dispose()`
- [ ] Guard `start()` dengan `_started` biar double-call nggak double-subscribe
- [ ] Guard callback `getInitialMessage()` dengan `if (!_started) return;` — dia `Future` bukan stream, nggak ada yang di-cancel, tapi resolusi telat setelah `dispose()` jangan nyentuh provider yang udah dibuang

Alasan, urut bobot:

1. **Hot restart** (dan test apa pun nanti) bikin & buang tree berulang. Listener `onMessage` yang nggak di-cancel numpuk → satu push ngetrigger N kali `refreshNotifikasi()`. Ini penyebab plausibel keanehan duplicate-fetch saat development, dan nggak keliatan di produksi cuma karena `_EnvirooAppState` itu root State yang nggak pernah dispose.
2. Simetri `start()`/`dispose()` + guard idempotence itu yang bikin **mungkin** benerin `test/widget_test.dart` nanti — satu-satunya test app ini, yang sekarang gagal.
3. `dispose()` sekarang cuma remove observer; ninggalin 3 stream nggantung sambil hati-hati ngeremove satu observer itu inkonsisten dan nyesatin pembaca.

> ⚠️ **Retry 3 × 500ms di `refreshNotifikasi` (`main.dart:129-151`) dipertahankan byte-identical**, termasuk debugPrint-nya. Itu ada buat race restore token dari secure storage yang nyata, dan gampang banget "dirapihin" jadi bug.

### 6g. `main.dart` setelah step ini

**Hilang:** import `firebase_messaging`, import `dart:io`, `MyHttpOverrides` (→ Step 5), 4 blok listener, `_refreshNotifikasi`, `_sendFcmToken`, mayoritas `_handleNotifDeepLink`.

**Tetap:** `main()`, `_navigatorKey`, 3 provider field, `setForceLogoutCallback`, `_fcm` create/start/dispose, observer one-liner, `_routeDeepLink` (~10 baris), `MultiProvider`, `MaterialApp`.

**~230 baris → ~115.**

### Gate Step 6 — keempat entry point, tanpa potong kompas

- [ ] **`onMessage`** — app kebuka, kirim push → list notif refresh
- [ ] **`onMessageOpenedApp`** — background, tap notif tray `ref_type=pengajuan_pengangkutan` → mendarat di `PengangkutanBsiScreen(initialTab: 1, initialFilter: 'requested')`, row ke-highlight
- [ ] **`getInitialMessage`** — **force-stop**, tap notif → cold start, **nggak** navigasi; terus buka `PengangkutanBsiScreen` manual → highlight masih dikonsumsi di `pengangkutan_bsi_screen.dart:156-166`
- [ ] **`onTokenRefresh`** — clear app data / reinstall → backend nerima token baru
- [ ] **lifecycle resume** — background **lebih lama dari TTL access token**, resume → **nggak ada 401 di log**, notif refresh. Ini yang mbuktiin urutan `await refreshToken()` selamat
- [ ] **dedupe login** — login akun **single-role** (jalur login_screen) **dan** **multi-role** (jalur role_options) → `PATCH /users/update-fcm-token` nembak **tepat sekali** per login di dua-duanya; tag `[Login]`/`[RoleOptions]` masih ngebedain di log
- [ ] **race token** — fresh install → login → force-stop → buka lagi (restore session dari secure storage) → jalur `token kosong, retry ke-N` masih nge-log dan akhirnya **sukses**, bukan abort setelah 3×

> Baris terakhir itu yang paling gampang rusak tanpa kelihatan — retry-nya cuma kepanggil di kondisi race yang spesifik.

---

## Step 7 — `ThemeData` → `core/theme/app_theme.dart` · risiko: nol

- [ ] Bikin `lib/core/theme/app_theme.dart` dengan `static ThemeData get light` yang isinya **persis** `main.dart:213-224` sekarang — hex sama, `useMaterial3: false` sama, **tanpa nambah `fontFamily`, tanpa nambah `textTheme`**
- [ ] `main.dart` jadi `theme: AppTheme.light`
- [ ] `flutter analyze` → 0 errors

Nol perubahan visual, bisa diverifikasi cukup dengan baca diff.

Step ini sengaja ditaruh terakhir dan berdiri sendiri, jadi gampang di-skip kalau mau ngurus `core/theme/` dari nol di plan tampilan.

---

## Gate global — jalanin setelah **setiap** step

```powershell
flutter analyze | Select-String -Pattern 'error - '   # HARUS KOSONG
flutter analyze | Select-Object -Last 1               # "N issues found" — harus <= 489
```

- **errors harus tetep 0.** Tiap import yang kelewat di Step 2/4 muncul di sini — ini yang ngeganti fungsi shim.
- **warnings (60) dan infos (429) nggak boleh naik.** Nggak ada step di ronde ini yang seharusnya ngubah angka-angka itu; kalau berubah, ada yang kebawa nggak sengaja.

### Cek struktur akhir

```powershell
Select-String -Path lib\**\*.dart -Pattern "config/api_config"        # 0 hit
Select-String -Path lib\**\*.dart -Pattern "services/api_client"      # 0 hit
Select-String -Path lib\**\*.dart -Pattern "import 'api_client.dart'" # 0 hit
Test-Path lib\config, lib\services\api_client.dart                    # dua-duanya False
```

### Smoke navigasi penutup

- [ ] `flutter run` debug → buka tiap dashboard role (`nasabah`, `petugas_bsu`, `petugas_bsm`, `petugas_bsi`)
- [ ] Tema keliatan identik (warna primary, background putih)
- [ ] Nggak ada `RenderFlex overflowed` baru di console

---

## Follow-up fungsional (sengaja di luar ronde ini)

| Item | Catatan |
|---|---|
| **Gap FCM: nggak ada `onBackgroundMessage`** | Data-only message ilang pas app di background |
| **`flutter_local_notifications` nggak dipakai** | Udah jadi dependency di `pubspec.yaml:51` tapi nol referensi di `lib/` → **notif foreground nggak keliatan sama user**, cuma nge-refresh list |
| **Deep link cuma nutup 1 dari 11 `ref_type`** | `notifikasi_screen.dart:63-144` udah punya switch lengkap buat 11 jenis. Sekarang tap notif dari tray buat `setoran` nggak ngapa-ngapain, padahal tap dari dalam app jalan. Follow-up: pindahin `_routeDeepLink` ke `lib/routing/notif_router.dart` yang megang navigator key dan nyatuin dua jalur itu |
| **`await requestPermission()`** | Perubahan perilaku — dialog muncul sebelum home, bukan di atasnya |
| **`bukti_penjualan_pdf_service.dart`** | Ngimport **naik** ke `../screens/penjualan_eksternal/pdf_bukti_penjualan.dart`. Layer violation nyata, tapi bukan REST wrapper dan nggak cocok di `core/network/`. Mindahin butuh keputusan di mana service yang ngasilin view tinggal |
| **11 raw `http` call di `auth_service.dart`** | 2 beneran butuh header `Cookie` manual + `refreshToken` bakal rekursi. Habis Step 5 semuanya udah share satu postur TLS, jadi nggak urgent |
| **Benerin `test/widget_test.dart`** | Jadi mungkin begitu `FcmMessaging.start()` di-guard dan `FirebaseMessaging` injectable (Step 6 udah nyiapin dua-duanya). Bakal ngasih project ini gate otomatis pertama yang jalan — **kandidat follow-up terbaik** |
