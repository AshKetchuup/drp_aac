import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
import '../theme/app_theme.dart';

class VoiceSettingsDialog extends StatefulWidget {
  const VoiceSettingsDialog({super.key});

  @override
  State<VoiceSettingsDialog> createState() => _VoiceSettingsDialogState();
}

class _VoiceSettingsDialogState extends State<VoiceSettingsDialog> {
  late double _pitch;
  late double _rate;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AACProvider>();
    _pitch = provider.voicePitch;
    _rate = provider.voiceRate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Voice Settings', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pitch: ${_pitch.toStringAsFixed(1)}', style: TextStyle(color: AppTheme.textSecondary)),
          Slider(
            value: _pitch,
            min: 0.5,
            max: 2.0,
            activeColor: AppTheme.primary,
            onChanged: (val) => setState(() => _pitch = val),
            onChangeEnd: (val) {
              context.read<AACProvider>().updateVoiceSettings(_pitch, _rate);
              context.read<AACProvider>().speak("Hello, this is my new voice.");
            },
          ),
          const SizedBox(height: 16),
          Text('Speed: ${_rate.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.textSecondary)),
          Slider(
            value: _rate,
            min: 0.1,
            max: 1.0,
            activeColor: AppTheme.primary,
            onChanged: (val) => setState(() => _rate = val),
            onChangeEnd: (val) {
              context.read<AACProvider>().updateVoiceSettings(_pitch, _rate);
              context.read<AACProvider>().speak("Hello, this is my new speed.");
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}

class GridLayoutDialog extends StatelessWidget {
  const GridLayoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AACProvider>();
    final currentCols = provider.gridColumns;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Grid Layout', style: TextStyle(color: AppTheme.textPrimary)),
      content: RadioGroup<int?>(
        groupValue: currentCols,
        onChanged: (val) {
          provider.updateGridColumns(val);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              title: const Text('Auto (Responsive)', style: TextStyle(color: AppTheme.textPrimary)),
              value: null,
              activeColor: AppTheme.primary,
            ),
            ...[2, 3, 4, 5, 6].map((cols) => RadioListTile<int?>(
                  title: Text('$cols Columns', style: const TextStyle(color: AppTheme.textPrimary)),
                  value: cols,
                  activeColor: AppTheme.primary,
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}

class AppearanceDialog extends StatelessWidget {
  const AppearanceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AACProvider>();

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Appearance', style: TextStyle(color: AppTheme.textPrimary)),
      content: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: provider.highContrast,
        onChanged: provider.setHighContrast,
        activeThumbColor: AppTheme.primary,
        title: const Text('High Contrast', style: TextStyle(color: AppTheme.textPrimary)),
        subtitle: Text(
          'Black background, white text, strong borders. Word colours stay the same.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}

class SuggestionCountDialog extends StatefulWidget {
  const SuggestionCountDialog({super.key});

  @override
  State<SuggestionCountDialog> createState() => _SuggestionCountDialogState();
}

class _SuggestionCountDialogState extends State<SuggestionCountDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = context.read<AACProvider>().minSuggestions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Suggestion Count', style: TextStyle(color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minimum suggestions: $_count',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'How many word suggestions the AI will generate each time.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _count.toDouble(),
            min: 2,
            max: 15,
            divisions: 13,
            label: '$_count',
            activeColor: AppTheme.primary,
            onChanged: (val) => setState(() => _count = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text('15', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            context.read<AACProvider>().updateMinSuggestions(_count);
            Navigator.pop(context);
          },
          child: const Text('Save', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}
