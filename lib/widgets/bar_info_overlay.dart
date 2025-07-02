import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bar.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';

class BarInfoOverlay extends StatelessWidget {
  final Bar bar;
  final Position? currentPosition;
  final VoidCallback? onEnterBar;
  final bool isInProgress;

  const BarInfoOverlay({
    super.key,
    required this.bar,
    this.currentPosition,
    this.onEnterBar,
    this.isInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    double? distance;
    if (currentPosition != null) {
      distance = LocationService.calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        bar.lat,
        bar.lon,
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_bar,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bar.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    if (bar.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        bar.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.lightGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (distance != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.accentGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${distance.toStringAsFixed(0)}m päässä',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isInProgress ? null : onEnterBar,
              style: ElevatedButton.styleFrom(
                backgroundColor: isInProgress
                    ? AppTheme.grey
                    : AppTheme.accentGold,
                foregroundColor: isInProgress
                    ? AppTheme.lightGrey
                    : AppTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInProgress ? Icons.hourglass_empty : Icons.login,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isInProgress ? 'Käynnissä...' : 'Kirjaudu baariin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
