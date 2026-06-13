import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  static const _primary = Color(0xFF8B4757);
  static const _surface = Color(0xFFFCF9F4);
  static const _onSurface = Color(0xFF1C1C19);
  static const _onSurfaceVariant = Color(0xFF524345);
  static const _outlineVariant = Color(0xFFD7C1C4);
  static const _outline = Color(0xFF857375);
  static const _onPrimary = Colors.white;
  static const _surfaceContainerLowest = Colors.white;

  void _sendRecoveryLink() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    // Simula uma chamada de API
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background blob
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(width: 500, height: 500, decoration: const BoxDecoration(color: Color(0x0D8B4757), shape: BoxShape.circle)),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10))],
                  ),
                  child: _isSent ? _buildSuccessState() : _buildFormState(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recuperar Senha', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: _onSurface)),
        const SizedBox(height: 8),
        Text('Digite seu e-mail abaixo e enviaremos um link para você redefinir sua senha.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 40),
        
        Text('E-mail', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _onSurface),
          decoration: InputDecoration(
            hintText: 'exemplo@email.com',
            hintStyle: GoogleFonts.plusJakartaSans(color: _outlineVariant),
            prefixIcon: const Icon(Icons.mail, color: _outline, size: 24),
            filled: true,
            fillColor: _surface,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primary, width: 2)),
          ),
        ),
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendRecoveryLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Enviar Link', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 24),
        Text('E-mail Enviado!', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: _onSurface)),
        const SizedBox(height: 16),
        Text('Se houver uma conta associada a este e-mail, você receberá um link de recuperação em breve. Verifique sua caixa de entrada e spam.', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text('Voltar para o Login', style: GoogleFonts.plusJakartaSans(color: _primary, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
