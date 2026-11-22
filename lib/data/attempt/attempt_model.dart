import 'package:quiz_app/data/database/app_database.dart';

class AttemptModel {
  final String id;
  final String quizId;
  final String startedAt;
  final String endedAt;
  final int durationMs;
  final int score;
  final int maxScore;
  final String answersJson;

  const AttemptModel({
    required this.id,
    required this.quizId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.score,
    required this.maxScore,
    required this.answersJson,
  });

  factory AttemptModel.fromRow(Attempt row) => AttemptModel(
        id: row.id,
        quizId: row.quizId,
        startedAt: row.startedAt,
        endedAt: row.endedAt,
        durationMs: row.durationMs,
        score: row.score,
        maxScore: row.maxScore,
        answersJson: row.answersJson,
      );

  AttemptsCompanion toCompanion() => AttemptsCompanion.insert(
        id: id,
        quizId: quizId,
        startedAt: startedAt,
        endedAt: endedAt,
        durationMs: durationMs,
        score: score,
        maxScore: maxScore,
        answersJson: answersJson,
      );
}
