import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final phone = '+237${_ctrl.text.trim()}';
    await ref.read(authStateProvider.notifier).requestOtp(phone);
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.status == AuthStatus.otpSent) {
      context.push('/otp', extra: phone);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
        authStateProvider.select((s) => s.status == AuthStatus.loading));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text('🏍️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text(
                  'NYAMA Rider',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre numéro de livreur',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone field — grand, facile à taper
                TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixText: '+237 ',
                    prefixStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    hintText: '6XX XXX XXX',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 9) {
                      return 'Numéro invalide (9 chiffres requis)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit button — 72dp
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.white),
                          )
                        : const Text(
                            'Recevoir le code SMS',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),

                const Spacer(),
                const Center(
                  child: Text(
                    'Réservé aux livreurs NYAMA enregistrés',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
