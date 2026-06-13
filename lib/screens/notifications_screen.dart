import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final history = await _apiService.getChatHistory();
      if (mounted) {
        setState(() {
          // Filtrar apenas as mensagens da IA (is_user == false)
          _notifications = history.where((msg) => msg['is_user'] == false).toList();
          // Inverter a lista para que a mais recente fique no topo, se o backend retornar em ordem cronológica
          _notifications = _notifications.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar notificações: $e')));
      }
    }
  }

  List<TextSpan> _colorizeText(String text) {
    final regex = RegExp(r'(https?:\/\/[^\s]+|R\$\s*-?[\d.]+(?:[.,]\d+)?|negativo|positivo|gasto|lucro|aumento|reduziu)', caseSensitive: false);
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedStr = match.group(0)!;
      final lowerStr = matchedStr.toLowerCase();

      if (lowerStr.startsWith('http')) {
        spans.add(TextSpan(
          text: matchedStr,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()..onTap = () async {
            final uri = Uri.parse(matchedStr);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ));
      } else {
        Color color = Colors.black87;
        if (lowerStr.contains('r\$')) {
          final val = double.tryParse(lowerStr.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
          if (lowerStr.contains('-') || val < 0) {
            color = Colors.red.shade600;
          } else {
            color = Colors.green.shade700;
          }
        } else if (['negativo', 'gasto', 'reduziu'].contains(lowerStr)) {
          color = Colors.red.shade600;
        } else if (['positivo', 'lucro', 'aumento'].contains(lowerStr)) {
          color = Colors.green.shade700;
        }
        spans.add(TextSpan(text: matchedStr, style: TextStyle(color: color, fontWeight: FontWeight.bold)));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Notificações', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('Nenhuma notificação da Josi no momento.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final msg = notif['message'] ?? notif['text'] ?? '';
                      // Pegar apenas a data se estiver disponível
                      final dateRaw = notif['created_at'] ?? notif['timestamp'] ?? '';
                      String displayDate = '';
                      if (dateRaw.isNotEmpty) {
                        try {
                          final d = DateTime.parse(dateRaw);
                          displayDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                            border: Border.all(color: Colors.grey.shade100)
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.auto_awesome, color: _primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dica da Josi', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87, height: 1.4),
                                        children: _colorizeText(msg),
                                      ),
                                    ),
                                    if (displayDate.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(displayDate, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
