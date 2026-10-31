import 'dart:async';
import 'dart:convert';

import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../domain/chat_message.dart';

/// Turns sent per question; the backend accepts at most 20.
const _maxTurns = 20;

final chatRepositoryProvider = Provider((ref) => ChatRepository());

/// Follow-up questions to Gemini about one zone, answered as a stream.
/// The server keeps no history, so each question carries the recent
/// conversation with it.
///
/// Uses package:http rather than Dio: Dio's browser adapter buffers the
/// whole response, while fetch (web) and dart:io (Android) stream it.
class ChatRepository {
  http.Client _client() =>
      kIsWeb ? FetchClient(mode: RequestMode.cors) : http.Client();

  /// Gemini's answer to the last message in [messages], a user question,
  /// in pieces as they are written.
  Stream<String> ask(
    String lakeId,
    String zoneId,
    String lang,
    List<ChatMessage> messages,
  ) async* {
    var recent = messages.length > _maxTurns
        ? messages.sublist(messages.length - _maxTurns)
        : messages;
    // A conversation sent to Gemini has to start with the user.
    recent = recent.skipWhile((m) => !m.fromUser).toList();

    final request =
        http.Request(
            'POST',
            Uri.parse(
              '${Env.apiUrl}/api/lakes/$lakeId/zones/$zoneId/chat/stream',
            ),
          )
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({
            'lang': lang,
            'messages': [for (final m in recent) m.toJson()],
          });

    final client = _client();
    try {
      final http.StreamedResponse res;
      try {
        res = await client.send(request).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        throw ApiException('Cannot reach the server. Is the backend running?');
      } on http.ClientException {
        throw ApiException('Cannot reach the server. Is the backend running?');
      }
      if (res.statusCode != 200) {
        throw ApiException(
          _errorOf(await res.stream.bytesToString()) ??
              'Request failed (${res.statusCode})',
        );
      }

      // Server-Sent Events: one "data: {json}" line per event.
      final lines = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(
            const Duration(seconds: 60),
            onTimeout: (sink) {
              sink.addError(
                ApiException('The server took too long to answer.'),
              );
              sink.close();
            },
          );
      await for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final event = jsonDecode(line.substring(6)) as Map<String, dynamic>;
        if (event['text'] case final String text) yield text;
        if (event['error'] case final String error) throw ApiException(error);
        if (event['done'] == true) return;
      }
      throw ApiException('The answer was cut off. Try again.');
    } finally {
      client.close();
    }
  }

  /// The backend's `{"error": "..."}` message, if [body] is one.
  String? _errorOf(String body) {
    try {
      final j = jsonDecode(body);
      return j is Map && j['error'] is String ? j['error'] as String : null;
    } on FormatException {
      return null;
    }
  }
}
