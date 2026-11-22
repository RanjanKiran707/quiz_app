class CompleteAttemptArgumentModel {
  final String quizId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Map<String, dynamic> answers;

  const CompleteAttemptArgumentModel({
    required this.quizId,
    required this.startedAt,
    required this.endedAt,
    required this.answers,
  });
}
