import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ArasaacService {
  static final ArasaacService _instance = ArasaacService._internal();
  factory ArasaacService() => _instance;
  ArasaacService._internal();

  final Map<String, String?> _cache = {};

  // Fetch pictogram image URL by keyword
  Future<String?> getPictogramUrl(String keyword) async {
    final searchWord = keyword.toLowerCase().trim();
    if (_cache.containsKey(searchWord)) {
      return _cache[searchWord];
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.arasaac.org/api/pictograms/en/search/$searchWord'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final id = data.first['_id'];
          final imageUrl = 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
          _cache[searchWord] = imageUrl;
          return imageUrl;
        }
      }
    } catch (e) {
      // Failed to fetch or no internet connection
      debugPrint('Failed to fetch ARASAAC pictogram for "$searchWord": $e');
    }

    // Cache null to avoid repeated failing network requests
    _cache[searchWord] = null;
    return null;
  }
}
