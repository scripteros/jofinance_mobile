import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Carteira de Investimentos', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pie_chart_outline, size: 64, color: _primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Em breve!',
                style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Text(
                'Sua nova carteira de investimentos inteligente está sendo preparada pela Josi. Fique de olho nas próximas atualizações!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Voltar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
