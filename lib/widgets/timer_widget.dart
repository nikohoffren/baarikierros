import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/timer_service.dart';

class TimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final bool isActive;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.timer : Icons.timer_off,
            size: 32,
            color: AppTheme.primaryBlack,
          ),
          const SizedBox(height: 12),
          Text(
            'Aika jäljellä',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TimerService.formatTime(remainingSeconds),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
              fontFamily: 'monospace',
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: remainingSeconds / (15 * 60), // 15 minutes
                backgroundColor: AppTheme.primaryBlack.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
