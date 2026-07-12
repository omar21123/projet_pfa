import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CustomIconButton.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:connectia/Core/widgets/Texts/CustomTextFormField.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle login logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.02,
            ),
            children: [
              Center(
                child: ClipOval(
                  child: SizedBox(
                    width: size.width * 0.32,
                    height: size.width * 0.32,
                    child: Image.asset(
                      'assets/images/Logo12.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.025),
              Text(
                'Connexion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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

              CustomTextFormField(
                label: 'Adresse e-mail',
                hintText: 'exemple@email.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'e-mail est requis';
                  }
                  if (!value.contains('@')) return 'E-mail invalide';
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
                  return null;
                },
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle forgot password logic here
                  },
                  child: Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.015),

              SizedBox(
                width: double.infinity,
                child: Customnavigationbutton(
                  text: 'Se connecter',
                  backgroundColor: AppColors.primary(context),
                  textColor: AppColors.onPrimary(context),
                  onPressed: _handleLogin,
                ),
              ),
              SizedBox(height: size.height * 0.03),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.secondary(context),
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
                      color: AppColors.secondary(context),
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
                      onPressed: () {
                        // Handle Google login logic here
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomIconButton(
                      iconPath: 'assets/images/facebook.svg',
                      title: 'Facebook',
                      onPressed: () {
                        // Handle Facebook login logic here
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomIconButton(
                      iconPath: 'assets/images/apple.svg',
                      title: 'Apple',
                      onPressed: () {
                        // Handle Apple login logic here
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.035),

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
                    onPressed: () {
                      // Navigate to register screen
                      // CustomNavigator.safeNavigateToRegister();
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
    );
  }
}