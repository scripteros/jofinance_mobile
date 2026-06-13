import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String date;
  final String category;
  final double amount;
  final bool isIncome;
  final IconData icon;

  const TransactionItem({
    Key? key,
    required this.title,
    required this.date,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const _onSurface = Color(0xFF1C1C19);
    const _onSurfaceVariant = Color(0xFF524345);
    const _outlineVariant = Color(0xFFD7C1C4);
    
    final color = isIncome ? Colors.green : const Color(0xFF8B4757);
    final bgColor = isIncome ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF8B4757).withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$category • $date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'} R\$ ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green.shade700 : _onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
