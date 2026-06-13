import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final double percentage;
  final String currentAmountText;
  final String targetAmountText;
  final String? detailText;

  const GoalCard({
    Key? key,
    required this.title,
    required this.percentage,
    required this.currentAmountText,
    required this.targetAmountText,
    this.detailText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final _primary = theme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: _primary.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.track_changes, color: _primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (detailText != null) ...[
                      const SizedBox(height: 2),
                      Text(detailText!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ]
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage >= 100 ? Colors.green.shade50 : _primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: percentage >= 100 ? Colors.green.shade200 : _primary.withValues(alpha: 0.2)),
                ),
                child: Text('${percentage.toInt()}%', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: percentage >= 100 ? Colors.green.shade700 : _primary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar base
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: 10,
                    width: constraints.maxWidth * (percentage / 100).clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: percentage >= 100 ? [Colors.green.shade400, Colors.green.shade600] : [_primary.withValues(alpha: 0.7), _primary]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: (percentage >= 100 ? Colors.green : _primary).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acumulado', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(currentAmountText, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Objetivo', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(targetAmountText, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
