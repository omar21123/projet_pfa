import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Core/widgets/Buttons/CustomPillRadioGroup.dart';
import 'package:connectia/Core/widgets/DateTime/CustomDateTimePicker.dart';
import 'package:connectia/Core/widgets/Terms%20and%20policies/TermsAcceptanceCheckbox.dart';
import 'package:connectia/Core/widgets/Texts/CustomTextFormField.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Registerscreen extends StatefulWidget {
  const Registerscreen({super.key});

  @override
  State<Registerscreen> createState() => _RegisterscreenState();
}

class _RegisterscreenState extends State<Registerscreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? selectedGender;
  DateTime? birthDate;
  bool acceptedTerms = false;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                  vertical: 0,
                ),
                children: [
                  SizedBox(height: size.height * 0.02),
                  Text(
                    'Créer un compte',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.primary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez Connectia et commencez à acheter et\nvendre.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),

                  // ── Identity card ────────────────────────
                  _SectionCard(
                    children: [
                      CustomTextFormField(
                        label: 'Prénom',
                        hintText: 'Mohammed',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        controller: _firstNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          if (value.trim().length < 2) {
                            return 'Le prénom est trop court';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        label: 'Nom',
                        hintText: 'Bourass',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        controller: _lastNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          if (value.trim().length < 2) {
                            return 'Le nom est trop court';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Credentials card ─────────────────────
                  _SectionCard(
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
                          final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
                          final hasDigit = RegExp(r'\d').hasMatch(value);
                          if (!hasLetter || !hasDigit) {
                            return 'Utilisez lettres et chiffres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Optional details card ────────────────
                  _SectionCard(
                    children: [
                      CustomTextFormField(
                        label: 'Numéro de téléphone (facultatif)',
                        hintText: '+212600000000',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Numéro invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomDateTimePicker(
                        label: 'Date de naissance',
                        onDateSelected: (date) {
                          setState(() => birthDate = date);
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomPillRadioGroup(
                        label: 'Genre (facultatif)',
                        options: const ['Homme', 'Femme'],
                        selectedValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Terms ────────────────────────────────
                  TermsAcceptanceCheckbox(
                    isChecked: acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        acceptedTerms = value;
                      });
                    },
                    onTermsTap: () => context.push('/terms'),
                    onPrivacyTap: () => context.push('/privacy'),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit ───────────────────────────────
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
                              text: 'Créer un compte',
                              backgroundColor: AppColors.primary(context),
                              textColor: AppColors.onPrimary(context),
                              onPressed: _handleLogin,
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // 1. Validate all text-field-based rules (name, email, password, phone)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validate terms acceptance separately (not a Form field)
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary(context),
          content: const Text(
            'Veuillez accepter les conditions d\'utilisation',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ─────────────────────────────────────────────
      // 👉 CALL YOUR API HERE
      // Example:
      // final result = await authRepository.register(
      //   firstName: _firstNameController.text.trim(),
      //   lastName: _lastNameController.text.trim(),
      //   email: _emailController.text.trim(),
      //   password: _passwordController.text,
      //   phone: _phoneController.text.trim().isEmpty
      //       ? null
      //       : _phoneController.text.trim(),
      //   birthDate: birthDate,
      //   gender: selectedGender,
      // );
      //
      // if (result.isSuccess) {
      //   if (mounted) context.go('/');
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
}

/// A soft rounded card grouping related form fields together,
/// using the app's neutral surface tones for a cleaner visual rhythm.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent20(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
