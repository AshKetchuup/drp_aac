import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';

class SmartSuggestions extends StatefulWidget {
  final Function(String) onSuggestionTap;

  const SmartSuggestions({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  State<SmartSuggestions> createState() => _SmartSuggestionsState();
}

class _SmartSuggestionsState extends State<SmartSuggestions> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<Color?> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = ColorTween(
      begin: Colors.greenAccent.withValues(alpha: 0.4),
      end: Colors.greenAccent,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black87, width: 2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.hearing, size: 24, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: provider.teacherPrompt != null
                    ? Text(
                        '"${provider.teacherPrompt}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : const Text(
                        'Classroom Context',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: provider.startContextListening,
                child: provider.isListeningContext
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: _pulseAnimation.value ?? Colors.redAccent, width: 2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop, size: 16, color: Colors.redAccent),
                              SizedBox(width: 6),
                              Text(
                                'Stop',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 16, color: Colors.green),
                          SizedBox(width: 6),
                          Text(
                            'Listen',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
