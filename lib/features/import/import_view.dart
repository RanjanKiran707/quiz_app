import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/failure_messages.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/features/import/import_view_model.dart';
import 'package:quiz_app/features/quiz_detail/quiz_detail_view.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/features/quiz_detail/quiz_detail_view_model.dart';

class ImportView extends StatefulWidget {
  final ImportBundle bundle;
  final ImportViewModel? viewModel;

  const ImportView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  late final ImportViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = widget.viewModel ??
        ImportViewModel(
          bundle: widget.bundle,
          getFolder: deps.getFolder,
          parseQuizJson: deps.parseQuizJson,
          importQuizzes: deps.importQuizzes,
        );
    ctrl.load();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<FolderModel?>>(
      listenable: ctrl.folderState,
      builder: (state) => state.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Import'),
          ),
          body: const SkeletonList(rows: 3),
        ),
        error: (failure) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Import'),
          ),
          body: ErrorState(failure: failure, onRetry: ctrl.load),
        ),
        loaded: _buildLoaded,
      ),
    );
  }

  Widget _buildLoaded(FolderModel? folder) {
    return ObxMulti(
      listenables: [ctrl.files, ctrl.reading, ctrl.importState],
      builder: () {
        final files = ctrl.files.value;
        final valid = files.where((file) => file.isValid).toList();
        final invalid = files.where((file) => !file.isValid).toList();
        final importing = ctrl.importState.value.isLoading;
        final reading = ctrl.reading.value;

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Import'),
          ),
          body: PageBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: context.appSurfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 16, color: context.appAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import into ${folder?.name ?? 'folder'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (files.isEmpty)
                _Dropzone(
                  reading: reading,
                  onChoose: _pickFiles,
                )
              else ...[
                _AddMoreCard(onChoose: _pickFiles, reading: reading),
                if (reading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Reading and validating files…',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                for (final file in files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _FileCard(
                      file: file,
                      onRemove: () => ctrl.removeFile(file.id),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${valid.length} valid'
                          '${invalid.isEmpty ? '' : ' · ${invalid.length} skipped'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appMuted,
                          ),
                        ),
                      ),
                      Text(
                        '${valid.fold<int>(0, (sum, file) => sum + file.quiz!.questions.length)} questions',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ],
            ),
          ),
          bottomNavigationBar: files.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    decoration: BoxDecoration(
                      color: context.appBg,
                      border: Border(top: BorderSide(color: context.appLine)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${files.length} ${files.length == 1 ? 'file' : 'files'}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.appMuted,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: valid.isEmpty || reading || importing
                              ? null
                              : _import,
                          style: appPrimaryButtonStyle(context).copyWith(
                            minimumSize:
                                const WidgetStatePropertyAll(Size(170, 46)),
                          ),
                          child: importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  'Import ${valid.length} '
                                  '${valid.length == 1 ? 'quiz' : 'quizzes'}',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    if (ctrl.reading.value || ctrl.importState.value.isLoading) return;
    try {
      final picked = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked.isEmpty) return;

      var files = picked;
      if (files.length + ctrl.files.value.length > 50) {
        _snack('You can add up to 50 files at a time.');
        files = files.take(50 - ctrl.files.value.length).toList();
      }

      final sizes = <int>[];
      for (final file in files) {
        sizes.add(file.lengthSync() ?? await file.length() ?? 0);
      }
      final total = sizes.fold<int>(0, (sum, size) => sum + size) +
          ctrl.files.value.fold<int>(0, (sum, file) => sum + file.size);
      if (total > 20 * 1024 * 1024) {
        _snack('The batch is larger than 20 MB.');
        return;
      }

      ctrl.setReading(true);
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          final bytes = await file.readAsBytes();
          ctrl.addTextFile(
            name: file.name,
            size: sizes[i],
            text: utf8.decode(bytes, allowMalformed: true),
          );
        } catch (error) {
          _snack('${file.name} could not be read.');
        }
      }
      ctrl.setReading(false);
    } catch (error) {
      ctrl.setReading(false);
      _snack('Could not open the file picker.');
    }
  }

  Future<void> _import() async {
    final result = await ctrl.importAll();
    if (!mounted) return;
    if (result case Err(:final failure)) {
      _snack(messageFor(failure));
      return;
    }
    final ids = result.valueOrNull ?? const <String>[];
    if (ids.isEmpty) return;
    if (ids.length == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizDetailView(
            bundle: QuizDetailBundle(quizId: ids.first),
          ),
        ),
      );
      return;
    }
    _snack('${ids.length} quizzes imported');
    Navigator.pop(context);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Dropzone extends StatelessWidget {
  final bool reading;
  final VoidCallback onChoose;

  const _Dropzone({required this.reading, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appLine, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.appAccentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.upload_file,
                color: context.appAccent, size: 24),
          ),
          const SizedBox(height: 13),
          Text(
            'Choose JSON files',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'One or more quiz files · .json · max 5 MB each',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 15),
          FilledButton(
            onPressed: reading ? null : onChoose,
            style: appPrimaryButtonStyle(context).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(160, 46)),
            ),
            child: const Text('Choose files'),
          ),
        ],
      ),
    );
  }
}

class _AddMoreCard extends StatelessWidget {
  final VoidCallback onChoose;
  final bool reading;

  const _AddMoreCard({required this.onChoose, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add more files',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Drop files here or choose again',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: reading ? null : onChoose,
          style: appSecondaryButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(88, 36)),
          ),
          child: const Text('Choose'),
        ),
      ],
    );
  }
}

class _FileCard extends StatelessWidget {
  final ImportFile file;
  final VoidCallback onRemove;

  const _FileCard({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final quiz = file.quiz;
    final counts = <QuestionType, int>{};
    if (quiz != null) {
      for (final question in quiz.questions) {
        counts.update(question.type, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final marks = quiz?.questions.fold<int>(
          0,
          (sum, question) => sum + question.marks,
        ) ??
        0;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 9, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: file.isValid ? context.appLine : context.appDanger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: file.isValid
                      ? context.appGoodSoft
                      : context.appDangerSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  file.isValid
                      ? Icons.description_outlined
                      : Icons.error_outline,
                  size: 16,
                  color: file.isValid ? context.appGood : context.appDanger,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appInk,
                      ),
                    ),
                    Text(
                      _bytes(file.size),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(valid: file.isValid),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (quiz != null) ...[
            const SizedBox(height: 9),
            Text(
              quiz.title.isEmpty ? 'Untitled quiz' : quiz.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appInk,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${quiz.questions.length} questions · $marks marks'
              '${counts.isEmpty ? '' : ' · ${counts.entries.map((entry) => '${entry.value} ${entry.key.label}').join(' · ')}'}',
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
            if (file.repaired) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appMidSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Backslashes were repaired so the math stays intact. Regenerate this file as valid JSON when you can.',
                  style: TextStyle(fontSize: 10.8, color: context.appMid),
                ),
              ),
            ],
          ],
          if (!file.isValid) ...[
            const SizedBox(height: 8),
            for (final error in file.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $error',
                  style: TextStyle(fontSize: 11, color: context.appDanger),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _bytes(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatusChip extends StatelessWidget {
  final bool valid;

  const _StatusChip({required this.valid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: valid ? context.appGoodSoft : context.appDangerSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        valid ? 'VALID' : 'NEEDS FIXES',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: valid ? context.appGood : context.appDanger,
        ),
      ),
    );
  }
}
