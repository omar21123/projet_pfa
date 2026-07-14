import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/widgets/Buttons/CustomIconButton.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Core/widgets/Texts/CustomTextFormField.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Validate email/password rules first
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isLoading = true);

    try {
      // ─────────────────────────────────────────────
      // 👉 CALL YOUR API HERE
      // Example:
      // final result = await authRepository.login(
      //   email: _emailController.text.trim(),
      //   password: _passwordController.text,
      // );
      //
      // if (result.isSuccess) {
      //   if (mounted) CustomNavigator.safeNavigateToMainPage();
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
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent20(context),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: size.width * 0.30,
                          height: size.width * 0.30,
                          child: Image.asset(
                            'assets/images/Logo12.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.primary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour continuer vos achats et ventes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  SizedBox(height: size.height * 0.035),

                  // ── Credentials card ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.softBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent20(context),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
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
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          label: 'Mot de passe',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            if (value.length < 8) {
                              return '8 caractères minimum';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:  isLoading ? null : () => context.push('/forgot-password'),

                      child: Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),

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
                              text: 'Se connecter',
                              backgroundColor: AppColors.primary(context),
                              textColor: AppColors.onPrimary(context),
                              onPressed: _handleLogin,
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.accent30(context),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'ou',
                          style: TextStyle(color: AppColors.secondary(context)),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.accent30(context),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.025),

                  Row(
                    children: [
                      Expanded(
                        child: CustomIconButton(
                          iconPath: 'assets/images/google.svg',
                          title: 'Google',
                          onPressed: isLoading
                              ? null
                              : () {
                                  // Handle Google login logic here
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomIconButton(
                          iconPath: 'assets/images/facebook.svg',
                          title: 'Facebook',
                          onPressed: isLoading
                              ? null
                              : () {
                                  // Handle Facebook login logic here
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomIconButton(
                          iconPath: 'assets/images/apple.svg',
                          title: 'Apple',
                          onPressed: isLoading
                              ? null
                              : () {
                                  // Handle Apple login logic here
                                },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.025),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous n\'avez pas de compte ?',
                        style: TextStyle(
                          color: AppColors.secondary(context),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                await CustomNavigator.navigateToRegister();
                              },
                        child: Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: AppColors.primary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
