import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/ai_message.dart';
import '../../providers/ai_coach_provider.dart';
import '../../utils/ai_coach_engine.dart';

/// Reusable chat UI for the GRIT AI Coach — used both as a full screen and
/// embedded in the global floating-assistant bottom sheet.
class AiCoachPanel extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const AiCoachPanel({super.key, this.scrollController});

  @override
  ConsumerState<AiCoachPanel> createState() => _AiCoachPanelState();
}

class _AiCoachPanelState extends ConsumerState<AiCoachPanel> {
  final _inputController = TextEditingController();
  late final ScrollController _ownedScrollController;

  ScrollController get _scrollController => widget.scrollController ?? _ownedScrollController;

  @override
  void initState() {
    super.initState();
    _ownedScrollController = ScrollController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _ownedScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    GritHaptics.selectionTick();
    _scrollToBottom();
    await ref.read(aiCoachActionsProvider).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(aiMessagesProvider);
    final isTyping = ref.watch(isCoachTypingProvider);

    ref.listen(aiMessagesProvider, (_, __) => _scrollToBottom());

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const SizedBox(),
            error: (e, st) => Center(
              child: Text('Failed to load conversation',
                  style: GritTextStyles.label(13, color: Theme.of(context).grit.textSecondary)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return _emptyState(context);
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _typingIndicator(context);
                  }
                  return _messageBubble(context, messages[index]);
                },
              );
            },
          ),
        ),
        _inputBar(context),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 48, color: grit.accent),
          const SizedBox(height: 16),
          Text(
            "Ask me anything about your training, or how to use the app — I'll walk you through it step by step.",
            textAlign: TextAlign.center,
            style: GritTextStyles.label(14, color: grit.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: QuickQuestion.values.map((q) => _quickChip(context, q)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(BuildContext context, QuickQuestion q) {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: () {
        GritHaptics.selectionTick();
        _scrollToBottom();
        ref.read(aiCoachActionsProvider).askQuickQuestion(q);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: grit.surface,
          border: Border.all(color: grit.border),
        ),
        child: Text(q.label, style: GritTextStyles.label(12, color: grit.textPrimary)),
      ),
    );
  }

  Widget _messageBubble(BuildContext context, AiMessage message) {
    final grit = Theme.of(context).grit;
    final isUser = message.role == AiRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? grit.accent : grit.surface,
          border: isUser ? null : Border.all(color: grit.border),
        ),
        child: isUser
            ? Text(
                message.content,
                style: GritTextStyles.label(13, color: Colors.white, height: 1.4),
              )
            : MarkdownBody(
                data: _sanitizeMarkdown(message.content),
                styleSheet: _markdownStyleSheet(grit),
                shrinkWrap: true,
              ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }

  /// Strips stray leading punctuation/artifacts some LLM responses produce
  /// before the actual markdown content (e.g. a lone ")##" prefix).
  String _sanitizeMarkdown(String content) {
    return content.replaceFirst(RegExp(r'^[^\w#*\-]+(?=[#*\-\w])'), '').trimLeft();
  }

  MarkdownStyleSheet _markdownStyleSheet(GritThemeData grit) {
    final base = GritTextStyles.label(13, color: grit.textPrimary, height: 1.4);
    return MarkdownStyleSheet(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.w800, color: grit.textPrimary),
      em: base.copyWith(fontStyle: FontStyle.italic),
      listBullet: base,
      h1: GritTextStyles.label(16, weight: FontWeight.w800, color: grit.accent),
      h2: GritTextStyles.label(15, weight: FontWeight.w800, color: grit.accent),
      h3: GritTextStyles.label(14, weight: FontWeight.w700, color: grit.accent),
      code: GritTextStyles.mono(12, color: grit.accent),
      codeblockDecoration: BoxDecoration(color: grit.surface2, border: Border.all(color: grit.border)),
      blockSpacing: 8,
      listIndent: 18,
    );
  }

  Widget _typingIndicator(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(width: 6, height: 6, decoration: BoxDecoration(color: grit.textSecondary, shape: BoxShape.circle))
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 400.ms, delay: (i * 150).ms)
                  .then()
                  .fadeOut(duration: 400.ms),
            );
          }),
        ),
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border(top: BorderSide(color: grit.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: GritTextStyles.label(13, color: grit.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask GRIT AI...',
                hintStyle: GritTextStyles.label(13, color: grit.muted),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_inputController.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: grit.accent),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
