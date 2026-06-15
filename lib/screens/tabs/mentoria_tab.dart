import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class MentoriaTab extends StatefulWidget {
  final VoidCallback? onRefresh;
  const MentoriaTab({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<MentoriaTab> createState() => MentoriaTabState();
}

class MentoriaTabState extends State<MentoriaTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  // Audio
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isSending = false;   // true enquanto aguarda resposta da API
  bool _isLoadingHistory = true;  // true enquanto carrega histórico inicial
  bool _isAudioLoading = false;
  String? _playingId;

  List<Map<String, dynamic>> _messages = [];
  final Set<String> _selectedMessages = {};
  bool get _isSelectionMode => _selectedMessages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadHistory() async {
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _apiService.getChatHistory();
      final List<Map<String, dynamic>> loaded = [];
      for (var h in history) {
        String content = h['content']?.toString() ?? '';
        
        // Ignorar mensagens de sistema/insight
        if (content.contains('Gere um insight curto') || 
            content.contains('Aja como Josi, minha mentora financeira') ||
            content.contains('Seu padrão é explodir tudo de uma vez')) {
          continue;
        }

        content = content.replaceAll(RegExp(r'\n\n\[Regra do Sistema:.*?\]', dotAll: true), '');
        loaded.insert(0, {
          'id': h['id'].toString(),
          'isUser': h['role'] == 'user',
          'text': content,
          'time': h['created_at'] != null 
              ? DateTime.parse(h['created_at']).toLocal().toString().substring(11, 16)
              : '',
          'historyId': h['id'],
        });
      }
      setState(() => _messages = loaded);
    } catch (e) {
      print('Erro ao carregar historico: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'isUser': true,
      'text': text,
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    };

    setState(() {
      _messages.insert(0, userMsg);
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {

      final response = await _apiService.sendChatMessage(text);
      final aiResponseText = response['response'] ?? 'Não entendi.';

      setState(() {
        _messages.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'isUser': false,
          'text': aiResponseText,
          'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        });
      });
      _scrollToBottom();
      
      if (response['action'] != null) {
        widget.onRefresh?.call();
      }
    } catch (e) {
      setState(() {
        _messages.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'isUser': false,
          'text': 'Ocorreu um erro. Tente novamente.',
          'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        });
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (_isRecording) {
          final path = await _audioRecorder.stop();
          setState(() {
            _isRecording = false;
            _isAudioLoading = true;
          });
          
          if (path != null) {
            try {
              final transcribed = await _apiService.transcribeAudio(path);
              if (transcribed.isNotEmpty) {
                await _sendMessage(textOverride: transcribed);
              }
            } catch (e) {
              print('Erro ao transcrever: $e');
            }
          }
          setState(() => _isAudioLoading = false);
        } else {
          String? path;
          try {
            final dir = await getTemporaryDirectory();
            path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          } catch(e) {
            path = '';
          }
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      print('Erro no microfone: $e');
    }
  }

  Future<void> _playTTS(String text, String msgId) async {
    if (_playingId == msgId) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
      return;
    }
    
    setState(() => _playingId = msgId);
    try {
      final bytes = await _apiService.getTTS(text);
      await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
    } catch (e) {
      print('Erro no TTS: $e');
      setState(() => _playingId = null);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessages.contains(id)) {
        _selectedMessages.remove(id);
      } else {
        _selectedMessages.add(id);
      }
    });
  }

  void _deleteSelectedMessages() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Mensagens?'),
        content: Text('Deseja apagar as ${_selectedMessages.length} mensagens selecionadas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final idsToDelete = _selectedMessages.toList();
              final historyIdsToDelete = _messages
                  .where((m) => idsToDelete.contains(m['id']) && m['historyId'] != null)
                  .map((m) => m['historyId'] as int)
                  .toList();

              setState(() {
                _messages.removeWhere((m) => idsToDelete.contains(m['id']));
                _selectedMessages.clear();
              });

              if (historyIdsToDelete.isNotEmpty) {
                try {
                  await _apiService.deleteMessages(historyIdsToDelete);
                } catch (_) {}
              }
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Histórico?'),
        content: const Text('Deseja realmente apagar todo o histórico desta conversa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final allHistoryIds = _messages.map((m) => m['historyId'] as int?).whereType<int>().toList();
              setState(() {
                _messages.clear();
                _selectedMessages.clear();
              });
              if (allHistoryIds.isNotEmpty) {
                try {
                  await _apiService.deleteMessages(allHistoryIds);
                } catch (_) {}
              }
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    const _bgWallpaper = Color(0xFFEBE5DE);
    const _userBubble = Color(0xFFD1FAE5);
    const _joBubble = Colors.white;

    return Scaffold(
      backgroundColor: _bgWallpaper,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 1,
        titleSpacing: _isSelectionMode ? null : 0,
        leading: _isSelectionMode 
            ? IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedMessages.clear()))
            : const SizedBox.shrink(),
        leadingWidth: _isSelectionMode ? 56 : 16,
        title: _isSelectionMode 
            ? Text('${_selectedMessages.length} selecionadas', style: const TextStyle(color: Colors.white, fontSize: 18))
            : Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: _primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Josi (Mentora)', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_isAudioLoading ? 'transcrevendo áudio...' : (_isSending ? 'digitando...' : 'online'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _deleteSelectedMessages)
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'clear') _clearHistory();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'clear', child: Text('Limpar Histórico')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFF1A1A2E),
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg['isUser'] as bool;
                            final isSelected = _selectedMessages.contains(msg['id']);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: () => _toggleSelection(msg['id']),
                              onTap: () {
                                if (_isSelectionMode) _toggleSelection(msg['id']);
                              },
                              child: Container(
                                color: isSelected ? _primary.withValues(alpha: 0.2) : Colors.transparent,
                                padding: const EdgeInsets.only(bottom: 12, top: 4, left: 16, right: 16),
                                child: Row(
                                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isUser) ...[
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: _primary,
                                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isUser ? _userBubble : _joBubble,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(20),
                                            topRight: const Radius.circular(20),
                                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                                            bottomRight: Radius.circular(isUser ? 4 : 20),
                                          ),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            if (isUser)
                                              Text(msg['text']?.toString() ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black87, height: 1.4))
                                            else
                                              RichText(
                                                text: TextSpan(
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black87, height: 1.4),
                                                  children: _colorizeText(msg['text']?.toString() ?? ''),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isUser) ...[
                                                  GestureDetector(
                                                    onTap: () => _playTTS(msg['text']?.toString() ?? '', msg['id']),
                                                    child: Icon(
                                                      _playingId == msg['id'] ? Icons.volume_up : Icons.volume_up_outlined,
                                                      size: 16,
                                                      color: _playingId == msg['id'] ? _primary : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Text(msg['time']?.toString() ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey.shade500)),
                                                if (isUser) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.done_all, size: 14, color: Colors.blue.shade400),
                                                ]
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isUser) const SizedBox(width: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          
          // Indicador de "digitando..." perto do input
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Text('Josi está digitando...', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          if (_isAudioLoading)
             const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),

          Container(
            padding: const EdgeInsets.all(8.0).copyWith(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: 5,
                            minLines: 1,
                            onChanged: (v) => setState((){}),
                            decoration: InputDecoration(
                              hintText: 'Mensagem...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _isRecording ? Colors.red : _primary,
                  child: IconButton(
                    icon: Icon(_isRecording ? Icons.stop : (_controller.text.trim().isEmpty ? Icons.mic : Icons.send), color: Colors.white, size: 24),
                    onPressed: () {
                      if (_isRecording || _controller.text.trim().isEmpty) {
                        _toggleRecording();
                      } else {
                        _sendMessage();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
