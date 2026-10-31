import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../settings/application/settings_providers.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';
import 'insights_providers.dart';

/// Prefix of saved chats in the local store.
const chatCachePrefix = 'chat:v1:';

/// Follow-up chat per zone, saved on the phone so it is there next time.
/// Not auto-disposed: an answer still arrives if the zone is closed meanwhile.
final zoneChatProvider =
    NotifierProvider.family<ZoneChatController, ZoneChat, ZoneRef>(
      ZoneChatController.new,
    );

class ZoneChatController extends Notifier<ZoneChat> {
  ZoneChatController(this.zone);

  final ZoneRef zone;

  String get _key => '$chatCachePrefix${zone.lakeId}|${zone.zoneId}';

  @override
  ZoneChat build() {
    final saved = ref.read(localStoreProvider).readJson(_key);
    if (saved == null) return const ZoneChat();
    return ZoneChat(
      messages: [
        for (final m in saved['messages'] as List)
          ChatMessage.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.sending) return;
    state = ZoneChat(
      messages: [...state.messages, ChatMessage.user(question)],
      sending: true,
    );
    await _answer();
  }

  /// Asks again after an error.
  Future<void> retry() async {
    if (state.sending || state.error == null) return;
    state = ZoneChat(messages: state.messages, sending: true);
    await _answer();
  }

  Future<void> clear() async {
    state = const ZoneChat();
    await ref.read(localStoreProvider).remove(_key);
  }

  Future<void> _answer() async {
    final asked = state.messages;
    // Cleared while answering: stop and drop the answer.
    bool stale() => !ref.mounted || !identical(state.messages, asked);
    final answer = StringBuffer();
    try {
      final pieces = ref
          .read(chatRepositoryProvider)
          .ask(zone.lakeId, zone.zoneId, ref.read(appLanguageProvider), asked);
      await for (final piece in pieces) {
        // Leaving the loop cancels the request.
        if (stale()) return;
        answer.write(piece);
        state = ZoneChat(
          messages: asked,
          sending: true,
          partial: answer.toString(),
        );
      }
      if (stale()) return;
      final reply = answer.toString().trim();
      state = ZoneChat(messages: [...asked, ChatMessage.model(reply)]);
      await ref.read(localStoreProvider).writeJson(_key, {
        'messages': [for (final m in state.messages) m.toJson()],
      });
    } catch (e) {
      if (!ref.mounted || !identical(state.messages, asked)) return;
      state = ZoneChat(messages: asked, error: '$e');
    }
  }
}
