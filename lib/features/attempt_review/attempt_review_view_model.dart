import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_usecase.dart';

class AttemptReviewBundle {
  final String attemptId;

  const AttemptReviewBundle({required this.attemptId});
}

class AttemptReviewViewModel {
  AttemptReviewViewModel({
    required this.bundle,
    required GetAttemptReviewUsecase getAttemptReview,
  }) : _getAttemptReview = getAttemptReview;

  final AttemptReviewBundle bundle;
  final GetAttemptReviewUsecase _getAttemptReview;

  final ValueNotifier<ViewState<AttemptReviewModel>> state =
      ValueNotifier(const ViewStateLoading());

  Future<void> load() async {
    state.value = const ViewStateLoading();
    final result = await _getAttemptReview(bundle.attemptId);
    state.value = result.fold(
      (failure) => ViewStateError(failure),
      (data) => ViewStateLoaded(data),
    );
  }

  void dispose() {
    state.dispose();
  }
}
