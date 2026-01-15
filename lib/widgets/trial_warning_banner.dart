import 'package:flutter/material.dart';
import '../services/trial_service.dart';

class TrialWarningBanner extends StatefulWidget {
  final String orgId;
  final String? userId;
  final VoidCallback? onUpgradePressed;

  const TrialWarningBanner({
    super.key,
    required this.orgId,
    this.userId,
    this.onUpgradePressed,
  });

  @override
  State<TrialWarningBanner> createState() => _TrialWarningBannerState();
}

class _TrialWarningBannerState extends State<TrialWarningBanner> {
  final _trialService = TrialService();
  int remainingDays = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrialInfo();
  }

  Future<void> _loadTrialInfo() async {
    try {
      final days = await _trialService.getRemainingTrialDays(widget.orgId);
      if (mounted) {
        setState(() {
          remainingDays = days;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || remainingDays <= 0) {
      return const SizedBox.shrink();
    }

    // Determine banner color based on remaining days
    Color bannerColor;
    String urgencyText;
    IconData icon;

    if (remainingDays >= 2) {
      bannerColor = const Color(0xFF4CAF50); // Green
      urgencyText = '✨ Trial Active';
      icon = Icons.check_circle;
    } else if (remainingDays == 1) {
      bannerColor = const Color(0xFFFF9800); // Orange - Warning
      urgencyText = '⚠️ Trial Ending Tomorrow!';
      icon = Icons.warning;
    } else {
      bannerColor = const Color(0xFFF44336); // Red - Critical
      urgencyText = '🚨 Trial Expires Today!';
      icon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        border: Border.all(color: bannerColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgencyText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remainingDays == 1
                      ? 'Upgrade now to maintain access after trial ends'
                      : 'You have $remainingDays days left. Full access to all features.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                if (remainingDays <= 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '💰 Get 50% off your first 2 months when you upgrade',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: widget.onUpgradePressed ??
                () {
                  // Default: navigate to pricing
                  Navigator.pushNamed(context, '/pricing');
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: bannerColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              remainingDays <= 1 ? 'Upgrade Now' : 'View Plans',
            ),
          ),
        ],
      ),
    );
  }
}

/// Show trial ending dialog when trial has 1 day or less
class TrialEndingDialog extends StatelessWidget {
  final int remainingDays;
  final String planName;
  final double monthlPrice;
  final VoidCallback onUpgradePressed;

  const TrialEndingDialog({
    super.key,
    required this.remainingDays,
    required this.planName,
    required this.monthlPrice,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final discountedPrice = (monthlPrice * 0.5).toStringAsFixed(2);

    return AlertDialog(
      title: const Text('⏰ Your Trial is Ending Soon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            remainingDays == 0
                ? 'Your 3-day free trial has ended.'
                : 'Your trial expires in $remainingDays day${remainingDays == 1 ? '' : 's'}.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Special Offer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Regular price:'),
                    Text(
                      '\$${monthlPrice.toStringAsFixed(2)}/month',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'First 2 months:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$$discountedPrice/month',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Then \$${monthlPrice.toStringAsFixed(2)}/month',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '✓ Cancel anytime\n'
            '✓ No long-term commitment\n'
            '✓ Full access to all features',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onUpgradePressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }
}
