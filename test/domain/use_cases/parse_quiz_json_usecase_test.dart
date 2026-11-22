import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/ui/parse_quiz_json/parse_quiz_json_usecase.dart';

void main() {
  final parser = ParseQuizJsonUsecase();

  test('parses the real IPv4 sample and repairs LaTeX backslashes', () {
    final source = File('docs/quiz.json').readAsStringSync();
    final result = parser(source);

    expect(result.isValid, isTrue, reason: result.errors.join('\n'));
    expect(result.repaired, isTrue);
    expect(result.quiz?.questions.length, 35);
    expect(result.quiz?.title, contains('Classful IPv4'));

    final types = result.quiz!.questions.map((question) => question.type);
    expect(types.where((type) => type == QuestionType.mcq).length, 15);
    expect(types.where((type) => type == QuestionType.msq).length, 10);
    expect(types.where((type) => type == QuestionType.numerical).length, 10);
  });

  test('rejects the invalid sample with clear errors', () {
    const source = '''
    {
      "title": "",
      "questions": [
        { "t": "MCQ", "q": "Broken", "o": ["Only one"], "a": 5 },
        { "t": "XYZ", "q": "Unknown", "o": ["A", "B"], "a": 0 }
      ]
    }
    ''';

    final result = parser(source);
    expect(result.isValid, isFalse);
    expect(result.errors, contains('The quiz needs a title.'));
    expect(result.errors, contains('Question 1 needs at least two options.'));
    expect(
      result.errors,
      contains('Question 1 must have exactly one correct option.'),
    );
    expect(result.errors, contains('Question 2 has an unsupported type.'));
  });

  test('parses strict JSON without repairing', () {
    const source = '''
    {
      "title": "Strict quiz",
      "questions": [
        {
          "t": "MCQ",
          "q": "Pick one",
          "o": ["A", "B"],
          "a": 0
        }
      ]
    }
    ''';

    final result = parser(source);
    expect(result.isValid, isTrue);
    expect(result.repaired, isFalse);
    expect(result.quiz?.questions.single.options.first.isCorrect, isTrue);
  });

  test('reports malformed JSON', () {
    final result = parser('{"title": "Broken",');
    expect(result.quiz, isNull);
    expect(result.errors, contains('This file contains malformed JSON.'));
  });
}
