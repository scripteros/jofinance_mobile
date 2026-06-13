import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart'; // Import AuthWrapper
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  void _register() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar os termos de uso e política de privacidade.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _phoneController.text.trim(),
    );
    
    if (!mounted) return;

    if (!success && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!)),
      );
    } else if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
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
                                Text('Junte-se a milhares de pessoas que transformaram suas vidas financeiras.', style: GoogleFonts.inter(fontSize: 18, color: subtitleColor, height: 1.6)),
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
                                Text('Criar conta', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                                const SizedBox(height: 8),
                                Text('Preencha os dados abaixo para começar.', style: GoogleFonts.inter(fontSize: 16, color: subtitleColor), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
                                const SizedBox(height: 40),
                                
                                _buildInput(label: 'Nome Completo', icon: Icons.person_outline, hint: 'Ex: Maria Silva', controller: _nameController, isDark: isDark, colorScheme: colorScheme),
                                const SizedBox(height: 16),
                                _buildInput(label: 'E-mail', icon: Icons.mail_outline_rounded, hint: 'exemplo@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress, isDark: isDark, colorScheme: colorScheme),
                                const SizedBox(height: 16),
                                _buildInput(label: 'Celular / WhatsApp', icon: Icons.phone_iphone_rounded, hint: '(00) 00000-0000', controller: _phoneController, keyboardType: TextInputType.phone, isDark: isDark, colorScheme: colorScheme),
                                const SizedBox(height: 16),
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
                                ),
                                const SizedBox(height: 24),
                                
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _termsAccepted,
                                        onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                                        activeColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Eu aceito os Termos de Uso e a Política de Privacidade.', style: GoogleFonts.inter(fontSize: 14, color: subtitleColor)),
                                    ),
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
                                      onPressed: isLoading ? null : _register,
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
                                                Text('Criar conta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                const SizedBox(height: 24),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Já tem uma conta?', style: GoogleFonts.inter(fontSize: 14, color: subtitleColor)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                      child: Text('Fazer Login', style: GoogleFonts.inter(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.bold)),
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

  Widget _buildInput({required String label, required IconData icon, required String hint, required TextEditingController controller, bool obscure = false, Widget? suffixIcon, TextInputType? keyboardType, required bool isDark, required ColorScheme colorScheme}) {
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1);
    final filledColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
    final labelColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor)),
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
