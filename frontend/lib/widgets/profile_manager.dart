import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../screens/profile_setup_screen.dart';

/// Emoji for the avatar ids used by [ProfileSetup]. Falls back to a neutral face.
const Map<String, String> _avatarEmoji = {
  'boy_1': '👦🏻',
  'boy_2': '👦🏼',
  'boy_3': '👦🏽',
  'boy_4': '👦🏿',
  'girl_1': '👧🏻',
  'girl_2': '👧🏼',
  'girl_3': '👧🏽',
  'girl_4': '👧🏿',
};

String avatarEmojiFor(String avatarId) => _avatarEmoji[avatarId] ?? '🙂';

/// Bottom sheet to switch between child profiles, add a new child (via the
/// existing setup wizard) or delete one.
void showProfilePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ProfilePickerSheet(),
  );
}

class _ProfilePickerSheet extends StatelessWidget {
  const _ProfilePickerSheet();

  Future<void> _addChild(BuildContext context) async {
    final provider = context.read<AACProvider>();
    Navigator.pop(context); // close the picker first
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ProfileSetup(
          onComplete: (profile) {
            provider.setProfile(profile);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserProfile profile) async {
    final provider = context.read<AACProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${profile.name}?'),
        content: const Text(
          'This permanently removes this child\'s profile, custom tiles, '
          'schedule and saved boards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteProfile(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, _) {
        final profiles = provider.profiles;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Children',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final p in profiles)
                        ListTile(
                          leading: Text(
                            avatarEmojiFor(p.avatarId),
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                          subtitle: p.age != null
                              ? Text(
                                  'Age ${p.age}',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.id == provider.activeProfileId)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF22C55E)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppTheme.error),
                                onPressed: () => _confirmDelete(context, p),
                              ),
                            ],
                          ),
                          onTap: () {
                            provider.selectProfile(p.id);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _addChild(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add child'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet listing boards saved remotely for the active child profile,
/// with open and delete actions.
void showSavedBoards(BuildContext context) {
  final provider = context.read<AACProvider>();
  provider.loadSavedBoards();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SavedBoardsSheet(),
  );
}

class _SavedBoardsSheet extends StatelessWidget {
  const _SavedBoardsSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, _) {
        final boards = provider.savedBoards;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Boards',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (boards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No boards saved yet. Import an OBF/OBZ board to save it here.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final b in boards)
                        ListTile(
                          leading: Icon(Icons.dashboard_outlined,
                              color: AppTheme.textSecondary),
                          title: Text(
                            b.name,
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.error),
                            onPressed: () => provider.deleteSavedBoard(b.boardId),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              await provider.openSavedBoard(b.boardId);
                            } catch (_) {}
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
