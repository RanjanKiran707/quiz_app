import 'dart:async';

/// Emits whenever either stream emits, once both have produced a value.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;
  var doneA = false;
  var doneB = false;

  void emit() {
    if (hasA && hasB) {
      controller.add(combine(latestA as A, latestB as B));
    }
  }

  void closeIfDone() {
    if (doneA && doneB && !controller.isClosed) {
      controller.close();
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = first.listen(
        (value) {
          latestA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
        onDone: () {
          doneA = true;
          closeIfDone();
        },
      );
      subB = second.listen(
        (value) {
          latestB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
        onDone: () {
          doneB = true;
          closeIfDone();
        },
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return controller.stream;
}
