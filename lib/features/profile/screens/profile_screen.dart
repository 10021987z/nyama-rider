import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../courses/data/models/course_model.dart';
import '../../earnings/providers/earnings_provider.dart';

// ─── Local settings providers ─────────────────────────────────────────────────

final _soundEnabledProvider = StateProvider<bool>((ref) => true);
final _dataEconomyProvider = StateProvider<bool>((ref) => false);

// ─── Profile screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(riderProfileProvider);
    final soundEnabled = ref.watch(_soundEnabledProvider);
    final dataEconomy = ref.watch(_dataEconomyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Impossible de charger le profil',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(riderProfileProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (profile) => _buildContent(
          context,
          ref,
          profile,
          soundEnabled,
          dataEconomy,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    RiderProfileModel profile,
    bool soundEnabled,
    bool dataEconomy,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête profil ─────────────────────────────────────────────
          _ProfileHeader(profile: profile),
          const SizedBox(height: 20),

          // ── Véhicule ───────────────────────────────────────────────────
          _ProfileCard(
            icon: '🏍️',
            title: 'Mon véhicule',
            children: [
              ListTile(
                leading: Text(
                  _vehicleIcon(profile.vehicleType),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  profile.vehicleType ?? 'Moto',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: profile.plateNumber != null
                    ? Text('Plaque : ${profile.plateNumber!}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Paiement ───────────────────────────────────────────────────
          _ProfileCard(
            icon: '💳',
            title: 'Paiement',
            children: [
              ListTile(
                leading: Text(
                  _momoIcon(profile.momoProvider),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  _momoLabel(profile.momoProvider),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: profile.momoPhone != null
                    ? Text(
                        _maskPhone(profile.momoPhone!),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Paramètres ─────────────────────────────────────────────────
          _ProfileCard(
            icon: '⚙️',
            title: 'Paramètres',
            children: [
              SwitchListTile(
                title: const Text('🔔 Son des alertes',
                    style: TextStyle(fontSize: 15)),
                value: soundEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(_soundEnabledProvider.notifier).state = v,
              ),
              SwitchListTile(
                title: const Text('📡 Mode économie data',
                    style: TextStyle(fontSize: 15)),
                subtitle: const Text(
                  'Réduit la fréquence GPS à 15s',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                value: dataEconomy,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(_dataEconomyProvider.notifier).state = v,
              ),
              const ListTile(
                title: Text('🌐 Langue', style: TextStyle(fontSize: 15)),
                trailing: Text(
                  'Français',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Aide ───────────────────────────────────────────────────────
          _ProfileCard(
            icon: '❓',
            title: 'Aide',
            children: [
              ListTile(
                title: const Text('📞 Contacter NYAMA',
                    style: TextStyle(fontSize: 15)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textSecondary),
                onTap: () async {
                  final uri = Uri.parse('tel:+237600000000');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              const ListTile(
                title:
                    Text('ℹ️ Version', style: TextStyle(fontSize: 15)),
                trailing: Text(
                  'NYAMA Rider v1.0.0',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Déconnexion ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content:
            const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/phone');
            },
            child: const Text(
              'Déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _vehicleIcon(String? type) {
    if (type == null) return '🏍️';
    final t = type.toLowerCase();
    if (t.contains('velo') || t.contains('vélo') || t.contains('bike')) {
      return '🚲';
    }
    if (t.contains('voiture') || t.contains('car')) return '🚗';
    return '🏍️';
  }

  String _momoIcon(String? provider) {
    final p = provider?.toUpperCase() ?? '';
    if (p.contains('MTN')) return '🟡';
    if (p.contains('ORANGE')) return '🟠';
    return '💳';
  }

  String _momoLabel(String? provider) {
    final p = provider?.toUpperCase() ?? '';
    if (p.contains('MTN')) return 'MTN Mobile Money';
    if (p.contains('ORANGE')) return 'Orange Money';
    return 'Mobile Money';
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

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final RiderProfileModel profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.name ?? 'Livreur';
    final initials = _initials(name);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.ctaGreen,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _BadgeChip(trips: profile.totalTrips, rating: profile.avgRating),
          const SizedBox(height: 8),
          RatingBarIndicator(
            rating: profile.avgRating,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            itemCount: 5,
            itemSize: 20,
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.totalTrips} course${profile.totalTrips > 1 ? 's' : ''} effectuée${profile.totalTrips > 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _BadgeChip extends StatelessWidget {
  final int trips;
  final double rating;
  const _BadgeChip({required this.trips, required this.rating});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bgColor;
    late final Color textColor;

    if (trips >= 100 && rating > 4.5) {
      label = '⭐ Premium';
      bgColor = AppColors.gold;
      textColor = Colors.black;
    } else if (trips >= 21) {
      label = '✅ Confirmé';
      bgColor = AppColors.ctaGreen;
      textColor = Colors.white;
    } else {
      label = '🆕 Nouveau';
      bgColor = Colors.grey.shade300;
      textColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String icon;
  final String title;
  final List<Widget> children;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '$icon $title',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
