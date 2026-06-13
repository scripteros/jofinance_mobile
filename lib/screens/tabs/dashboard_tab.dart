import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../extrato_screen.dart';
import '../investments_screen.dart';
import '../notifications_screen.dart';

class DashboardTab extends StatefulWidget {
  final double balance;
  final List<Transaction> transactions;
  final List<Goal> goals;
  final VoidCallback onRefresh;

  const DashboardTab({
    Key? key,
    required this.balance,
    required this.transactions,
    required this.goals,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ApiService _apiService = ApiService();
  String _insightText = 'Analisando suas finanças...';
  bool _isLoadingInsight = true;
  bool _hideBalance = false;

  List<TextSpan> _colorizeText(String text) {
    final regex = RegExp(r'(R\$\s*-?[\d.]+(?:[.,]\d+)?|negativo|positivo|gasto|lucro|aumento|reduziu)', caseSensitive: false);
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedStr = match.group(0)!;
      Color color = Colors.black87;
      final lowerStr = matchedStr.toLowerCase();

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
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  void initState() {
    super.initState();
    _fetchInsight();
  }

  Future<void> _fetchInsight() async {
    try {
      final prompt = 'Gere um insight curto (1 a 2 frases) sobre finanças. Meu saldo atual é R\$ ${widget.balance}. Aja como Josi, minha mentora financeira. Seja direta e sem saudações.';
      final response = await _apiService.sendChatMessage(prompt, []);
      final insight = response['message'] ?? response['response'] ?? response['text'] ?? 'Mantenha o foco nos seus objetivos financeiros!';
      
      if (mounted) {
        setState(() {
          _insightText = insight;
          _isLoadingInsight = false;
        });
      }

      // Limpar essas mensagens do histórico do backend
      try {
        final history = await _apiService.getChatHistory();
        for (var h in history) {
          String content = h['content']?.toString() ?? '';
          if (content.contains('Gere um insight curto') || content == insight) {
            await _apiService.deleteMessages([h['id']]);
          }
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _insightText = 'Mantenha o controle dos seus gastos e tente guardar um pouco todo mês!';
          _isLoadingInsight = false;
        });
      }
    }
  }

  Future<void> _showAddModal(BuildContext context, bool isIncome) async {
    final TextEditingController _descController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();
    String _selectedCategory = isIncome ? 'Receita' : 'Alimentação';
    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = context.watch<ThemeProvider>();
          final _primary = theme.primaryColor;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(isIncome ? 'Adicionar Receita' : 'Registrar Gasto', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: _primary))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                    const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Valor (R\$)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: (isIncome 
                            ? ['Receita', 'Salário', 'Investimento']
                            : ['Alimentação', 'Transporte', 'Lazer', 'Outros']).map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => _selectedCategory = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncome ? Colors.green.shade600 : _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : () async {
                      if (_descController.text.isEmpty || _amountController.text.isEmpty) return;
                      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
                      if (amount <= 0) return;

                      setModalState(() => _isLoading = true);
                      try {
                        await _apiService.createTransaction(
                          description: _descController.text,
                          amount: amount,
                          category: _selectedCategory,
                          type: isIncome ? 'income' : 'expense',
                        );
                        Navigator.pop(ctx);
                        widget.onRefresh();
                      } catch (e) {
                        setModalState(() => _isLoading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    },
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Salvar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx, BuildContext context, {bool isDeletable = false}) {
    final typeStr = tx.type?.toLowerCase() ?? '';
    final isIncome = typeStr == 'income' || typeStr == 'receita' || typeStr == 'entrada';
    
    IconData txIcon;
    Color txBgColor;
    Color txIconColor;

    if (isIncome) {
      txIcon = Icons.arrow_downward;
      txBgColor = Colors.green.shade50;
      txIconColor = Colors.green.shade600;
    } else {
      final cat = tx.category.toLowerCase();
      txBgColor = Colors.red.shade50;
      txIconColor = Colors.red.shade600;
      
      if (cat.contains('aliment') || cat.contains('lanche') || cat.contains('comida')) {
        txIcon = Icons.restaurant;
      } else if (cat.contains('transporte') || cat.contains('viagem') || cat.contains('viagens')) {
        txIcon = Icons.directions_car;
      } else if (cat.contains('lazer') || cat.contains('divers')) {
        txIcon = Icons.movie;
      } else if (cat.contains('compra') || cat.contains('mercado') || cat.contains('roupa')) {
        txIcon = Icons.shopping_bag;
      } else if (cat.contains('saúde') || cat.contains('farm')) {
        txIcon = Icons.local_pharmacy;
      } else {
        txIcon = Icons.receipt_long;
      }
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: txBgColor, shape: BoxShape.circle),
              child: Icon(txIcon, color: txIconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Builder(builder: (_) {
                    final dateObj = DateTime.tryParse(tx.date)?.toLocal();
                    final formattedDate = dateObj != null ? DateFormat('dd/MM/yyyy HH:mm').format(dateObj) : tx.date;
                    return Text('${tx.category} • $formattedDate', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]));
                  }),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} R\$ ${tx.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (isDeletable) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Excluir transação?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                          content: Text('Essa ação não pode ser desfeita e afetará o seu saldo.', style: GoogleFonts.plusJakartaSans()),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('Cancelar')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                              onPressed: () => Navigator.pop(ctx2, true), 
                              child: const Text('Excluir', style: TextStyle(color: Colors.white))
                            ),
                          ],
                        )
                      );
                      if (confirm == true) {
                        try {
                          await _apiService.deleteTransaction(tx.id);
                          widget.onRefresh();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    )
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final _primary = context.watch<ThemeProvider>().primaryColor;
    const _onSurfaceVariant = Color(0xFF524345);

    Color _balanceColor = Colors.amber.shade600;
    IconData _balanceIcon = Icons.horizontal_rule;

    final totalIncome = widget.transactions.where((t) {
      final typeStr = t.type?.toLowerCase() ?? '';
      return typeStr == 'income' || typeStr == 'receita' || typeStr == 'entrada';
    }).fold(0.0, (s, t) => s + t.amount);

    final totalExpenses = widget.transactions.where((t) {
      final typeStr = t.type?.toLowerCase() ?? '';
      return typeStr != 'income' && typeStr != 'receita' && typeStr != 'entrada';
    }).fold(0.0, (s, t) => s + t.amount);
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    double changeLast30Days = 0;
    for (var tx in widget.transactions) {
      try {
        DateTime txDate = DateTime.parse(tx.date);
        if (txDate.isAfter(thirtyDaysAgo)) {
          changeLast30Days += (tx.type == 'income') ? tx.amount : -tx.amount;
        }
      } catch (_) {
        changeLast30Days += (tx.type == 'income') ? tx.amount : -tx.amount;
      }
    }
    
    double balance30DaysAgo = widget.balance - changeLast30Days;
    double percentage = 0;
    if (balance30DaysAgo != 0) {
      percentage = (changeLast30Days / balance30DaysAgo.abs()) * 100;
    } else {
      percentage = changeLast30Days > 0 ? 100 : (changeLast30Days < 0 ? -100 : 0);
    }

    String _balanceText = '0.00% nos últimos 30 dias';
    if (percentage > 0) {
      _balanceColor = Colors.green.shade600;
      _balanceText = '+${percentage.toStringAsFixed(1).replaceAll('.', ',')}% nos últimos 30 dias';
      _balanceIcon = Icons.trending_up;
    } else if (percentage < 0) {
      _balanceColor = Colors.red.shade600;
      _balanceText = '${percentage.toStringAsFixed(1).replaceAll('.', ',')}% nos últimos 30 dias';
      _balanceIcon = Icons.trending_down;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 8),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Conta', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hideBalance ? 'R\$ •••••' : 'R\$ ${widget.balance.toStringAsFixed(2).replaceAll('.', ',')}', 
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _hideBalance = !_hideBalance;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(_hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_balanceIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(_balanceText, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickAction(Icons.arrow_downward, 'Receber', () => _showAddModal(context, true), _primary),
                _buildQuickAction(Icons.arrow_upward, 'Pagar', () => _showAddModal(context, false), _primary),
                _buildQuickAction(Icons.list_alt, 'Extrato', () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ExtratoScreen())).then((_) => widget.onRefresh());
                }, _primary),
                _buildQuickAction(Icons.pie_chart_outline, 'Carteira', () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const InvestmentsScreen()));
                }, _primary),
              ],
            ),
          ),

          Container(height: 8, color: Colors.grey.shade200),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumo do Mês', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_circle_down, color: Colors.green.shade600, size: 24),
                            const SizedBox(height: 12),
                            Text('Receitas', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('R\$ ${totalIncome.toStringAsFixed(2).replaceAll('.', ',')}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_circle_up, color: Colors.red.shade500, size: 24),
                            const SizedBox(height: 12),
                            Text('Despesas', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('R\$ ${totalExpenses.toStringAsFixed(2).replaceAll('.', ',')}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(height: 8, color: Colors.grey.shade200),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isLoadingInsight
                        ? const Align(alignment: Alignment.centerLeft, child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[800], height: 1.5, fontStyle: FontStyle.italic),
                              children: _colorizeText('“$_insightText”'),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome, color: _primary, size: 20),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Movimentações', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: _onSurfaceVariant)),
                if (widget.transactions.length > 5)
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ExtratoScreen())).then((_) => widget.onRefresh());
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Ver mais', style: GoogleFonts.plusJakartaSans(color: _primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (widget.transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Nenhuma transação encontrada.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
              ),
            )
          else
            ...widget.transactions.take(5).map((tx) {
              return _buildTransactionItem(tx, context);
            }).toList(),
            
          Container(height: 8, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 16)),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Metas Ativas', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: _onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          if (widget.goals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Nenhuma meta ativa.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: widget.goals.length,
                itemBuilder: (ctx, idx) {
                  final goal = widget.goals[idx];
                  final percent = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text('R\$ ${goal.currentAmount.toStringAsFixed(2)} / R\$ ${goal.targetAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                        const Spacer(),
                        LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey.shade200,
                          color: _primary,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('${(percent * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _primary)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 80), // Espaço pro Bottom Navigation e FAB flutuante
        ],
      ),
    );
  }
}
