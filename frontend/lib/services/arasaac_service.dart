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

    // Try the word as-is first, then progressively strip common suffixes
    // (e.g. "legos" fails but "lego" has a result).
    for (final candidate in _searchCandidates(searchWord)) {
      final imageUrl = await _searchPictogram(candidate);
      if (imageUrl != null) {
        _cache[searchWord] = imageUrl;
        return imageUrl;
      }
    }

    // Cache null to avoid repeated failing network requests
    _cache[searchWord] = null;
    return null;
  }

  // Queries ARASAAC for a single term, returning the first pictogram URL or
  // null if none is found (or the request fails).
  Future<String?> _searchPictogram(String term) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.arasaac.org/api/pictograms/en/search/$term'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final id = data.first['_id'];
          return 'https://static.arasaac.org/pictograms/$id/${id}_300.png';
        }
      }
    } catch (e) {
      // Failed to fetch or no internet connection
      debugPrint('Failed to fetch ARASAAC pictogram for "$term": $e');
    }
    return null;
  }

  // Produces an ordered, de-duplicated list of search terms to try: the word
  // itself, then variants with useless suffixes removed so plurals/inflections
  // still resolve (e.g. "legos" -> "lego", "puppies" -> "puppy",
  // "running" -> "run").
  Iterable<String> _searchCandidates(String word) {
    final candidates = <String>[word];

    void add(String? variant) {
      if (variant != null && variant.length >= 2 && !candidates.contains(variant)) {
        candidates.add(variant);
      }
    }

    if (word.endsWith('ies')) {
      add('${word.substring(0, word.length - 3)}y');
    }
    if (word.endsWith('es')) {
      add(word.substring(0, word.length - 2));
    }
    if (word.endsWith('s')) {
      add(word.substring(0, word.length - 1));
    }
    if (word.endsWith('ing')) {
      add(word.substring(0, word.length - 3));
      add('${word.substring(0, word.length - 3)}e'); // "making" -> "make"
    }
    if (word.endsWith('ed')) {
      add(word.substring(0, word.length - 2));
      add(word.substring(0, word.length - 1)); // "liked" -> "like"
    }

    return candidates;
  }
}
