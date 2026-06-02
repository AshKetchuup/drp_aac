import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class CalmingMode extends StatelessWidget {
  final VoidCallback onExit;
  final Function(String) onSelect;

  const CalmingMode({
    super.key,
    required this.onExit,
    required this.onSelect,
  });

  static final List<EmergencyOption> options = [
    EmergencyOption(
      id: 'quiet',
      label: 'Quiet / Break',
      icon: Icons.volume_off_rounded,
      color: Color(0xFF3B82F6), // Blue
    ),
    EmergencyOption(
      id: 'drink',
      label: 'Drink',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF22C55E), // Green
    ),
    EmergencyOption(
      id: 'hurt',
      label: 'Hurt / Help',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF4444), // Red
    ),
    EmergencyOption(
      id: 'leave',
      label: 'Leave / Exit',
      icon: Icons.exit_to_app_rounded,
      color: Color(0xFFF97316), // Orange
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.emergency_rounded,
                          color: AppTheme.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Overload Mode',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onExit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.close, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Exit',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Emergency buttons grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return _EmergencyButton(
                      option: option,
                      onTap: () => onSelect(option.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final EmergencyOption option;
  final VoidCallback onTap;

  const _EmergencyButton({
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: option.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: option.color,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                size: 64,
                color: option.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              option.label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
