import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../widgets/goal_card.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';

class MetasTab extends StatelessWidget {
  final List<Goal> goals;
  final VoidCallback onRefresh;

  const MetasTab({Key? key, required this.goals, required this.onRefresh}) : super(key: key);

  void _showAddGoalModal(BuildContext context) {
    final _titleController = TextEditingController();
    final _targetController = TextEditingController();
    final _currentController = TextEditingController();
    final ApiService _apiService = ApiService();
    bool _isLoading = false;

    showDialog(
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
                        Flexible(child: Text('Nova Meta', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: _primary))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                    const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título da Meta',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor Objetivo (R\$)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _currentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor Já Acumulado (R\$) (Opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final title = _titleController.text.trim();
                            final targetStr = _targetController.text.replaceAll(',', '.');
                            final currentStr = _currentController.text.replaceAll(',', '.');

                            if (title.isEmpty || targetStr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha título e valor objetivo')));
                              return;
                            }

                            final target = double.tryParse(targetStr);
                            final current = currentStr.isEmpty ? 0.0 : double.tryParse(currentStr);

                            if (target == null || current == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valores numéricos inválidos')));
                              return;
                            }

                            setModalState(() => _isLoading = true);
                            try {
                              await _apiService.createGoal(
                                name: title,
                                targetAmount: target,
                                category: catController.text,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                onRefresh();
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                                setModalState(() => _isLoading = false);
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Salvar Meta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;
    
    final double totalMetas = goals.fold(0.0, (sum, item) => sum + item.targetAmount);
    final double totalAcumulado = goals.fold(0.0, (sum, item) => sum + item.currentAmount);
    final double percentageGlobal = totalMetas > 0 ? (totalAcumulado / totalMetas) * 100 : 0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minhas Metas', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Acompanhe a realização dos seus sonhos.', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.8), fontSize: 15)),
              const SizedBox(height: 32),
              
              // Global Progress
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progresso Global', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('${percentageGlobal.toInt()}%', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (percentageGlobal / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('R\$ ${totalAcumulado.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('R\$ ${totalMetas.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Goals List
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Seus Objetivos', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  TextButton.icon(
                    onPressed: () => _showAddGoalModal(context),
                    icon: Icon(Icons.add, color: _primary, size: 20),
                    label: Text('Nova Meta', style: GoogleFonts.plusJakartaSans(color: _primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (goals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nenhuma meta cadastrada.', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                ...goals.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GoalCard(
                    title: g.name,
                    percentage: g.percentage,
                    currentAmountText: 'R\$ ${g.currentAmount.toStringAsFixed(2)}',
                    targetAmountText: 'R\$ ${g.targetAmount.toStringAsFixed(2)}',
                    detailText: g.percentage >= 100 ? 'Concluído!' : 'Faltam R\$ ${(g.targetAmount - g.currentAmount).toStringAsFixed(2)}',
                  ),
                )),
                
              const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ],
    );
  }
}
