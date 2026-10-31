/// One turn of a follow-up chat about a zone.
class ChatMessage {
  const ChatMessage.user(this.text) : fromUser = true;
  const ChatMessage.model(this.text) : fromUser = false;

  ChatMessage.fromJson(Map<String, dynamic> j)
    : fromUser = j['role'] == 'user',
      text = j['text'] as String;

  final bool fromUser;
  final String text;

  Map<String, dynamic> toJson() => {
    'role': fromUser ? 'user' : 'model',
    'text': text,
  };
}

/// A zone's conversation, plus the state of the question being answered.
class ZoneChat {
  const ZoneChat({
    this.messages = const [],
    this.sending = false,
    this.partial = '',
    this.error,
  });

  final List<ChatMessage> messages;
  final bool sending;

  /// The answer so far, while it streams in.
  final String partial;

  /// Why the last question got no answer; it can be retried.
  final String? error;
}
