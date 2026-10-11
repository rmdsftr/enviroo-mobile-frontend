import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/pengangkutan_provider.dart';
import '../../screens/bagi_hasil/struk_bagi_hasil_bsu_screen.dart';
import '../../screens/bagi_hasil/struk_bagi_hasil_nasabah.dart';
import '../../screens/katalog/katalog_barang_screen.dart';
import '../../screens/penarikan/detail_penarikan_screen.dart';
import '../../screens/penarikan/detail_transaksi_penarikan_screen.dart';
import '../../screens/pengangkutan/detail_pengangkutan_screen.dart';
import '../../screens/pengangkutan/pengangkutan_bsi_screen.dart';
import '../../screens/penimbangan/list_setoran_sesi_screen.dart';
import '../../screens/setoran/detail_setoran_screen.dart';

class NotifRouter {
  const NotifRouter._();

  static WidgetBuilder? _destination(String refType, String refId, String role) {
    switch (refType) {
      case 'jadwal_pengangkutan':
        return null;

      case 'jadwal_penimbangan':
        return (_) => ListSetoranSesiScreen(
              penimbanganId: refId,
              tanggalPenimbangan: '',
            );

      case 'setoran':
        return (_) => DetailSetoranScreen(setoranId: refId);

      case 'pengangkutan':
        return (_) => DetailPengangkutanScreen(pengangkutanId: refId);

      case 'pengajuan_pengangkutan':
        return (_) => const PengangkutanBsiScreen(
              initialTab: 1,
              initialFilter: 'requested',
            );

      case 'distribusi_barang':
        return (_) => const KatalogBarangScreen();

      case 'penarikan':
        return role == 'nasabah'
            ? (_) => DetailPenarikanScreen(penarikanId: refId)
            : (_) => DetailTransaksiPenarikanScreen(penarikanId: refId);

      case 'bagi_hasil':
        if (role == 'nasabah') {
          return (_) => StrukBagiHasilNasabah(penerimaId: refId);
        }
        if (role == 'petugas_bsu') {
          return (_) => StrukBagiHasilBsuScreen(penerimaSisaId: refId);
        }
        return null;

      default:
        return null;
    }
  }

  static bool hasDestination({
    String? refType,
    String? refId,
    required String role,
  }) {
    if (refType == null || refId == null) return false;
    return _destination(refType, refId, role) != null;
  }

  static bool open(
    NavigatorState navigator, {
    required String refType,
    required String refId,
  }) {
    final context = navigator.context;

    final role = context.read<AuthProvider>().role;
    final builder = _destination(refType, refId, role);
    if (builder == null) return false;

    if (refType == 'pengajuan_pengangkutan') {
      context.read<PengangkutanProvider>().setHighlight(refId);
    }

    navigator.push(MaterialPageRoute(builder: builder));
    return true;
  }
}
