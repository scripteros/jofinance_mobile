import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../main.dart'; // Import AuthWrapper

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  static const _primary = Color(0xFF8B4757);
  static const _surface = Color(0xFFFCF9F4);
  static const _onSurface = Color(0xFF1C1C19);
  static const _onSurfaceVariant = Color(0xFF524345);
  static const _outlineVariant = Color(0xFFD7C1C4);
  static const _onPrimary = Colors.white;

  // Step 1: Perfil
  String? _selectedProfile;
  final List<Map<String, dynamic>> _perfis = [
    {'value': 'conservador', 'label': 'Conservador', 'icon': Icons.security, 'desc': 'Prefiro segurança e baixo risco'},
    {'value': 'moderado', 'label': 'Moderado', 'icon': Icons.balance, 'desc': 'Busco equilíbrio entre risco e retorno'},
    {'value': 'arrojado', 'label': 'Arrojado', 'icon': Icons.rocket_launch, 'desc': 'Aceito riscos para maiores ganhos'},
  ];

  // Step 2: Dividas
  bool _hasDebts = false;
  final List<Map<String, dynamic>> _debts = [];
  final _debtNameCtrl = TextEditingController();
  final _debtAmountCtrl = TextEditingController();

  // Step 3: Metas
  final List<Map<String, dynamic>> _goals = [];
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();

  // Step 4: Resumo
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();

  void _nextStep() {
    if (_currentStep == 0 && _selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um perfil.')));
      return;
    }
    if (_currentStep == 3) {
      _submitOnboarding();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.submitOnboarding({
        'profile': _selectedProfile,
        'debts': _debts,
        'goals': _goals,
        'monthly_income': double.tryParse(_incomeCtrl.text) ?? 0,
        'monthly_expenses': double.tryParse(_expenseCtrl.text) ?? 0,
      });
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 
          ? IconButton(icon: const Icon(Icons.arrow_back, color: _primary), onPressed: _prevStep)
          : null,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progresso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? _primary : _outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            // Footer (Botão Próximo)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep == 3 ? 'Finalizar' : 'Avançar', style: GoogleFonts.plusJakartaSans(color: _onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qual é o seu perfil de investidor?', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 8),
          Text('Isota ajuda a Jo a personalizar suas recomendações.', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _onSurfaceVariant)),
          const SizedBox(height: 32),
          ..._perfis.map((p) => _buildProfileOption(p['value'], p['label'], p['icon'], p['desc'])),
        ],
      ),
    );
  }

  Widget _buildProfileOption(String value, String label, IconData icon, String desc) {
    final isSelected = _selectedProfile == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedProfile = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? _primary : _outlineVariant.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? _primary : _surface, shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? Colors.white : _primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: _primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Você possui dívidas ativas?', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 8),
          Text('Não se preocupe, ajudaremos você a quitá-las mais rápido.', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _onSurfaceVariant)),
          const SizedBox(height: 32),
          SwitchListTile(
            title: Text('Tenho empréstimos ou financiamentos', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            activeColor: _primary,
            value: _hasDebts,
            onChanged: (v) => setState(() => _hasDebts = v),
          ),
          if (_hasDebts) ...[
            const SizedBox(height: 24),
            Text('Adicionar dívida:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _debtNameCtrl, decoration: const InputDecoration(labelText: 'Nome da dívida (ex: Financiamento Carro)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _debtAmountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor Total (R\$)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (_debtNameCtrl.text.isNotEmpty && _debtAmountCtrl.text.isNotEmpty) {
                  setState(() {
                    _debts.add({'name': _debtNameCtrl.text, 'amount': double.parse(_debtAmountCtrl.text)});
                    _debtNameCtrl.clear();
                    _debtAmountCtrl.clear();
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar à lista'),
            ),
            const SizedBox(height: 24),
            ..._debts.map((d) => ListTile(
              title: Text(d['name']),
              subtitle: Text('R\$ ${d['amount']}'),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _debts.remove(d))),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quais são suas metas?', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 8),
          Text('Defina objetivos para focar seus investimentos.', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _onSurfaceVariant)),
          const SizedBox(height: 32),
          TextField(controller: _goalNameCtrl, decoration: const InputDecoration(labelText: 'Nome da Meta (ex: Viagem Europa)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _goalAmountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor Alvo (R\$)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              if (_goalNameCtrl.text.isNotEmpty && _goalAmountCtrl.text.isNotEmpty) {
                setState(() {
                  _goals.add({'title': _goalNameCtrl.text, 'target': double.parse(_goalAmountCtrl.text)});
                  _goalNameCtrl.clear();
                  _goalAmountCtrl.clear();
                });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Meta'),
          ),
          const SizedBox(height: 24),
          ..._goals.map((g) => ListTile(
            title: Text(g['title']),
            subtitle: Text('R\$ ${g['target']}'),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _goals.remove(g))),
          )),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Última etapa: Resumo financeiro', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 8),
          Text('Esses dados formam a base do seu fluxo de caixa mensal.', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _onSurfaceVariant)),
          const SizedBox(height: 32),
          TextField(controller: _incomeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Renda Mensal Média (R\$)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _expenseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gastos Essenciais Mensais (R\$)', prefixIcon: Icon(Icons.money_off), border: OutlineInputBorder())),
        ],
      ),
    );
  }
}
