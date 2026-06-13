import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _presetColors = [
    {'name': 'Esmeralda', 'color': const Color(0xFF047857)},
    {'name': 'Verde Floresta', 'color': const Color(0xFF2E7D32)},
    {'name': 'Teal Profundo', 'color': const Color(0xFF00695C)},
    {'name': 'Vinho', 'color': const Color(0xFF8B4757)},
    {'name': 'Cereja', 'color': const Color(0xFFE91E63)},
    {'name': 'Azul Royal', 'color': const Color(0xFF1E3A8A)},
    {'name': 'Ciano', 'color': const Color(0xFF00838F)},
    {'name': 'Índigo', 'color': const Color(0xFF3F51B5)},
    {'name': 'Roxo Escuro', 'color': const Color(0xFF4C1D95)},
    {'name': 'Laranja', 'color': const Color(0xFFF57C00)},
    {'name': 'Âmbar', 'color': const Color(0xFFD97706)},
    {'name': 'Vermelho Fogo', 'color': const Color(0xFFD32F2F)},
    {'name': 'Grafite', 'color': const Color(0xFF455A64)},
    {'name': 'Preto Elegante', 'color': const Color(0xFF1F2937)},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      if (user.name != null) _nameController.text = user.name!;
      _emailController.text = user.email;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    // Simulating API call to save user profile
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configurações salvas com sucesso!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primary = theme.primaryColor;
    final user = context.watch<AuthProvider>().user;

    ImageProvider? avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(_imageFile!);
    } else if (user?.avatarUrl != null) {
      avatarImage = NetworkImage(user!.avatarUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      appBar: AppBar(
        title: Text('Configurações', style: GoogleFonts.playfairDisplay(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background accent
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Card
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: primary.withValues(alpha: 0.1),
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Icon(Icons.person, size: 60, color: primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Perfil Section
                Text('Seu Perfil', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primary, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.person_outline, color: primary),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Theme Section
                Text('Aparência do App', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primary, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paleta de Cores', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text('Selecione a sua cor preferida para personalizar o visual do aplicativo inteiro instantaneamente.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: _presetColors.map((preset) {
                          final color = preset['color'] as Color;
                          final isSelected = primary.value == color.value;
                          return GestureDetector(
                            onTap: () => theme.setPrimaryColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: primary.withValues(alpha: 0.3), width: 4) : null,
                                boxShadow: [
                                  if (isSelected) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                                  else BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ── Reset Data Section ──
                Text('Gerenciar Dados', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade700, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.refresh_rounded, color: Colors.orange.shade700, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Resetar Registros', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('Apaga todas as transações, metas, dívidas e conversas. Sua conta permanece.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmResetData(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text('Resetar Dados', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Delete Account Section ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deletar Conta', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('Remove permanentemente sua conta e todos os dados.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDeleteAccount(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.delete_forever_rounded, size: 20),
                          label: Text('Deletar Conta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: primary.withValues(alpha: 0.4),
                    ),
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Salvar Alterações', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reset Data ──

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Text('Resetar Dados?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Todas as suas transações, metas, dívidas e conversas serão apagadas permanentemente. Sua conta e perfil continuarão ativos.',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sim, Resetar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeReset() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final result = await api.resetUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Dados resetados com sucesso!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceFirst('Exception: ', '')}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Delete Account ──

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Text('Deletar Conta?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Isso é PERMANENTE! Sua conta, transações, metas, conversas e todos os dados serão perdidos para sempre.',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sim, Deletar Tudo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.deleteAccount();
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jo_finance_token');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Scaffold(
            body: Center(child: Text('Conta deletada.')),
          )),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceFirst('Exception: ', '')}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
