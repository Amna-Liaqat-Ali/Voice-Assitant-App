enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;

  const ChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role.name, 'text': text};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
    text: json['text'] as String,
  );
}
