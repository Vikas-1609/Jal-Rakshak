import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/common.dart';
import '../../application/chat_providers.dart';
import '../../domain/chat_message.dart';

/// Follow-up questions to Gemini about one zone, below its explanation.
/// Inline rather than a separate screen, so it works the same in the map
/// sheet, the map side panel and the zone page.
class ZoneChatCard extends ConsumerStatefulWidget {
  const ZoneChatCard({super.key, required this.lakeId, required this.zoneId});

  final String lakeId, zoneId;

  @override
  ConsumerState<ZoneChatCard> createState() => _ZoneChatCardState();
}

class _ZoneChatCardState extends ConsumerState<ZoneChatCard> {
  final _input = TextEditingController();
  final _inputKey = GlobalKey();

  ({String lakeId, String zoneId}) get _zone =>
      (lakeId: widget.lakeId, zoneId: widget.zoneId);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    Haptics.selection();
    _input.clear();
    ref.read(zoneChatProvider(_zone).notifier).send(text);
  }

  /// Keeps the newest message and the input in view as the chat grows.
  void _revealInput(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _inputKey.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chat = ref.watch(zoneChatProvider(_zone));
    final controller = ref.read(zoneChatProvider(_zone).notifier);
    ref.listen(
      zoneChatProvider(_zone).select((c) => c.messages.length),
      (_, _) => _revealInput(const Duration(milliseconds: 300)),
    );
    // Follow a streaming answer as it grows; quickly, as pieces come often.
    ref.listen(
      zoneChatProvider(_zone).select((c) => c.partial.length),
      (_, _) => _revealInput(const Duration(milliseconds: 120)),
    );

    return SectionCard(
      title: l.chatTitle,
      icon: Icons.forum_outlined,
      trailing: chat.messages.isEmpty
          ? null
          : M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l.chatClear,
              onPressed: () {
                Haptics.selection();
                controller.clear();
              },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chat.messages.isEmpty) ...[
            Text(l.chatIntro),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in [
                  l.chatSuggest1,
                  l.chatSuggest2,
                  l.chatSuggest3,
                ])
                  ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(q),
                    onPressed: chat.sending ? null : () => _send(q),
                  ),
              ],
            ),
          ],
          for (final (i, m) in chat.messages.indexed)
            FadeSlideIn(
              key: ValueKey('${widget.zoneId}-$i'),
              offset: 12,
              child: _Bubble(message: m),
            ),
          // The answer so far, keyed like the message it becomes so it
          // doesn't animate in again when finished.
          if (chat.partial.isNotEmpty)
            FadeSlideIn(
              key: ValueKey('${widget.zoneId}-${chat.messages.length}'),
              offset: 12,
              child: _Bubble(message: ChatMessage.model(chat.partial)),
            )
          else if (chat.sending)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const M3ELoadingIndicator(size: 24),
                  const SizedBox(width: 10),
                  Text(l.chatThinking),
                ],
              ),
            ),
          if (chat.error case final error?)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.chatError(error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                M3EButton.text(
                  onPressed: () {
                    Haptics.selection();
                    controller.retry();
                  },
                  child: Text(l.retry),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _ChatInput(
            key: _inputKey,
            controller: _input,
            enabled: !chat.sending,
            onSend: _send,
          ),
          const SizedBox(height: 10),
          Text(l.chatFootnote, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            // Matches the backend's limit per question.
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            // Enter sends; on phones the keyboard shows a send key.
            textInputAction: TextInputAction.send,
            onSubmitted: enabled ? onSend : null,
            decoration: InputDecoration(
              hintText: l.chatHint,
              counterText: '',
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => M3EIconButton(
            variant: M3EIconButtonVariant.filled,
            icon: const Icon(Icons.send_rounded),
            tooltip: l.chatSend,
            onPressed: enabled && controller.text.trim().isNotEmpty
                ? () => onSend(controller.text)
                : null,
          ),
        ),
      ],
    );
  }
}

/// The user's questions on the right, Gemini's answers on the left.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.fromUser;
    const r = Radius.circular(20), tail = Radius.circular(6);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      // 85% of the card, not the screen: the card can sit in a narrow panel.
      child: FractionallySizedBox(
        widthFactor: 0.85,
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: mine ? r : tail,
                bottomRight: mine ? tail : r,
              ),
            ),
            // Selectable, so an answer can be copied into a message or report.
            child: SelectableText(
              message.text,
              style: TextStyle(
                color: mine ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
