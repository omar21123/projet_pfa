import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Core/widgets/Texts/CustomTextFormField.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      // ─────────────────────────────────────────────
      // 👉 CALL YOUR API HERE (send reset code to email)
      // Example:
      // final result = await authRepository.sendResetCode(
      //   email: _emailController.text.trim(),
      // );
      //
      // if (result.isSuccess) {
      //   if (mounted) {
      context.push(
        '/forgot-password/verify',
        extra: _emailController.text.trim(),
      );
      //   }
      // } else {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text(result.errorMessage)),
      //     );
      //   }
      // }
      // ─────────────────────────────────────────────
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Une erreur est survenue: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.02,
                ),
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accent20(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary(context),
                      size: 30,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.primary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez l\'adresse e-mail associée à votre compte. '
                    'Nous vous enverrons un code pour réinitialiser votre mot de passe.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  SizedBox(height: size.height * 0.035),

                  CustomTextFormField(
                    label: 'Adresse e-mail',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'e-mail est requis';
                      }
                      final emailRegex = RegExp(
                        r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'E-mail invalide';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.035),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoading
                          ? Container(
                              key: const ValueKey('loading'),
                              decoration: BoxDecoration(
                                color: AppColors.primary(context),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.onPrimary(context),
                                  ),
                                ),
                              ),
                            )
                          : Customnavigationbutton(
                              key: const ValueKey('button'),
                              text: 'Envoyer le code',
                              backgroundColor: AppColors.primary(context),
                              textColor: AppColors.onPrimary(context),
                              onPressed: _handleSendCode,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
