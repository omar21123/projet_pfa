import 'dart:async';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/widgets/Buttons/CustomNavigationButton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  const VerifyResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool isLoading = false;
  bool isResending = false;
  String? errorText;
  int _secondsLeft = 60;
  Timer? _timer;

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

    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (_code.length != 4) {
      setState(() => errorText = 'Veuillez entrer le code complet');
      return;
    }
    setState(() {
      errorText = null;
      isLoading = true;
    });

    try {
      // ─────────────────────────────────────────────
      // 👉 CALL YOUR API HERE (verify reset code)
      // Example:
      // final result = await authRepository.verifyResetCode(
      //   email: widget.email,
      //   code: _code,
      // );
      //
      // if (result.isSuccess) {
      //   if (mounted) {
      context.push(
        '/forgot-password/reset',
        extra: {'email': widget.email, 'code': _code},
      );
      //   }
      // } else {
      //   if (mounted) setState(() => errorText = 'Code incorrect. Réessayez.');
      // }
      // ─────────────────────────────────────────────
    } catch (e) {
      if (mounted) setState(() => errorText = 'Une erreur est survenue');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => isResending = true);
    try {
      // ─────────────────────────────────────────────
      // 👉 CALL YOUR API HERE (resend reset code)
      // await authRepository.sendResetCode(email: widget.email);
      // ─────────────────────────────────────────────
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (errorText != null) setState(() => errorText = null);
    if (_code.length == 4) _handleVerify();
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
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary(context),
                    size: 30,
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                Text(
                  'Vérifiez votre e-mail',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.primary(context),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.secondary(context),
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Veuillez entrer le code que nous avons envoyé à ',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: 64,
                      height: 64,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary(context),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.softBg(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: errorText != null
                                  ? Colors.redAccent
                                  : AppColors.accent20(context),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: errorText != null
                                  ? Colors.redAccent
                                  : AppColors.accent20(context),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary(context),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    );
                  }),
                ),

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],

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
                            text: 'Vérifier',
                            backgroundColor: AppColors.primary(context),
                            textColor: AppColors.onPrimary(context),
                            onPressed: _handleVerify,
                          ),
                  ),
                ),
                SizedBox(height: size.height * 0.025),

                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Renvoyer le code dans ${_secondsLeft}s',
                          style: TextStyle(
                            color: AppColors.secondary(context),
                            fontSize: 14,
                          ),
                        )
                      : TextButton(
                          onPressed: isResending ? null : _handleResend,
                          child: Text(
                            isResending ? 'Envoi...' : 'Renvoyer le code',
                            style: TextStyle(
                              color: AppColors.primary(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),

                SizedBox(height: size.height * 0.015),

                // ── "Ce n'est pas vous ?" ────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Ce n\'est pas vous ?',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
