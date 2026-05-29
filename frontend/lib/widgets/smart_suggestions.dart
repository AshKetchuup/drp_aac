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
      begin: Colors.greenAccent.withOpacity(0.4),
      end: Colors.greenAccent.withOpacity(1.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listening / Context Bar
              Row(
                children: [
                  const Icon(Icons.hearing, size: 28, color: Colors.black87),
                  const SizedBox(width: 8),
                  
                  // Teacher Prompt or Status
                  Expanded(
                    child: provider.teacherPrompt != null
                        ? Text(
                            '"${provider.teacherPrompt}"',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : const Text(
                            'Classroom Context',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                            ),
                          ),
                  ),

                  // Listen Button / Status
                  if (provider.isListeningContext)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: _pulseAnimation.value ?? Colors.greenAccent, width: 2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _pulseAnimation.value ?? Colors.greenAccent,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.mic, size: 18, color: Colors.greenAccent),
                              SizedBox(width: 8),
                              Text(
                                '((•)) Listening...',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        provider.startContextListening();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Listen Context',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dynamic Suggestion Area
              SizedBox(
                height: 56, // Slightly taller
                child: provider.isLoadingSuggestions
                    ? _buildSkeletonLoader()
                    : provider.contextSuggestions.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.contextSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = provider.contextSuggestions[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _SuggestionBtn(
                                  label: suggestion,
                                  icon: Icons.fastfood, // Generic icon for mockup
                                  isNew: true,
                                  onTap: () => widget.onSuggestionTap(suggestion),
                                ),
                              );
                            },
                          )
                        : provider.teacherPrompt != null
                            ? const Center(
                                child: Text(
                                  "No suggestions available.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isNew;

  const _SuggestionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNew ? Colors.lime : Colors.black87,
            width: isNew ? 3 : 2,
          ),
          boxShadow: isNew
              ? [
                  BoxShadow(
                    color: Colors.lime.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isNew ? Colors.black87 : Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.black87, size: 20),
          ],
        ),
      ),
    );
  }
}
