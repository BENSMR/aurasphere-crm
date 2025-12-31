import 'package:flutter/material.dart';

/// Modern glassmorphic design system for AuraSphere CRM
class ModernTheme {
  // ==================== COLORS ====================
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1a1a1a);
  static const Color textGray = Color(0xFF6C757D);
  static const Color borderGray = Color(0xFFE9ECEF);
  static const Color successGreen = Color(0xFF00C853);
  static const Color dangerRed = Color(0xFFFF3B30);

  // ==================== SHADOWS ====================
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> glassmorphShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];

  // ==================== GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF0050CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryOrange, Color(0xFFFF8533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryBlue, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;

  // ==================== SPACING ====================
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ==================== TEXT STYLES ====================
  static const TextStyle headline1 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textDark,
    fontFamily: 'Manrope',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textGray,
    fontFamily: 'Manrope',
  );

  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textGray,
    fontFamily: 'Manrope',
  );

  // ==================== ANIMATION DURATIONS ====================
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ==================== HELPER METHODS ====================
  static BoxDecoration cardDecoration({bool hover = false}) {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: hover ? hoverShadow : cardShadow,
    );
  }

  static BoxDecoration glassmorphDecoration() {
    return BoxDecoration(
      color: cardWhite.withOpacity(0.7),
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: glassmorphShadow,
    );
  }

  static BoxDecoration buttonDecoration(Color color) {
    return BoxDecoration(
      gradient: color == primaryBlue
          ? primaryGradient
          : color == primaryOrange
              ? accentGradient
              : LinearGradient(colors: [color, color]),
      borderRadius: BorderRadius.circular(radiusMedium),
    );
  }
}

/// Modern Button Styles
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool fullWidth;
  final Widget? icon;
  final bool loading;

  const ModernButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.color = ModernTheme.primaryBlue,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
  }) : super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.animationFast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: ModernTheme.animationFast,
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: ModernTheme.spacingL,
            vertical: ModernTheme.spacingM,
          ),
          decoration: BoxDecoration(
            gradient: widget.color == ModernTheme.primaryBlue
                ? ModernTheme.primaryGradient
                : widget.color == ModernTheme.primaryOrange
                    ? ModernTheme.accentGradient
                    : LinearGradient(colors: [widget.color, widget.color]),
            borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
            boxShadow: _hovering ? ModernTheme.hoverShadow : ModernTheme.cardShadow,
          ),
          transform: _hovering ? Matrix4.identity()..translate(0, -2) : Matrix4.identity(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.loading) ...[
                widget.icon!,
                const SizedBox(width: ModernTheme.spacingS),
              ],
              if (widget.loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Manrope',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated Card with fade and slide effects
class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool hover;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(ModernTheme.spacingL),
    this.borderRadius = ModernTheme.radiusMedium,
    this.hover = true,
  }) : super(key: key);

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.animationFast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.hover ? (_) => setState(() => _hovering = true) : null,
      onExit: widget.hover ? (_) => setState(() => _hovering = false) : null,
      child: AnimatedContainer(
        duration: ModernTheme.animationFast,
        decoration: ModernTheme.cardDecoration(hover: _hovering && widget.hover),
        transform: widget.hover && _hovering
            ? Matrix4.identity()..translate(0, -4)
            : Matrix4.identity(),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Page transition with fade and slide
class ModernPageTransition extends StatelessWidget {
  final Widget child;
  final Offset beginOffset;

  const ModernPageTransition({
    Key? key,
    required this.child,
    this.beginOffset = const Offset(0, 0.1),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ModernTheme.animationNormal,
      builder: (context, opacity, _) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - opacity),
            beginOffset.dy * (1 - opacity),
          ),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
    );
  }
}
