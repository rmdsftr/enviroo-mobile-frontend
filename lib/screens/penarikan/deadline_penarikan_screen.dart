import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../core/format/app_date.dart';
import '../../models/penarikan_model.dart';
import '../../providers/penarikan_petugas_provider.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/topbar_back.dart';
import 'preview_request_penarikan_screen.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

enum _DeadlineMode { nasabahRequest, petugasTolak, petugasSetujui }

class DeadlinePenarikanScreen extends StatefulWidget {
  final _DeadlineMode _mode;
  final PenarikanFormData? formData;
  final String? penarikanId;

  const DeadlinePenarikanScreen.request({super.key, required this.formData})
      : _mode = _DeadlineMode.nasabahRequest,
        penarikanId = null;

  const DeadlinePenarikanScreen.tolak({super.key, required this.penarikanId})
      : _mode = _DeadlineMode.petugasTolak,
        formData = null;

  const DeadlinePenarikanScreen.setujui({super.key, required this.penarikanId})
      : _mode = _DeadlineMode.petugasSetujui,
        formData = null;

  @override
  State<DeadlinePenarikanScreen> createState() =>
      _DeadlinePenarikanScreenState();
}

class _DeadlinePenarikanScreenState extends State<DeadlinePenarikanScreen> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _dateTimeError;
  Timer? _clockTimer;
  bool _submitting = false;

  final TextEditingController _catatanController = TextEditingController();

  bool get _showDateTime => widget._mode != _DeadlineMode.petugasTolak;
  bool get _catatanRequired => widget._mode == _DeadlineMode.petugasTolak;

  DateTime get _minDateTime => DateTime.now().add(const Duration(hours: 1));
  DateTime get _maxDateTime => DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _validate();
    });
    if (_catatanRequired) {
      _catatanController.addListener(_onCatatanChanged);
    }
  }

  void _onCatatanChanged() => setState(() {});

  @override
  void dispose() {
    _clockTimer?.cancel();
    if (_catatanRequired) {
      _catatanController.removeListener(_onCatatanChanged);
    }
    _catatanController.dispose();
    super.dispose();
  }

  DateTime? get _combined {
    final d = _selectedDate;
    final t = _selectedTime;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _isValid {
    if (widget._mode == _DeadlineMode.petugasTolak) {
      return _catatanController.text.trim().isNotEmpty;
    }
    final combined = _combined;
    if (combined == null) return false;
    return !combined.isBefore(_minDateTime) && !combined.isAfter(_maxDateTime);
  }

  bool _validate() {
    if (!_showDateTime) return true;
    final combined = _combined;
    if (combined == null) {
      setState(() => _dateTimeError = null);
      return false;
    }
    if (combined.isBefore(_minDateTime) || combined.isAfter(_maxDateTime)) {
      setState(() {
        _dateTimeError =
            'Tenggat harus antara ${DateFormat('d MMM, HH:mm', 'id_ID').format(_minDateTime)} '
            'dan ${DateFormat('d MMM, HH:mm', 'id_ID').format(_maxDateTime)}';
      });
      return false;
    }
    setState(() => _dateTimeError = null);
    return true;
  }

  Future<void> _pickDate() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DatePickerSheet(
        pengajuanAt: DateTime.now(),
        minDateTime: _minDateTime,
        maxDateTime: _maxDateTime,
        initialDate: _selectedDate,
      ),
    );
    if (result == null) return;
    setState(() => _selectedDate = result);
    _validate();
  }

  Future<void> _pickTime() async {
    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TimePickerSheet(initialTime: _selectedTime),
    );
    if (result == null) return;
    setState(() => _selectedTime = result);
    _validate();
  }

  void _handleSubmit() {
    if (widget._mode == _DeadlineMode.petugasTolak) {
      _submitTolak();
      return;
    }

    if (_selectedDate == null) {
      setState(() => _dateTimeError = 'Pilih tanggal terlebih dahulu');
      return;
    }
    if (_selectedTime == null) {
      setState(() => _dateTimeError = 'Pilih waktu terlebih dahulu');
      return;
    }
    if (!_validate()) return;

    if (widget._mode == _DeadlineMode.petugasSetujui) {
      _submitSetujui();
      return;
    }

    HapticFeedback.lightImpact();
    final catatan = _catatanController.text.trim();
    final formData = widget.formData!.copyWith(
      batasKonfirmasi: _combined,
      catatanPetugas: catatan.isEmpty ? null : catatan,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewRequestPenarikanScreen(formData: formData),
      ),
    );
  }

  Future<void> _submitTolak() async {
    final prov = context.read<PenarikanPetugasProvider>();
    setState(() => _submitting = true);

    final ok = await prov.tolakPengajuan(
      penarikanId: widget.penarikanId!,
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      _showErrorSnack(prov.errorDetail ?? 'Gagal menolak pengajuan');
    }
  }

  Future<void> _submitSetujui() async {
    final prov = context.read<PenarikanPetugasProvider>();
    setState(() => _submitting = true);

    final catatan = _catatanController.text.trim();
    final ok = await prov.setujuiPengajuan(
      penarikanId: widget.penarikanId!,
      deadlineJemput: _combined!,
      catatan: catatan.isEmpty ? null : catatan,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      _showErrorSnack(prov.errorDetail ?? 'Gagal menyetujui pengajuan');
    }
  }

  void _showErrorSnack(String message) {
    showCustomSnackBar(context, message);
  }

  String get _topbarTitle {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return 'Tenggat Konfirmasi';
      case _DeadlineMode.petugasTolak:
        return 'Tolak Pengajuan';
      case _DeadlineMode.petugasSetujui:
        return 'Setujui Pengajuan';
    }
  }

  String get _instruksiText {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return 'Tentukan tenggat waktu konfirmasi pengajuan penarikan dari pihak bank sampah. '
            'Minimal 1 jam dan maksimal 3 hari dari waktu pengajuan dibuat.';
      case _DeadlineMode.petugasTolak:
        return 'Isi alasan pengajuan penarikan nasabah ditolak. Nasabah akan menerima '
            'notifikasi dan pengembalian saldo.';
      case _DeadlineMode.petugasSetujui:
        return 'Tentukan tenggat waktu pengambilan insentif nasabah, minimal 1 jam dan '
            'maksimal 3 hari dari waktu persetujuan pencairan saldo.';
    }
  }

  String get _catatanLabel {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return 'Catatan Untuk Petugas';
      case _DeadlineMode.petugasTolak:
        return 'Alasan Penolakan';
      case _DeadlineMode.petugasSetujui:
        return 'Catatan Untuk Nasabah';
    }
  }

  String get _catatanHint {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return 'Tulis catatan atau pesan untuk pengurus bank sampah';
      case _DeadlineMode.petugasTolak:
        return 'Tulis alasan penolakan pengajuan penarikan';
      case _DeadlineMode.petugasSetujui:
        return 'Tulis catatan untuk nasabah';
    }
  }

  String get _ctaLabel {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return 'Lihat Preview';
      case _DeadlineMode.petugasTolak:
        return 'Tolak Pengajuan';
      case _DeadlineMode.petugasSetujui:
        return 'Setujui Pengajuan';
    }
  }

  Color get _ctaColor {
    switch (widget._mode) {
      case _DeadlineMode.nasabahRequest:
        return dark;
      case _DeadlineMode.petugasTolak:
        return AppColors.dark;
      case _DeadlineMode.petugasSetujui:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            TopBarBack(title: _topbarTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstruksi(),
                    if (_showDateTime) ...[
                      const SizedBox(height: 24),
                      const _SectionLabel('Tanggal', required: true),
                      const SizedBox(height: 8),
                      _SelectField(
                        icon: Icons.calendar_today_rounded,
                        placeholder: 'Pilih tanggal',
                        value: _selectedDate == null
                            ? null
                            : AppDate.tanggalPenuh(_selectedDate!),
                        hasError: _dateTimeError != null,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Waktu', required: true),
                      const SizedBox(height: 8),
                      _SelectField(
                        icon: Icons.access_time_rounded,
                        placeholder: 'Pilih waktu',
                        value: _selectedTime?.format(context),
                        hasError: _dateTimeError != null,
                        onTap: _pickTime,
                      ),
                      if (_dateTimeError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _dateTimeError!,
                            style: AppText.r(11, Colors.red),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    _SectionLabel(_catatanLabel, required: _catatanRequired),
                    const SizedBox(height: 8),
                    _buildCatatanField(),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: _buildCTA(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruksi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _instruksiText,
              style: AppText.p(12, color: dark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _catatanController,
        maxLines: 5,
        minLines: 5,
        maxLength: 255,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
        style: AppText.p(13, color: dark, height: 1.5),
        decoration: InputDecoration(
          hintText: _catatanHint,
          hintStyle: AppText.r(13, dark.withValues(alpha: 0.35)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          counterStyle: AppText.r(11, dark.withValues(alpha: 0.35)),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final disabled = !_isValid || _submitting;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade400 : _ctaColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : _handleSubmit,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _ctaLabel,
                      style: AppText.w600(14, Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _SectionLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppText.w600(12, Colors.black.withValues(alpha: 0.7)),
        children: [
          if (required)
            TextSpan(
              text: '*',
              style: AppText.w600(12, Colors.red),
            ),
        ],
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  final IconData icon;
  final String placeholder;
  final String? value;
  final bool hasError;
  final VoidCallback onTap;

  const _SelectField({
    required this.icon,
    required this.placeholder,
    required this.value,
    required this.hasError,
    required this.onTap,
  });

  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: hasError && value == null
                  ? Colors.red
                  : Colors.black.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: AppText.p(14, weight: value == null ? FontWeight.w500 : FontWeight.w600, color: value == null
                        ? dark.withValues(alpha: 0.35)
                        : dark),
                ),
              ),
              Icon(Icons.expand_more_rounded,
                  size: 20, color: dark.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerSheet extends StatelessWidget {
  final DateTime pengajuanAt;
  final DateTime minDateTime;
  final DateTime maxDateTime;
  final DateTime? initialDate;

  const _DatePickerSheet({
    required this.pengajuanAt,
    required this.minDateTime,
    required this.maxDateTime,
    required this.initialDate,
  });

  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _labelFor(int offset, DateTime date) {
    switch (offset) {
      case 0:
        return 'Hari ini';
      case 1:
        return 'Besok';
      case 2:
        return 'Lusa';
      default:
        return AppDate.namaHari(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseDate = _startOfDay(pengajuanAt);
    final dates = List.generate(4, (i) => baseDate.add(Duration(days: i)));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih Tanggal',
            style: AppText.w700(16, dark),
          ),
          const SizedBox(height: 16),
          ...dates.asMap().entries.map((e) {
            final offset = e.key;
            final date = e.value;
            final enabled = _endOfDay(date).isAfter(minDateTime) &&
                !_startOfDay(date).isAfter(maxDateTime);
            final isSelected =
                initialDate != null && _sameDay(initialDate!, date);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: enabled ? () => Navigator.pop(context, date) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withValues(alpha: 0.1)
                        : enabled
                            ? AppColors.surface
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelFor(offset, date),
                              style: AppText.w600(13.5, enabled
                                    ? (isSelected ? primary : dark)
                                    : dark.withValues(alpha: 0.3)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppDate.tanggalPanjang(date),
                              style: AppText.r(11.5, enabled
                                    ? dark.withValues(alpha: 0.5)
                                    : dark.withValues(alpha: 0.25)),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay? initialTime;
  const _TimePickerSheet({required this.initialTime});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  static const Color primary = AppColors.green;
  static const Color dark = AppColors.dark;

  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _hour = widget.initialTime?.hour ?? now.hour;
    _minute = widget.initialTime?.minute ?? now.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 70,
      height: 160,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: AppText.w700(20, primary),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWheel(
                    controller: _hourCtrl,
                    itemCount: 24,
                    onChanged: (i) => setState(() => _hour = i),
                  ),
                  Text(
                    ':',
                    style: AppText.w700(22, primary),
                  ),
                  _buildWheel(
                    controller: _minuteCtrl,
                    itemCount: 60,
                    onChanged: (i) => setState(() => _minute = i),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: () => Navigator.pop(
                context,
                TimeOfDay(hour: _hour, minute: _minute),
              ),
              child: Text(
                'Pilih Waktu',
                style: AppText.w600(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
