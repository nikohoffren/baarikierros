import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/timer_service.dart';
import '../models/bar.dart';
import 'package:intl/intl.dart';

class TimerWidget extends StatefulWidget {
  final int remainingSeconds;
  final bool isActive;
  final Bar currentBar;
  final int currentBarIndex;
  final int totalBars;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.isActive,
    required this.currentBar,
    required this.currentBarIndex,
    required this.totalBars,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getOpeningHoursForToday(Bar bar) {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now).toLowerCase();
    final todayHours = bar.openingHours[weekday]?.first;
    return todayHours != null ? '${todayHours.open} - ${todayHours.close}' : 'Suljettu';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final openingHours = _getOpeningHoursForToday(widget.currentBar);

    return Container(
      width: screenWidth * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Baari ${widget.currentBarIndex + 1}/${widget.totalBars}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: (widget.currentBarIndex + 1) / widget.totalBars,
                  backgroundColor: AppTheme.primaryBlack.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            widget.currentBar.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: AppTheme.primaryBlack.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                'Avoinna tänään: $openingHours',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryBlack.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (widget.currentBar.description != null) ...[
            Text(
              widget.currentBar.description!,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryBlack.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (widget.currentBar.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPhotoIndex = index;
                      });
                    },
                    itemCount: widget.currentBar.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(widget.currentBar.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  if (widget.currentBar.imageUrls.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.currentBar.imageUrls.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoIndex == index
                                  ? AppTheme.primaryBlack
                                  : AppTheme.primaryBlack.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Center(
            child: Column(
              children: [
                Icon(
                  widget.isActive ? Icons.timer : Icons.timer_off,
                  size: 40,
                  color: AppTheme.primaryBlack,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aikaa jäljellä',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TimerService.formatTime(widget.remainingSeconds),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlack,
                    fontFamily: 'monospace',
                  ),
                ),
                if (widget.isActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: screenWidth * 0.7,
                    child: LinearProgressIndicator(
                      value: widget.remainingSeconds / (15 * 60), //* 15 minutes
                      backgroundColor: AppTheme.primaryBlack.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
