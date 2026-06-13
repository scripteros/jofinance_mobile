import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ExtratoScreen extends StatefulWidget {
  const ExtratoScreen({Key? key}) : super(key: key);

  @override
  State<ExtratoScreen> createState() => _ExtratoScreenState();
}

class _ExtratoScreenState extends State<ExtratoScreen> {
  final ApiService _apiService = ApiService();
  List<Transaction> _allTransactions = [];
  bool _isLoading = true;

  String _filterType = 'Todas'; // 'Todas', 'Receitas', 'Despesas'
  String _filterPeriod = 'Últimos 30 dias'; // 'Todos', 'Mês Atual', 'Últimos 7 dias', 'Últimos 30 dias'

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _apiService.getTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar transações: $e')));
      }
    }
  }

  List<Transaction> get _filteredTransactions {
    List<Transaction> filtered = List.from(_allTransactions);

    // Filtro de Tipo
    if (_filterType == 'Receitas') {
      filtered.retainWhere((t) {
        final typeStr = t.type?.toLowerCase() ?? '';
        return typeStr == 'income' || typeStr == 'receita' || typeStr == 'entrada';
      });
    } else if (_filterType == 'Despesas') {
      filtered.retainWhere((t) {
        final typeStr = t.type?.toLowerCase() ?? '';
        return typeStr != 'income' && typeStr != 'receita' && typeStr != 'entrada';
      });
    }

    // Filtro de Período
    final now = DateTime.now();
    if (_filterPeriod == 'Mês Atual') {
      filtered.retainWhere((t) {
        try {
          final d = DateTime.parse(t.date);
          return d.month == now.month && d.year == now.year;
        } catch (_) { return false; }
      });
    } else if (_filterPeriod == 'Últimos 7 dias') {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      filtered.retainWhere((t) {
        try {
          return DateTime.parse(t.date).isAfter(sevenDaysAgo);
        } catch (_) { return false; }
      });
    } else if (_filterPeriod == 'Últimos 30 dias') {
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      filtered.retainWhere((t) {
        try {
          return DateTime.parse(t.date).isAfter(thirtyDaysAgo);
        } catch (_) { return false; }
      });
    }

    return filtered;
  }

  Widget _buildTransactionItem(Transaction tx) {
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
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (ctx2) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Excluir transação?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                        content: Text('Essa ação não pode ser desfeita.', style: GoogleFonts.plusJakartaSans()),
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
                        _fetchTransactions(); // Refetch
                      } catch (e) {
                        if (mounted) {
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;
    final filteredList = _filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Extrato', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // FILTERS SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter by Type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todas', 'Receitas', 'Despesas'].map((type) {
                      final isSelected = _filterType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(type, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _filterType = type);
                          },
                          selectedColor: _primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: isSelected ? _primary : Colors.grey[600]),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter by Period
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _filterPeriod,
                      icon: Icon(Icons.calendar_month, size: 20, color: _primary),
                      style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
                      items: ['Todos', 'Mês Atual', 'Últimos 7 dias', 'Últimos 30 dias'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _filterPeriod = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // LIST SECTION
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(child: Text('Nenhuma transação encontrada.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _fetchTransactions,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(filteredList[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
