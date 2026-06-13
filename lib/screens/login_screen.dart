import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  void _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!)),
      );
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.hasToken && (_emailController.text.isEmpty || _passwordController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login com e-mail e senha ao menos uma vez neste dispositivo.')),
      );
      return;
    }

    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometria não suportada neste dispositivo.')),
        );
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para acessar a conta',
        biometricOnly: true,
      );

      if (didAuthenticate && mounted) {
        if (authProvider.hasToken) {
          Provider.of<AuthProvider>(context, listen: false).unlock();
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _login();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao verificar biometria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    return Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Side: Visual/Branding
                        if (isDesktop)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(Icons.rocket_launch, color: colorScheme.primary, size: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    Text('Josi Finanças', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -1)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text('Transforme sua relação com o dinheiro através de uma gestão sofisticada, clara e empoderada.', style: GoogleFonts.inter(fontSize: 18, color: subtitleColor, height: 1.6)),
                                const SizedBox(height: 48),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                                    boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10))],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: AspectRatio(
                                    aspectRatio: 4/3,
                                    child: Image.network(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCCHRuVvI6vAIGwqrrh4U3_gRyYb9vLbcMEv9VzFAnHqMri64mG1pWqv8KR2cXfKAY04yt1pUtsCCnjUVmxpQO9AMcsPqpWWX_xWCdesQ94EYFfiCZ1elM0naADJSKO5vb56ulaGG2qTdecscFNlsEtu50_pgmfTnhIjKtgCvFOgjnMUZM-EAzcOzGvqaGr1zgY-y6X03qFyBuWegATxZGZEimWSC5XWIpen6AMYvvmkJlK9bMSRDV5kJkIWX4ArM1iM2CqB3LFCyFL',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isDesktop) const Spacer(flex: 1),
                        
                        // Right Side: Form
                        Expanded(
                          flex: isDesktop ? 5 : 0,
                          child: Container(
                            padding: EdgeInsets.all(isDesktop ? 48 : 32),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                              children: [
                                if (!isDesktop)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.rocket_launch, color: colorScheme.primary, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Josi Finanças', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                                    ],
                                  ),
                                if (!isDesktop) const SizedBox(height: 32),
                                Text('Bem-vinda de volta', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                                const SizedBox(height: 8),
                                Text('Acesse sua conta para continuar sua jornada de stewardship financeira.', style: GoogleFonts.inter(fontSize: 16, color: subtitleColor), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
                                const SizedBox(height: 40),
                                
                                _buildInput(label: 'E-mail', icon: Icons.mail_outline_rounded, hint: 'exemplo@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress, isDark: isDark, colorScheme: colorScheme),
                                const SizedBox(height: 24),
                                _buildInput(
                                  label: 'Senha',
                                  icon: Icons.lock_outline_rounded,
                                  hint: '••••••••',
                                  controller: _passwordController,
                                  obscure: _obscurePassword,
                                  isDark: isDark,
                                  colorScheme: colorScheme,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: subtitleColor),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  labelExtra: TextButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                    },
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                    child: Text('Esqueci minha senha', style: GoogleFonts.inter(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Lembrar de mim', style: GoogleFonts.inter(fontSize: 14, color: subtitleColor)),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('Entrar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _authenticateWithBiometrics,
                                    icon: Icon(Icons.fingerprint_rounded, color: textColor, size: 24),
                                    label: Text('Entrar com Biometria', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                const SizedBox(height: 24),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Não tem uma conta?', style: GoogleFonts.inter(fontSize: 14, color: subtitleColor)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                      child: Text('Criar conta', style: GoogleFonts.inter(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Text('© 2026 Josi Finanças. Todos os direitos reservados.', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, required String hint, required TextEditingController controller, bool obscure = false, Widget? suffixIcon, Widget? labelExtra, TextInputType? keyboardType, required bool isDark, required ColorScheme colorScheme}) {
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1);
    final filledColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
    final labelColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
            if (labelExtra != null) labelExtra,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: filledColor,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
