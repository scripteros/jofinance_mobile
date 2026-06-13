import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/theme_provider.dart';

class RelatoriosTab extends StatelessWidget {
  final List<Transaction> transactions;

  const RelatoriosTab({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;
    
    // Calcular despesas por categoria
    final expenses = transactions.where((t) {
      final typeStr = t.type?.toLowerCase() ?? '';
      return typeStr != 'income' && typeStr != 'receita' && typeStr != 'entrada';
    }).toList();

    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpenses = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

    final List<Color> palette = [
      _primary,
      _primary.withValues(alpha: 0.8),
      _primary.withValues(alpha: 0.6),
      _primary.withValues(alpha: 0.4),
      Colors.grey.shade400,
      Colors.grey.shade300,
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text('Entenda para onde vai o seu dinheiro e tome melhores decisões.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 15)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distribuição de Gastos', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              
              if (sortedCategories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nenhum gasto registrado.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else ...[
                // Gráfico Principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                startDegreeOffset: -90,
                                sections: sortedCategories.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cat = entry.value;
                                  final color = palette[idx % palette.length];
                                  final percentage = (cat.value / totalExpenses) * 100;
                                  
                                  return PieChartSectionData(
                                    color: color,
                                    value: cat.value,
                                    title: percentage >= 5 ? '${percentage.toInt()}%' : '',
                                    radius: percentage >= 5 ? 30 : 25,
                                    titleStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                                }).toList(),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                  Text('R\$ ${totalExpenses.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Legenda detalhada
                      ...sortedCategories.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;
                        final color = palette[idx % palette.length];
                        final percentage = (cat.value / totalExpenses) * 100;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(cat.key, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                              ),
                              Text('R\$ ${cat.value.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 45,
                                child: Text('${percentage.toStringAsFixed(1)}%', textAlign: TextAlign.right, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}
