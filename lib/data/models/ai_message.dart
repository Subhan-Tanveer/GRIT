enum AiRole { user, coach }

class AiMessage {
  final int? id;
  final AiRole role;
  final String content;
  final String createdAt;

  const AiMessage({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessage.fromMap(Map<String, dynamic> m) => AiMessage(
        id: m['id'] as int?,
        role: (m['role'] as String) == 'user' ? AiRole.user : AiRole.coach,
        content: m['content'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'role': role == AiRole.user ? 'user' : 'coach',
        'content': content,
      };
}
