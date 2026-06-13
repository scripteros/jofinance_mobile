import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'landing_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Tabs
import 'tabs/dashboard_tab.dart';
import 'tabs/mentoria_tab.dart';
import 'tabs/metas_tab.dart';
import 'tabs/relatorios_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<MentoriaTabState> _mentoriaKey = GlobalKey<MentoriaTabState>();

  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  double _balance = 0.0;
  List<Transaction> _transactions = [];
  List<Goal> _goals = [];
  List<dynamic> _upcomingBills = [];
  int _notificationsCount = 0;

  static const _surface = Color(0xFFFCF9F4);
  static const _onSurfaceVariant = Color(0xFF524345);

  @override
  void initState() {
    super.initState();
    _loadTab();
    _loadData();
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('jo_finance_tab_index') ?? 0;
    });
  }

  void _onTabChanged(int index) async {
    final previousIndex = _currentIndex;
    setState(() => _currentIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jo_finance_tab_index', index);

    if (previousIndex == 1 && index != 1) {
      _loadData(showLoading: false);
    }
    
    if (index == 1) {
      _mentoriaKey.currentState?.loadHistory();
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final api = ApiService();
      
      final results = await Future.wait([
        api.getTransactions().catchError((_) => <Transaction>[]),
        api.getGoalsProgress().catchError((_) => []),
        api.getForecast('30d').catchError((_) => <String, dynamic>{}),
        api.getNetWorth().catchError((_) => <String, dynamic>{}),
        api.getUpcomingBills().catchError((_) => []),
        api.getChatHistory().catchError((_) => []),
      ]);

      final txData = results[0] as List<Transaction>;
      final goalsDataRaw = results[1] as List<dynamic>;
      final forecastData = results[2] as Map<String, dynamic>;
      final netWorthData = results[3] as Map<String, dynamic>;
      final billsData = results[4] as List<dynamic>;
      final chatHistory = results[5] as List<dynamic>;

      int notifCount = chatHistory.where((msg) => msg['is_user'] == false).length;

      double parseDouble(dynamic val) {
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }

      final List<Goal> goalsData = goalsDataRaw.map((gp) {
        return Goal(
          id: (gp['goal_id'] is num) ? (gp['goal_id'] as num).toInt() : (int.tryParse(gp['goal_id']?.toString() ?? '0') ?? 0),
          title: gp['title'] ?? '',
          targetAmount: parseDouble(gp['target_amount']),
          currentAmount: parseDouble(gp['current_amount']),
          percentage: parseDouble(gp['percentage']),
          type: 'custom',
        );
      }).toList();



      double balance = 0.0;
      if (forecastData.containsKey('current_balance')) {
        balance = parseDouble(forecastData['current_balance']);
      } else if (forecastData.containsKey('projected_balance')) {
        balance = parseDouble(forecastData['projected_balance']);
      } else if (netWorthData.containsKey('net_worth')) {
        balance = parseDouble(netWorthData['net_worth']);
      } else {
        for (var tx in txData) {
          final typeStr = tx.type?.toLowerCase() ?? '';
          if (typeStr == 'income' || typeStr == 'receita' || typeStr == 'entrada') {
            balance += tx.amount;
          } else {
            balance -= tx.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _transactions = txData;
          _goals = goalsData;
          _upcomingBills = billsData;
          _balance = balance;
          _notificationsCount = notifCount;
          _loading = false;
        });
      }
    } catch (e, stack) {
      print('=== ERRO NO LOADDATA ===');
      print(e);
      print(stack);
      if (mounted) {
        setState(() {
          _error = 'Erro detalhado: $e';
          _loading = false;
        });
      }
    }
  }

  String _getHeaderTitle() {
    switch (_currentIndex) {
      case 0: return 'Vitalidade Financeira';
      case 1: return 'Mentoria IA';
      case 2: return 'Minhas Metas';
      case 3: return 'Relatórios e Insights';
      default: return 'Jo Finanças';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;

    return Scaffold(
      backgroundColor: _surface,
      appBar: _currentIndex == 1 ? null : AppBar(
        backgroundColor: _primary,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null
                    ? Text(user?.name?.substring(0, 1).toUpperCase() ?? 'J', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá,', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),
                Text(user?.name?.split(' ').first ?? 'Usuário', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_outlined, color: Colors.white),
                if (_notificationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text(
                        _notificationsCount > 9 ? '9+' : '$_notificationsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : IndexedStack(
                  index: _currentIndex,
                  children: [
                    DashboardTab(balance: _balance, transactions: _transactions, goals: _goals, onRefresh: _loadData),
                    MentoriaTab(key: _mentoriaKey, onRefresh: _loadData),
                    MetasTab(goals: _goals, onRefresh: _loadData),
                    RelatoriosTab(transactions: _transactions),
                  ],
                ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: _primary,
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'PAINEL'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'MENTORIA'),
              BottomNavigationBarItem(icon: Icon(Icons.my_location_rounded), label: 'METAS'),
              BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'INSIGHTS'),
            ],
          ),
        ),
      ),
    );
  }
}
