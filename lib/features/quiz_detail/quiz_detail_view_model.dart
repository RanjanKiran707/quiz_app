import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/domain/use_cases/business/delete_quiz/delete_quiz_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_usecase.dart';

class QuizDetailBundle {
  final String quizId;

  const QuizDetailBundle({required this.quizId});
}

class QuizDetailViewModel {
  QuizDetailViewModel({
    required this.bundle,
    required GetQuizScreenUsecase getQuizScreen,
    required DeleteQuizUsecase deleteQuiz,
  })  : _getQuizScreen = getQuizScreen,
        _deleteQuiz = deleteQuiz {
    _subscribe();
  }

  final QuizDetailBundle bundle;
  final GetQuizScreenUsecase _getQuizScreen;
  final DeleteQuizUsecase _deleteQuiz;

  final ValueNotifier<ViewState<QuizScreenModel>> state =
      ValueNotifier(const ViewStateLoading());
  final ValueNotifier<ViewState<void>> actionState =
      ValueNotifier(const ViewStateIdle());

  StreamSubscription<Result<QuizScreenModel>>? _subscription;

  QuizScreenModel? get screen =>
      state.value is ViewStateLoaded<QuizScreenModel>
          ? (state.value as ViewStateLoaded<QuizScreenModel>).data
          : null;

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _getQuizScreen(bundle.quizId).listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
  }

  void refresh() {
    state.value = const ViewStateLoading();
    _subscribe();
  }

  Future<Result<void>> deleteQuiz() async {
    if (actionState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    actionState.value = const ViewStateLoading();
    final result = await _deleteQuiz(bundle.quizId);
    actionState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result;
  }

  void dispose() {
    _subscription?.cancel();
    state.dispose();
    actionState.dispose();
  }
}
