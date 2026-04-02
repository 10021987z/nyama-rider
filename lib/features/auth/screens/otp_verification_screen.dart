import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authStateProvider, (_, state) {
      if (!mounted) return;
      if (state.status == AuthStatus.authenticated) {
        context.go('/courses');
      } else if (state.status == AuthStatus.wrongRole) {
        _controller.clear();
        _showWrongRoleDialog(state.errorMessage);
      } else if (state.status == AuthStatus.error &&
          state.errorMessage != null) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showWrongRoleDialog(String? msg) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🏍️ Accès livreur requis'),
        content: Text(msg ?? 'Ce numéro n\'est pas enregistré comme livreur.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/phone');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying = ref.watch(
        authStateProvider.select((s) => s.status == AuthStatus.verifying));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 28),
          onPressed: () => context.go('/phone'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Code SMS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code envoyé au ${widget.phone}',
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // OTP input — gros chiffres
              PinCodeTextField(
                appContext: context,
                controller: _controller,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 64,
                  fieldWidth: 52,
                  activeFillColor: AppColors.background,
                  selectedFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                ),
                enableActiveFill: true,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                onCompleted: (code) {
                  ref
                      .read(authStateProvider.notifier)
                      .verifyOtp(widget.phone, code);
                },
                onChanged: (_) {},
              ),
              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                height: 72,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () {
                          if (_controller.text.length == 6) {
                            ref.read(authStateProvider.notifier).verifyOtp(
                                widget.phone, _controller.text);
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.white),
                        )
                      : const Text(
                          'Valider',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend
              Center(
                child: TextButton(
                  onPressed: () =>
                      ref.read(authStateProvider.notifier).resendOtp(),
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
