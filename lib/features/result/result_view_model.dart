import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_usecase.dart';

class ResultBundle {
  final String attemptId;

  const ResultBundle({required this.attemptId});
}

class ResultViewModel {
  ResultViewModel({
    required this.bundle,
    required GetAttemptScreenUsecase getAttemptScreen,
  }) : _getAttemptScreen = getAttemptScreen;

  final ResultBundle bundle;
  final GetAttemptScreenUsecase _getAttemptScreen;

  final ValueNotifier<ViewState<AttemptScreenModel>> state =
      ValueNotifier(const ViewStateLoading());

  Future<void> load() async {
    state.value = const ViewStateLoading();
    final result = await _getAttemptScreen(bundle.attemptId);
    state.value = result.fold(
      (failure) => ViewStateError(failure),
      (data) => ViewStateLoaded(data),
    );
  }

  void dispose() {
    state.dispose();
  }
}
