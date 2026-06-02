import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomBar extends StatelessWidget {
  final String? userName;
  final String? avatarId;
  final bool isCalmingMode;
  final VoidCallback onOverloadToggle;
  final VoidCallback onSettingsTap;
  final VoidCallback? onProfileTap;

  const BottomBar({
    super.key,
    this.userName,
    this.avatarId,
    required this.isCalmingMode,
    required this.onOverloadToggle,
    required this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          // User profile section
          if (userName != null)
            GestureDetector(
              onTap: onProfileTap,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName!,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Synced',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Overload mode toggle
          GestureDetector(
            onTap: onOverloadToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCalmingMode 
                    ? AppTheme.error.withOpacity(0.2) 
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCalmingMode ? AppTheme.error : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCalmingMode 
                        ? Icons.emergency_rounded 
                        : Icons.shield_outlined,
                    color: isCalmingMode 
                        ? AppTheme.error 
                        : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCalmingMode ? 'Exit Overload' : 'Overload Mode',
                    style: TextStyle(
                      color: isCalmingMode 
                          ? AppTheme.error 
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
