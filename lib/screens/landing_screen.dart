import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../providers/theme_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _pricingKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              _buildAppBar(context, colorScheme, isDark),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHero(context, colorScheme, isDark),
                    _buildFeatures(context, colorScheme, isDark, surfaceColor),
                    _buildPricing(context, colorScheme, isDark, surfaceColor),
                    _buildFooter(context, colorScheme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)).withValues(alpha: 0.8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.rocket_launch, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          // Esconde o texto longo em telas muito pequenas para não estourar (RenderFlex)
          if (MediaQuery.of(context).size.width > 380)
            Text(
              'Josi Finanças',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
          },
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
          ),
          child: Text(
            'Login',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              'Criar Conta',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHero(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      constraints: const BoxConstraints(maxWidth: 1280),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: colorScheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'A revolução financeira chegou',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: isDesktop ? 64 : 42,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                        children: [
                          const TextSpan(text: 'Transforme sua\n'),
                          TextSpan(
                            text: 'relação ',
                            style: TextStyle(
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.secondary],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          const TextSpan(text: 'com o dinheiro.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'O caminho para sua liberdade financeira não precisa ser solitário. Junte-se a Josi e descubra como dominar seus investimentos e construir um futuro sólido.',
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Começar Agora',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            if (_pricingKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _pricingKey.currentContext!,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOutQuart,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'Conhecer Planos',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(width: 64),
              if (!isDesktop) const SizedBox(height: 64),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 60,
                          spreadRadius: 20,
                        )
                      ],
                    ),
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDNIWscr2o7sx2kDWodqfQ1cbXuXO2XKCoXWRTZ3iKuzZMg3IEtn7vwqik90BktHML0zMf0K16QspEvs_nNZ89FF5f5GhXqbvXTGwvKw_e752T-eS5k10qYHmBqWMfpvCw9Bieb6XQa1S2X4obYaTGmZqtRDde4n-leZMHQikClqnZ3Ui-fhivoAmdJ_b8IqrF8xGl6bFxEaUjfYmX1kjRLWK6BcGkJEFY_zdyox7hnqL6X932SZN5-Qmrzludwc66kF7SkNIlfhwTU',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatures(BuildContext context, ColorScheme colorScheme, bool isDark, Color surfaceColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              Text(
                'Por que escolher a Josi?',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tudo que você precisa para alcançar a independência financeira.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: _buildFeatureCard(
                          icon: Icons.auto_graph_rounded,
                          title: 'Análise de Carteira',
                          description: 'Avaliação detalhada dos seus ativos para otimizar rentabilidade e segurança.',
                          colorScheme: colorScheme,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                        ),
                      ),
                      if (isDesktop) const SizedBox(width: 32),
                      if (!isDesktop) const SizedBox(height: 32),
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: _buildFeatureCard(
                          icon: Icons.groups_rounded,
                          title: 'Mentorias Exclusivas',
                          description: 'Sessões individuais para planejar seu futuro financeiro com precisão cirúrgica.',
                          colorScheme: colorScheme,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          isFeatured: true,
                        ),
                      ),
                      if (isDesktop) const SizedBox(width: 32),
                      if (!isDesktop) const SizedBox(height: 32),
                      Expanded(
                        flex: isDesktop ? 1 : 0,
                        child: _buildFeatureCard(
                          icon: Icons.insert_chart_rounded,
                          title: 'Gestão Inteligente',
                          description: 'Ferramentas de controle de gastos e projeção de metas fáceis de usar.',
                          colorScheme: colorScheme,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    required bool isDark,
    required Color surfaceColor,
    bool isFeatured = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isFeatured ? colorScheme.primary : surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isFeatured ? Colors.transparent : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: (isFeatured ? colorScheme.primary : Colors.black).withValues(alpha: isFeatured ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFeatured ? Colors.white.withValues(alpha: 0.2) : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: isFeatured ? Colors.white : colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isFeatured ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.5,
              color: isFeatured ? Colors.white.withValues(alpha: 0.9) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(BuildContext context, ColorScheme colorScheme, bool isDark, Color surfaceColor) {
    return Container(
      key: _pricingKey,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Column(
        children: [
          Text(
            'Planos Simples e Transparentes',
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'O investimento ideal para cada etapa da sua jornada.',
            style: GoogleFonts.inter(fontSize: 18, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: _buildPricingCard(
                      title: 'Plano Gratuito',
                      subtitle: 'Essencial para começar.',
                      price: 'R\$ 0',
                      features: [
                        {'text': 'Acesso a dicas semanais', 'included': true},
                        {'text': 'Planilhas básicas de orçamento', 'included': true},
                        {'text': 'Sem mentoria individual', 'included': false},
                        {'text': 'Sem auxílio de IA', 'included': false},
                      ],
                      isPremium: false,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                    ),
                  ),
                  if (isDesktop) const SizedBox(width: 32),
                  if (!isDesktop) const SizedBox(height: 32),
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: _buildPricingCard(
                      title: 'Plano Premium',
                      subtitle: 'Para quem busca excelência.',
                      price: 'R\$ 50',
                      features: [
                        {'text': 'Mentorias exclusivas mensais', 'included': true},
                        {'text': 'Análise completa de carteira', 'included': true},
                        {'text': 'Auxílio de Inteligência Artificial (IA)', 'included': true},
                        {'text': 'Suporte prioritário via WhatsApp', 'included': true},
                        {'text': 'Eventos VIP trimestrais', 'included': true},
                      ],
                      isPremium: true,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String subtitle,
    required String price,
    required List<Map<String, dynamic>> features,
    required bool isPremium,
    required ColorScheme colorScheme,
    required bool isDark,
    required Color surfaceColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isPremium ? colorScheme.primary : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          width: isPremium ? 2 : 1,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'RECOMENDADO',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text('/mês', style: GoogleFonts.inter(fontSize: 18, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 40),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: f['included'] ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                        border: f['included'] ? null : Border.all(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      child: Icon(
                        f['included'] ? Icons.check : Icons.close,
                        color: f['included'] ? colorScheme.primary : (isDark ? Colors.white38 : Colors.black26),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        f['text'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: f['included'] ? (isDark ? Colors.white : const Color(0xFF1E293B)) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          fontWeight: f['included'] ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: isPremium
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Assinar Premium', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('Começar Agora', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0B1120) : Colors.white,
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  return Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rocket_launch, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Josi Finanças', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Educação financeira personalizada para\ntransformar vidas e realizar sonhos.',
                            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      if (!isDesktop) const SizedBox(height: 48),
                      Column(
                        crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(onPressed: () {}, child: Text('Serviços', style: GoogleFonts.inter(color: isDark ? Colors.white70 : const Color(0xFF475569)))),
                              const SizedBox(width: 16),
                              TextButton(onPressed: () {}, child: Text('Preços', style: GoogleFonts.inter(color: isDark ? Colors.white70 : const Color(0xFF475569)))),
                              const SizedBox(width: 16),
                              TextButton(onPressed: () {}, child: Text('Sobre', style: GoogleFonts.inter(color: isDark ? Colors.white70 : const Color(0xFF475569)))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                child: IconButton(onPressed: () {}, icon: const Icon(Icons.public, size: 20), color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                child: IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded, size: 20), color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                child: IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt, size: 20), color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 64),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
            ),
            child: Text(
              '© 2026 Josi Finanças. Todos os direitos reservados.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
