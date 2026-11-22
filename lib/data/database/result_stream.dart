import 'dart:async';

import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';

/// Converts a Drift watch stream into a stream of [Result] values.
/// Storage errors become an [Err] instead of closing the stream silently.
Stream<Result<T>> resultStream<T, R>(
  Stream<List<R>> stream,
  T Function(List<R> rows) mapper,
) {
  return stream.transform(
    StreamTransformer<List<R>, Result<T>>.fromHandlers(
      handleData: (rows, sink) => sink.add(Ok(mapper(rows))),
      handleError: (error, stackTrace, sink) =>
          sink.add(Err(StorageFailure(error.toString()))),
    ),
  );
}
