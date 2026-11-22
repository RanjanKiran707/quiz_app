import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/format.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_usecase.dart';

class AttemptBundle {
  final String quizId;

  const AttemptBundle({required this.quizId});
}

enum AttemptPhase { preStart, running }

class AttemptViewModel {
  AttemptViewModel({
    required this.bundle,
    required GetQuizScreenUsecase getQuizScreen,
    required CompleteAttemptUsecase completeAttempt,
  })  : _getQuizScreen = getQuizScreen,
        _completeAttempt = completeAttempt {
    _subscribe();
  }

  final AttemptBundle bundle;
  final GetQuizScreenUsecase _getQuizScreen;
  final CompleteAttemptUsecase _completeAttempt;

  final ValueNotifier<ViewState<QuizScreenModel>> loadState =
      ValueNotifier(const ViewStateLoading());
  final ValueNotifier<AttemptPhase> phase =
      ValueNotifier(AttemptPhase.preStart);
  final ValueNotifier<String> elapsed = ValueNotifier('00:00');
  final ValueNotifier<int> answersRevision = ValueNotifier(0);
  final ValueNotifier<ViewState<void>> saveState =
      ValueNotifier(const ViewStateIdle());

  final Map<String, dynamic> answers = {};

  StreamSubscription<Result<QuizScreenModel>>? _subscription;
  QuizDetailModel? _detail;
  DateTime? _startedAt;
  Timer? _timer;

  QuizDetailModel? get detail => _detail;

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _getQuizScreen(bundle.quizId).listen((result) {
      loadState.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
      _detail = result.valueOrNull?.detail;
    });
  }

  void refresh() {
    loadState.value = const ViewStateLoading();
    _subscribe();
  }

  void start() {
    if (_detail == null || phase.value == AttemptPhase.running) return;
    _startedAt = DateTime.now();
    phase.value = AttemptPhase.running;
    _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    elapsed.value = formatClock(DateTime.now().difference(startedAt));
  }

  void chooseMcq(String questionId, String optionId) {
    answers[questionId] = optionId;
    answersRevision.value++;
  }

  void toggleMsq(String questionId, String optionId) {
    final selected = (answers[questionId] as List?)?.cast<String>().toList() ??
        <String>[];
    if (selected.contains(optionId)) {
      selected.remove(optionId);
    } else {
      selected.add(optionId);
    }
    answers[questionId] = selected;
    answersRevision.value++;
  }

  void setNumerical(String questionId, String text) {
    answers[questionId] = text;
    answersRevision.value++;
  }

  bool isAnswered(QuestionModel question) {
    final answer = answers[question.id];
    return switch (question.type) {
      QuestionType.numerical => (answer?.toString() ?? '').trim().isNotEmpty,
      QuestionType.msq => answer is List && answer.isNotEmpty,
      QuestionType.mcq => answer is String && answer.isNotEmpty,
    };
  }

  int get answeredCount {
    final detail = _detail;
    if (detail == null) return 0;
    return detail.questions.where(isAnswered).length;
  }

  Future<Result<AttemptModel>> end() async {
    if (saveState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    final startedAt = _startedAt;
    final detail = _detail;
    if (startedAt == null || detail == null) {
      return const Err(StorageFailure('attempt_not_started'));
    }

    saveState.value = const ViewStateLoading();
    final result = await _completeAttempt(
      CompleteAttemptArgumentModel(
        quizId: bundle.quizId,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        answers: Map<String, dynamic>.from(answers),
      ),
    );
    saveState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    if (result is Ok<AttemptModel>) {
      _timer?.cancel();
      _timer = null;
    }
    return result;
  }

  void discard() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    answers.clear();
    answersRevision.value++;
    phase.value = AttemptPhase.preStart;
  }

  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    loadState.dispose();
    phase.dispose();
    elapsed.dispose();
    answersRevision.dispose();
    saveState.dispose();
  }
}
