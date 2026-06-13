import 'dart:typed_data';

import '../services/api_client.dart';

/// Metadata for a board saved remotely; the raw .obf/.obz bytes live in GridFS
/// and are fetched on demand via [BoardRepository.download].
class BoardMeta {
  final String boardId;
  final String name;
  final String filename;
  final String? contentType;
  final String? uploadedAt;

  const BoardMeta({
    required this.boardId,
    required this.name,
    required this.filename,
    this.contentType,
    this.uploadedAt,
  });

  factory BoardMeta.fromJson(Map<String, dynamic> json) => BoardMeta(
    boardId: json['board_id'] as String,
    name: (json['name'] as String?) ?? (json['filename'] as String? ?? 'Board'),
    filename: (json['filename'] as String?) ?? 'board.obz',
    contentType: json['contentType'] as String?,
    uploadedAt: json['uploadedAt'] as String?,
  );
}

/// Saved boards for a single child profile.
class BoardRepository {
  BoardRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<List<BoardMeta>> list(String profileId) async {
    final data =
        await _api.getJson('/api/profiles/$profileId/boards') as List? ?? [];
    return data
        .map((j) => BoardMeta.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Upload a board file. [boardId] keeps re-uploads of the same board stable;
  /// the server generates one when omitted.
  Future<BoardMeta> upload(
    String profileId, {
    required String filename,
    required Uint8List bytes,
    String? name,
    String? boardId,
    String? contentType,
  }) async {
    final resp = await _api.uploadFile(
      '/api/profiles/$profileId/boards',
      field: 'file',
      filename: filename,
      bytes: bytes,
      contentType: contentType,
      fields: {
        'name': ?name,
        'board_id': ?boardId,
      },
    );
    return BoardMeta.fromJson(resp as Map<String, dynamic>);
  }

  Future<Uint8List> download(String profileId, String boardId) =>
      _api.getBytes('/api/profiles/$profileId/boards/$boardId/file');

  Future<void> deleteBoard(String profileId, String boardId) =>
      _api.delete('/api/profiles/$profileId/boards/$boardId');
}
