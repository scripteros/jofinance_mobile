import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
      final data = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notificações: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    final notif = _notifications[index];
    final title = notif['title']?.toString() ?? notif['message']?.toString() ?? 'Notificação';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D5E4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Excluir notificação',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir "$title"?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Excluir', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteNotification(id);
      if (mounted) {
        setState(() {
          _notifications.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificação excluída'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(d);

      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
      if (diff.inHours < 24) return '${diff.inHours} h atrás';
      if (diff.inDays == 1) return 'Ontem';
      if (diff.inDays < 7) return '${diff.inDays} dias atrás';

      return DateFormat('dd/MM/yyyy • HH:mm').format(d);
    } catch (_) {
      return raw ?? '';
    }
  }

  Color _categoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'goal':
      case 'meta':
        return const Color(0xFF10B981);
      case 'transaction':
      case 'transação':
        return const Color(0xFF3B82F6);
      case 'tip':
      case 'dica':
        return const Color(0xFFF59E0B);
      case 'alert':
      case 'alerta':
        return const Color(0xFFEF4444);
      case 'system':
      case 'sistema':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF047857);
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'goal':
      case 'meta':
        return Icons.flag_rounded;
      case 'transaction':
      case 'transação':
        return Icons.receipt_long_rounded;
      case 'tip':
      case 'dica':
        return Icons.lightbulb_rounded;
      case 'alert':
      case 'alerta':
        return Icons.warning_amber_rounded;
      case 'system':
      case 'sistema':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primary = theme.primaryColor;
    final bgDark = const Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Notificações',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.1), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final id = notif['id'] is int
                          ? notif['id'] as int
                          : int.tryParse(notif['id']?.toString() ?? '0') ?? 0;
                      final title = notif['title']?.toString() ?? '';
                      final body = notif['body']?.toString() ?? notif['message']?.toString() ?? notif['text']?.toString() ?? '';
                      final dateRaw = notif['created_at']?.toString() ?? notif['date']?.toString() ?? notif['timestamp']?.toString() ?? '';
                      final category = notif['category']?.toString() ?? notif['type']?.toString() ?? '';
                      final hasLink = notif['link_url'] != null && notif['link_url'].toString().isNotEmpty;
                      final hasImage = notif['image_url'] != null && notif['image_url'].toString().isNotEmpty;
                      final isRead = notif['is_read'] == true || notif['read'] == true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key('notif_$id'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF0D5E4B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  'Excluir notificação',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                content: Text(
                                  'Tem certeza que deseja excluir esta notificação?',
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Excluir', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            _deleteNotification(id, index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? const Color(0xFF1A1A2E).withValues(alpha: 0.6)
                                  : const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFF047857).withValues(alpha: 0.3),
                                width: isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ícone da categoria
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _categoryColor(category).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _categoryIcon(category),
                                    color: _categoryColor(category),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Conteúdo
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Título + indicadores
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title.isNotEmpty ? title : 'Notificação',
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                color: isRead ? Colors.white60 : Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasLink || hasImage) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              hasLink ? Icons.link_rounded : Icons.image_rounded,
                                              size: 14,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ],
                                          if (!isRead) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Corpo (truncado)
                                      if (body.isNotEmpty)
                                        Text(
                                          body,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.white54,
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                      // Data
                                      Text(
                                        _formatDate(dateRaw),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Botão lixeira
                                GestureDetector(
                                  onTap: () => _deleteNotification(id, index),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF047857).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 40,
                color: Color(0xFF047857),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma notificação ainda',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando você receber alertas financeiros, dicas ou atualizações, eles aparecerão aqui.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white38,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
