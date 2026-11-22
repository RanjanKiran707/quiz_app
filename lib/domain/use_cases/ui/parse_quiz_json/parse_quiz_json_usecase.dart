import 'dart:convert';

import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/ui/parse_quiz_json/quiz_parse_result_model.dart';

class ParseQuizJsonUsecase {
  QuizParseResultModel call(String source) {
    var repaired = _needsRepair(source);
    dynamic decoded;

    try {
      decoded = jsonDecode(repaired ? _repair(source) : source);
    } on FormatException {
      if (!repaired) {
        try {
          decoded = jsonDecode(_repair(source));
          repaired = true;
        } on FormatException {
          return _malformed(false);
        }
      } else {
        return _malformed(true);
      }
    }

    if (decoded is! Map) {
      return const QuizParseResultModel(
        quiz: null,
        errors: ['The file does not contain a quiz object.'],
        repaired: false,
      );
    }

    final map = Map<String, dynamic>.from(decoded);
    final errors = <String>[];
    final title = _asString(map['title']) ?? '';
    if (title.isEmpty) errors.add('The quiz needs a title.');
    if (title.length > 120) {
      errors.add('The quiz title must be 120 characters or fewer.');
    }

    var subtitle = _asString(map['subtitle']);
    if (subtitle != null && subtitle.length > 240) {
      subtitle = subtitle.substring(0, 240);
    }

    final rawQuestions = map['questions'];
    final questionMaps = rawQuestions is List
        ? rawQuestions.whereType<Map>().toList()
        : const <Map>[];
    if (questionMaps.isEmpty) errors.add('This quiz has no questions.');
    if (questionMaps.length > 1000) {
      errors.add('This quiz exceeds 1,000 questions.');
    }

    final questions = <QuestionImportModel>[];
    for (var i = 0; i < questionMaps.length; i++) {
      final questionMap = Map<String, dynamic>.from(questionMaps[i]);
      final questionNumber = i + 1;

      final typeRaw = (_asString(questionMap['t']) ?? '').toUpperCase();
      final type = switch (typeRaw) {
        'MCQ' => QuestionType.mcq,
        'MSQ' => QuestionType.msq,
        'NAT' => QuestionType.numerical,
        _ => null,
      };
      if (type == null) {
        errors.add('Question $questionNumber has an unsupported type.');
        continue;
      }

      final prompt = _asString(questionMap['q']) ?? '';
      if (prompt.isEmpty) {
        errors.add('Question $questionNumber has no question text.');
        continue;
      }

      final difficultyRaw = _asString(questionMap['d'])?.toLowerCase();
      final difficulty = const ['easy', 'medium', 'hard'].contains(difficultyRaw)
          ? difficultyRaw
          : null;
      final explanation = _asString(questionMap['e']);
      final unit = _asString(questionMap['u']);

      var marks = 1;
      final marksRaw = questionMap['marks'];
      if (marksRaw is num) {
        if (marksRaw <= 0) {
          errors.add('Question $questionNumber has an invalid mark value.');
        } else {
          marks = marksRaw.toInt();
        }
      }

      if (type == QuestionType.numerical) {
        final answer = questionMap['a'];
        if (answer is! num) {
          errors.add('Question $questionNumber needs a numeric answer.');
        }
        final toleranceRaw = questionMap['tolerance'];
        final tolerance =
            toleranceRaw is num && toleranceRaw >= 0 ? toleranceRaw.toDouble() : 0.0;
        questions.add(QuestionImportModel(
          prompt: prompt,
          type: type,
          marks: marks,
          position: i,
          difficulty: difficulty,
          explanation: explanation,
          unit: unit,
          numericalAnswer: answer is num ? answer.toDouble() : null,
          tolerance: tolerance,
        ));
        continue;
      }

      final rawOptions =
          questionMap['o'] is List ? questionMap['o'] as List : const [];
      if (rawOptions.length < 2) {
        errors.add('Question $questionNumber needs at least two options.');
      }

      final seen = <String>{};
      final options = <OptionImportModel>[];
      for (var j = 0; j < rawOptions.length; j++) {
        final text = _asString(rawOptions[j]) ?? '';
        if (text.isEmpty) {
          errors.add('Question $questionNumber has an empty option.');
        }
        if (text.isNotEmpty && !seen.add(text.toLowerCase())) {
          errors.add('Question $questionNumber has a repeated option.');
        }
        options.add(OptionImportModel(text: text, isCorrect: false, position: j));
      }

      final answer = questionMap['a'];
      if (type == QuestionType.mcq) {
        if (answer is! int || answer < 0 || answer >= options.length) {
          errors.add(
            'Question $questionNumber must have exactly one correct option.',
          );
        } else {
          options[answer] = OptionImportModel(
            text: options[answer].text,
            isCorrect: true,
            position: answer,
          );
        }
      } else {
        final indices =
            answer is List ? answer.whereType<int>().toList() : const <int>[];
        final valid = indices.isNotEmpty &&
            indices.every((index) => index >= 0 && index < options.length) &&
            indices.toSet().length == indices.length;
        if (!valid) {
          errors.add(
            'Question $questionNumber must have at least one correct option.',
          );
        } else {
          for (final index in indices) {
            options[index] = OptionImportModel(
              text: options[index].text,
              isCorrect: true,
              position: index,
            );
          }
        }
      }

      questions.add(QuestionImportModel(
        prompt: prompt,
        type: type,
        marks: marks,
        position: i,
        difficulty: difficulty,
        explanation: explanation,
        unit: unit,
        options: options,
      ));
    }

    return QuizParseResultModel(
      quiz: QuizImportModel(
        title: title,
        subtitle: subtitle,
        sourceKey: _asString(map['key']),
        questions: questions,
      ),
      errors: errors.toSet().toList(),
      repaired: repaired,
    );
  }

  QuizParseResultModel _malformed(bool repaired) => QuizParseResultModel(
        quiz: null,
        errors: const ['This file contains malformed JSON.'],
        repaired: repaired,
      );

  String? _asString(Object? value) =>
      value is String ? value.trim() : null;

  static final _invalidEscape =
      RegExp(r'(^|[^\\])\\(?!["\\/bfnrtu])');
  static final _latexCommand = RegExp(
    r'(^|[^\\])\\(?:times|text|frac|sqrt|le|ge|neq|pm|cdot|pi|alpha|beta|gamma|theta|lambda|sigma|omega|left|right|begin|end)\b',
  );

  bool _needsRepair(String source) =>
      _invalidEscape.hasMatch(source) || _latexCommand.hasMatch(source);

  String _repair(String source) {
    final out = StringBuffer();
    var inString = false;

    for (var i = 0; i < source.length; i++) {
      final character = source[i];
      if (!inString) {
        out.write(character);
        if (character == '"') inString = true;
        continue;
      }

      if (character == '\\') {
        final next = i + 1 < source.length ? source[i + 1] : '';
        if (next == '"' || next == '\\') {
          out.write('\\');
          out.write(next);
          i++;
        } else {
          out.write('\\\\');
        }
        continue;
      }

      out.write(character);
      if (character == '"') inString = false;
    }

    return out.toString();
  }
}
