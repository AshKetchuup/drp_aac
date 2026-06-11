import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'symbol_tile.dart';

class SentenceRail extends StatelessWidget {
  final VoidCallback onSpeak;
  final VoidCallback onClear;
  final double height;

  const SentenceRail({
    super.key,
    required this.onSpeak,
    required this.onClear,
    this.height = 124,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          color: Colors.black, // Dark background
          height: height,
          child: Row(
            children: [
              // Add custom word button
              _IconButton(
                icon: Icons.add,
                color: Colors.blueGrey,
                onTap: () {
                  _showAddCustomWordDialog(context, provider);
                },
              ),
              const SizedBox(width: 4),
              // Undo/Backspace (Word level)
              _IconButton(
                icon: Icons.keyboard_backspace,
                color: Colors.blueGrey,
                onTap: () {
                  if (provider.sentenceBuilder.isNotEmpty) {
                    provider.removeFromSentence(provider.sentenceBuilder.length - 1);
                  }
                },
              ),
              const SizedBox(width: 4),
              
              // Sentence display area
              Expanded(
                child: GestureDetector(
                  onTap: onSpeak, // Keep tap text area to speak as fallback
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.isHighContrast
                          ? Colors.black
                          : Colors.white,
                      border: Border.all(
                        color: AppTheme.isHighContrast
                            ? Colors.white
                            : Colors.black,
                        width: 2,
                      ),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: provider.sentenceBuilder.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final symbol = provider.sentenceBuilder[index];
                        // Reuse the exact grid tile so the rail icons fill the
                        // square just like the communication board — no extra
                        // padding shrinking the pictogram.
                        return AspectRatio(
                          aspectRatio: 1,
                          child: SymbolTile(
                            symbol: symbol,
                            onTap: onSpeak,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              // Dedicated SPEAK Button (User requested)
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue, // Make it stand out
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volume_up,
                        color: AppTheme.isHighContrast
                            ? AppTheme.onColor(Colors.blue)
                            : Colors.white,
                        size: 32,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Speak',
                          style: TextStyle(
                            color: AppTheme.isHighContrast
                                ? AppTheme.onColor(Colors.blue)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              
              // Delete word button
              _IconButton(
                icon: Icons.backspace,
                color: Colors.blueGrey,
                onTap: () {
                  if (provider.sentenceBuilder.isNotEmpty) {
                    provider.removeFromSentence(provider.sentenceBuilder.length - 1);
                  }
                },
              ),
              const SizedBox(width: 4),
              // Clear All button
              _IconButton(
                icon: Icons.delete,
                color: Colors.blueGrey,
                onTap: onClear,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppTheme.isHighContrast ? Colors.white : Colors.black87,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: AppTheme.isHighContrast
                ? AppTheme.onColor(color)
                : Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

  void _showAddCustomWordDialog(BuildContext context, AACProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String inputText = '';
        return AlertDialog(
          backgroundColor:
              AppTheme.isHighContrast ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (val) => inputText = val,
                decoration: const InputDecoration(
                  hintText: 'Type a custom word...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add an image (optional):'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DialogOption(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: () async {
                      if (inputText.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please type a word first')),
                        );
                        return;
                      }
                      final picker = ImagePicker();
                      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 300);
                      if (photo != null) {
                        final bytes = await photo.readAsBytes();
                        final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        if (context.mounted) {
                          _saveAndClose(dialogContext, provider, inputText.trim(), dataUri);
                        }
                      }
                    },
                  ),
                  _DialogOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      if (inputText.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please type a word first')),
                        );
                        return;
                      }
                      final picker = ImagePicker();
                      final photo = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300);
                      if (photo != null) {
                        final bytes = await photo.readAsBytes();
                        final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        if (context.mounted) {
                          _saveAndClose(dialogContext, provider, inputText.trim(), dataUri);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (inputText.trim().isNotEmpty) {
                  _saveAndClose(dialogContext, provider, inputText.trim(), null);
                }
              },
              child: const Text('Add without Photo'),
            ),
          ],
        );
      },
    );
  }

  void _saveAndClose(BuildContext dialogContext, AACProvider provider, String word, String? imageUrl) {
    final symbol = Symbol(
      id: 'custom_${word.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      label: word,
      category: SymbolCategory.noun,
      icon: Icons.star,
      imageUrl: imageUrl,
    );
    provider.addCustomSymbol(symbol);
    provider.addToSentence(symbol);
    Navigator.pop(dialogContext);
  }

class _DialogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DialogOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.isHighContrast
                  ? AppTheme.surfaceLight
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.isHighContrast
                    ? Colors.white
                    : Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
