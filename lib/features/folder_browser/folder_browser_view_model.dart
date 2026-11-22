import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/delete_quiz/delete_quiz_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_folder_delete_preview/get_folder_delete_preview_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';

class FolderBrowserBundle {
  final String? folderId;

  const FolderBrowserBundle({this.folderId});
}

class FolderBrowserViewModel {
  FolderBrowserViewModel({
    required this.bundle,
    required ListFolderContentsUsecase listFolderContents,
    required CreateFolderUsecase createFolder,
    required RenameFolderUsecase renameFolder,
    required DeleteFolderUsecase deleteFolder,
    required DeleteQuizUsecase deleteQuiz,
    required GetFolderDeletePreviewUsecase getFolderDeletePreview,
  })  : _listFolderContents = listFolderContents,
        _createFolder = createFolder,
        _renameFolder = renameFolder,
        _deleteFolder = deleteFolder,
        _deleteQuiz = deleteQuiz,
        _getFolderDeletePreview = getFolderDeletePreview {
    _subscribe();
  }

  final FolderBrowserBundle bundle;
  final ListFolderContentsUsecase _listFolderContents;
  final CreateFolderUsecase _createFolder;
  final RenameFolderUsecase _renameFolder;
  final DeleteFolderUsecase _deleteFolder;
  final DeleteQuizUsecase _deleteQuiz;
  final GetFolderDeletePreviewUsecase _getFolderDeletePreview;

  final ValueNotifier<ViewState<FolderContentsModel>> state =
      ValueNotifier(const ViewStateLoading());
  final ValueNotifier<ViewState<void>> actionState =
      ValueNotifier(const ViewStateIdle());

  StreamSubscription<Result<FolderContentsModel>>? _subscription;

  FolderContentsModel? get contents =>
      state.value is ViewStateLoaded<FolderContentsModel>
          ? (state.value as ViewStateLoaded<FolderContentsModel>).data
          : null;

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _listFolderContents(bundle.folderId).listen((result) {
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

  Future<Result<FolderModel>> createFolder(String name) async {
    if (actionState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    actionState.value = const ViewStateLoading();
    final result = await _createFolder(
      CreateFolderArgumentModel(parentId: bundle.folderId, name: name),
    );
    actionState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result;
  }

  Future<Result<void>> renameFolder(String id, String name) async {
    if (actionState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    actionState.value = const ViewStateLoading();
    final result = await _renameFolder(
      RenameFolderArgumentModel(id: id, name: name),
    );
    actionState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    if (result is Ok<void>) refresh();
    return result;
  }

  Future<Result<void>> deleteFolder(String id) async {
    if (actionState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    actionState.value = const ViewStateLoading();
    final result = await _deleteFolder(id);
    actionState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result;
  }

  Future<Result<void>> deleteQuiz(String id) async {
    if (actionState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    actionState.value = const ViewStateLoading();
    final result = await _deleteQuiz(id);
    actionState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result;
  }

  Future<Result<FolderDeletePreviewModel>> deletePreview(String id) =>
      _getFolderDeletePreview(id);

  void resetActionState() {
    if (!actionState.value.isLoading) {
      actionState.value = const ViewStateIdle();
    }
  }

  void dispose() {
    _subscription?.cancel();
    state.dispose();
    actionState.dispose();
  }
}
