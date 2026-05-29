import 'package:flutter/material.dart';

class ArasaacImage extends StatelessWidget {
  final String keyword;
  final IconData fallbackIcon;
  final double size;
  final Color color;

  const ArasaacImage({
    super.key,
    required this.keyword,
    required this.fallbackIcon,
    this.size = 40,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Match the python script filename format
    final searchWord = keyword.split('/')[0].replaceAll('?', '').replaceAll("'", "").replaceAll(" ", "_").toLowerCase().trim();
    final path = searchWord == "dont_like" ? 'assets/arasaac/dislike.png' : 'assets/arasaac/$searchWord.png';

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          fallbackIcon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

