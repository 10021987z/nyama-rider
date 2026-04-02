import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../courses/data/models/course_model.dart';
import '../data/models/earnings_model.dart';
import '../providers/earnings_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  // Trend simulée une fois par session
  late final Map<String, (bool, int)> _trends;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _trends = {
      'today': (rng.nextBool(), 5 + rng.nextInt(20)),
      'week': (rng.nextBool(), 3 + rng.nextInt(15)),
      'month': (rng.nextBool(), 2 + rng.nextInt(25)),
    };
  }

  void _openTransferSheet(EarningsModel earnings, RiderProfileModel? profile) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: _TransferSheet(
          total: earnings.total,
          profile: profile,
          onSuccess: () {
            Navigator.of(sheetCtx).pop();
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  "✅ Transfert effectué ! L'argent arrive sur votre compte.",
                  style: TextStyle(fontSize: 15),
                ),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 4),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(selectedPeriodProvider);
    final earningsAsync = ref.watch(earningsProvider(period));
    final profileAsync = ref.watch(riderProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Mes Gains',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: earningsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Impossible de charger les gains',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(earningsProvider(period)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (earnings) {
          final profile = profileAsync.valueOrNull;
          final trend =
              _trends[period] ?? (true, 10);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(earningsProvider(period)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Solde disponible ───────────────────────────────────
                  _BalanceCard(
                    earnings: earnings,
                    onTransfer: () =>
                        _openTransferSheet(earnings, profile),
                  ),
                  const SizedBox(height: 16),

                  // ── Gains période ──────────────────────────────────────
                  _PeriodCard(
                    earnings: earnings,
                    trendUp: trend.$1,
                    trendPct: trend.$2,
                  ),
                  const SizedBox(height: 12),

                  // ── Sélecteur période ──────────────────────────────────
                  _PeriodChips(),
                  const SizedBox(height: 12),

                  // ── Contenu selon période ──────────────────────────────
                  if (period == 'today')
                    _TodayList(earnings: earnings)
                  else
                    _WeekMonthSummary(earnings: earnings),
                  const SizedBox(height: 16),

                  // ── Stats ──────────────────────────────────────────────
                  if (profile != null)
                    _StatsCard(earnings: earnings, profile: profile),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final EarningsModel earnings;
  final VoidCallback onTransfer;

  const _BalanceCard({required this.earnings, required this.onTransfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            earnings.total.toFcfa(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: onTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                '💸 Transférer mes gains',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period card ───────────────────────────────────────────────────────────────

class _PeriodCard extends StatelessWidget {
  final EarningsModel earnings;
  final bool trendUp;
  final int trendPct;

  const _PeriodCard({
    required this.earnings,
    required this.trendUp,
    required this.trendPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earnings.total.toFcfa(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${earnings.count} course${earnings.count > 1 ? 's' : ''} effectuée${earnings.count > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: trendUp
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${trendUp ? '↑' : '↓'} ${trendUp ? '+' : '-'}$trendPct%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: trendUp ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period chips ──────────────────────────────────────────────────────────────

class _PeriodChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(
            label: "Aujourd'hui",
            value: 'today',
            selected: period == 'today',
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Semaine',
            value: 'week',
            selected: period == 'week',
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Mois',
            value: 'month',
            selected: period == 'month',
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends ConsumerWidget {
  final String label;
  final String value;
  final bool selected;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (val) {
        if (val) ref.read(selectedPeriodProvider.notifier).state = value;
      },
    );
  }
}

// ── Today list ────────────────────────────────────────────────────────────────

class _TodayList extends StatelessWidget {
  final EarningsModel earnings;
  const _TodayList({required this.earnings});

  @override
  Widget build(BuildContext context) {
    if (earnings.breakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          "Pas encore de course aujourd'hui",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < earnings.breakdown.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 16, endIndent: 16),
            _EntryRow(entry: earnings.breakdown[i]),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final EarningEntry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            entry.timeLabel,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            '+${entry.netXaf.toFcfa()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week / Month summary ──────────────────────────────────────────────────────

class _WeekMonthSummary extends StatelessWidget {
  final EarningsModel earnings;
  const _WeekMonthSummary({required this.earnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            earnings.total.toFcfa(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${earnings.count} course${earnings.count > 1 ? 's' : ''} effectuée${earnings.count > 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          Text(
            'Gain moyen par course',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            earnings.avgPerDelivery.toFcfa(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final EarningsModel earnings;
  final RiderProfileModel profile;

  const _StatsCard({required this.earnings, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Mes stats',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCol(
                  icon: '🏍️',
                  label: 'Courses',
                  value: '${profile.totalTrips}',
                  valueSize: 24,
                ),
              ),
              Expanded(
                child: _StatCol(
                  icon: '⭐',
                  label: 'Note',
                  value: profile.avgRating.toStringAsFixed(1),
                  valueSize: 24,
                ),
              ),
              Expanded(
                child: _StatCol(
                  icon: '💰',
                  label: 'Moyenne',
                  value: earnings.avgPerDelivery.toFcfa(),
                  valueSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final double valueSize;

  const _StatCol({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Transfer bottom sheet ─────────────────────────────────────────────────────

class _TransferSheet extends StatefulWidget {
  final int total;
  final RiderProfileModel? profile;
  final VoidCallback onSuccess;

  const _TransferSheet({
    required this.total,
    required this.profile,
    required this.onSuccess,
  });

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  late final TextEditingController _amountCtrl;
  final TextEditingController _pinCtrl = TextEditingController();
  String _pin = '';
  bool _isTransferring = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.total > 0 ? widget.total.toString() : '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _doTransfer() async {
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount < 1000) {
      setState(() => _errorMsg = 'Montant minimum : 1 000 FCFA');
      return;
    }
    if (amount > widget.total) {
      setState(
          () => _errorMsg = 'Montant supérieur au solde disponible');
      return;
    }
    setState(() {
      _isTransferring = true;
      _errorMsg = null;
    });

    // Simulated 2-second transfer
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isTransferring = false);
    widget.onSuccess();
  }

  String get _operatorLabel {
    final provider = widget.profile?.momoProvider?.toUpperCase() ?? '';
    if (provider.contains('MTN')) return '🟡 MTN Mobile Money';
    if (provider.contains('ORANGE')) return '🟠 Orange Money';
    return '💳 Mobile Money';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            '💸 Transférer mes gains',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),

          // Montant
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffixText: 'FCFA',
              suffixStyle:
                  TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            onChanged: (_) => setState(() => _errorMsg = null),
          ),
          const SizedBox(height: 16),

          // Opérateur (lecture seule)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Opérateur',
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
            child: Text(
              _operatorLabel,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // Numéro (lecture seule, masqué)
          if (profile?.momoPhone != null)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Numéro',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              child: Text(
                _maskPhone(profile!.momoPhone!),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          const SizedBox(height: 16),

          // PIN Nyama
          const Text(
            'PIN Nyama',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          PinCodeTextField(
            appContext: context,
            length: 4,
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 48,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              selectedFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary,
              inactiveColor: Colors.grey.shade300,
            ),
            enableActiveFill: true,
            onChanged: (value) => _pin = value,
            onCompleted: (value) => _pin = value,
          ),
          const SizedBox(height: 4),

          // Error message
          if (_errorMsg != null) ...[
            Text(
              _errorMsg!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),

          // Transfer button
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton(
              onPressed: (_isTransferring || _pin.length < 4)
                  ? null
                  : _doTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor:
                    AppColors.secondary.withValues(alpha: 0.5),
                foregroundColor: Colors.black,
              ),
              child: _isTransferring
                  ? const CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 3)
                  : Text(
                      'Transférer ${int.tryParse(_amountCtrl.text)?.toFcfa() ?? '--'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 11 && digits.startsWith('237')) {
      return '+237 ${digits.substring(3, 5)}X XXX XX${digits.substring(digits.length - 2)}';
    }
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 5)}XXXX${phone.substring(phone.length - 2)}';
  }
}
