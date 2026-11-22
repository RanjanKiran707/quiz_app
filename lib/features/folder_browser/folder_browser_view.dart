import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/failure_messages.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/features/folder_browser/folder_browser_view_model.dart';
import 'package:quiz_app/features/import/import_view.dart';
import 'package:quiz_app/features/quiz_detail/quiz_detail_view.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:quiz_app/features/import/import_view_model.dart';
import 'package:quiz_app/features/quiz_detail/quiz_detail_view_model.dart';

class FolderBrowserView extends StatefulWidget {
  final FolderBrowserBundle bundle;
  final FolderBrowserViewModel? viewModel;

  const FolderBrowserView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  static Future<void> open(
    BuildContext context,
    FolderBrowserBundle bundle,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FolderBrowserView(bundle: bundle)),
    );
  }

  @override
  State<FolderBrowserView> createState() => _FolderBrowserViewState();
}

class _FolderBrowserViewState extends State<FolderBrowserView> {
  late final FolderBrowserViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = widget.viewModel ??
        FolderBrowserViewModel(
          bundle: widget.bundle,
          listFolderContents: deps.listFolderContents,
          createFolder: deps.createFolder,
          renameFolder: deps.renameFolder,
          deleteFolder: deps.deleteFolder,
          deleteQuiz: deps.deleteQuiz,
          getFolderDeletePreview: deps.getFolderDeletePreview,
        );
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  bool get _isRoot => widget.bundle.folderId == null;

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<FolderContentsModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => _shell(
          title: _isRoot ? 'All folders' : 'Folder',
          body: const SkeletonList(),
        ),
        error: (failure) => _shell(
          title: _isRoot ? 'All folders' : 'Folder',
          body: ErrorState(failure: failure, onRetry: ctrl.refresh),
        ),
        loaded: _buildLoaded,
      ),
    );
  }

  Widget _shell({
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: AppBar(
        leading: _isRoot ? null : const BackButton(),
        title: Text(title),
        actions: [...?actions, const ThemeModeSwitch()],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildLoaded(FolderContentsModel data) {
    final folder = data.folder;
    final folders = data.folders;
    final quizzes = data.quizzes;
    final isEmpty = folders.isEmpty && quizzes.isEmpty;

    final actions = <Widget>[
      if (folder != null)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'rename') {
              _showNameDialog(folderId: folder.id, initialName: folder.name);
            } else if (value == 'delete') {
              _showDeleteFolder(folder, isCurrent: true);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename folder')),
            PopupMenuItem(value: 'delete', child: Text('Delete folder')),
          ],
        ),
    ];

    return _shell(
      title: folder?.name ?? 'All folders',
      actions: actions,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: context.appAccent,
        foregroundColor: context.appOnAccent,
        child: const Icon(Icons.add),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            if (_isRoot)
              _RootHero(folderCount: folders.length)
            else ...[
              _Breadcrumb(
                path: data.path,
                onOpen: (folderId) => FolderBrowserView.open(
                  context,
                  FolderBrowserBundle(folderId: folderId),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${folders.length} ${folders.length == 1 ? 'folder' : 'folders'}'
                  ' · ${quizzes.length} ${quizzes.length == 1 ? 'quiz' : 'quizzes'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (folders.isNotEmpty) ...[
              SectionHeader('Folders', count: folders.length),
              _Rows(
                children: [
                  for (final item in folders)
                    _FolderRow(
                      folder: item,
                      onOpen: () => FolderBrowserView.open(
                        context,
                        FolderBrowserBundle(folderId: item.id),
                      ),
                      onRename: () => _showNameDialog(
                        folderId: item.id,
                        initialName: item.name,
                      ),
                      onDelete: () => _showDeleteFolder(item),
                    ),
                ],
              ),
            ],
            if (quizzes.isNotEmpty) ...[
              SectionHeader('Quizzes', count: quizzes.length),
              _Rows(
                children: [
                  for (final quiz in quizzes)
                    _QuizRow(
                      quiz: quiz,
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizDetailView(
                            bundle: QuizDetailBundle(quizId: quiz.id),
                          ),
                        ),
                      ),
                      onDelete: () => _showDeleteQuiz(quiz),
                    ),
                ],
              ),
            ],
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 34),
                child: EmptyState(
                  icon: Icons.folder_outlined,
                  title: _isRoot ? 'No folders yet' : 'This folder is empty',
                  message: _isRoot
                      ? 'Folders keep related quizzes together. Create your first one to begin.'
                      : 'Create a sub-folder or import a quiz to get started.',
                  actionLabel: 'New folder',
                  onAction: () => _showNameDialog(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNameDialog({String? folderId, String? initialName}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _FolderNameDialog(
        ctrl: ctrl,
        folderId: folderId,
        initialName: initialName,
      ),
    );
  }

  Future<void> _showDeleteFolder(
    FolderModel folder, {
    bool isCurrent = false,
  }) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteFolderDialog(
        ctrl: ctrl,
        folder: folder,
      ),
    );
    if (deleted == true && isCurrent && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showDeleteQuiz(QuizSummaryModel quiz) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteQuizDialog(ctrl: ctrl, quiz: quiz),
    );
  }

  Future<void> _showAddSheet() async {
    final folder = ctrl.contents?.folder;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                folder == null ? 'Add to library' : 'Add to ${folder.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                folder == null
                    ? 'Create a top-level folder to hold your quizzes.'
                    : 'Create a sub-folder or import one or more quiz files.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.create_new_folder_outlined,
                    color: context.appAccent),
                title: const Text('New folder'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showNameDialog(folderId: folder?.id);
                },
              ),
              if (folder != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.upload_file_outlined, color: context.appAccent),
                  title: const Text('Import quizzes'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImportView(
                          bundle: ImportBundle(folderId: folder.id),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RootHero extends StatelessWidget {
  final int folderCount;

  const _RootHero({required this.folderCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIBRARY',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your library',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Folders and quizzes, kept local and in order.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(
            '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}',
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final List<FolderModel> path;
  final ValueChanged<String> onOpen;

  const _Breadcrumb({required this.path, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _crumb(context, 'All folders', () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }),
          for (var i = 0; i < path.length; i++) ...[
            Icon(Icons.chevron_right, size: 14, color: context.appMuted),
            _crumb(
              context,
              path[i].name,
              i == path.length - 1 ? null : () => onOpen(path[i].id),
              current: i == path.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _crumb(
    BuildContext context,
    String label,
    VoidCallback? onTap, {
    bool current = false,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: current ? context.appInk : context.appMuted,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: current ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  final List<Widget> children;

  const _Rows({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appLine)),
      ),
      child: Column(children: children),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FolderRow({
    required this.folder,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            child: Row(
              children: [
                _RowIcon(icon: Icons.folder_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appInk,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: context.appMuted),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: context.appMuted),
                  onSelected: (value) =>
                      value == 'rename' ? onRename() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'rename', child: Text('Rename folder')),
                    PopupMenuItem(
                        value: 'delete', child: Text('Delete folder')),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(color: context.appLine, height: 1),
      ],
    );
  }
}

class _QuizRow extends StatelessWidget {
  final QuizSummaryModel quiz;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _QuizRow({
    required this.quiz,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = '${quiz.questionCount} '
        '${quiz.questionCount == 1 ? 'question' : 'questions'} · '
        '${quiz.attemptCount == 0 ? 'No attempts' : '${quiz.attemptCount} attempts'}';
    return Column(
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            child: Row(
              children: [
                _RowIcon(icon: Icons.description_outlined, accent: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: context.appInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (quiz.lastScore != null && quiz.lastMaxScore != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ScoreBadge(
                      score: quiz.lastScore!,
                      maxScore: quiz.lastMaxScore!,
                    ),
                  ),
                Icon(Icons.chevron_right,
                    size: 18, color: context.appMuted),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: context.appMuted),
                  onSelected: (_) => onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete quiz')),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(color: context.appLine, height: 1),
      ],
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final bool accent;

  const _RowIcon({required this.icon, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent ? context.appAccentSoft : context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: accent ? context.appAccent : context.appInk,
      ),
    );
  }
}

class _FolderNameDialog extends StatefulWidget {
  final FolderBrowserViewModel ctrl;
  final String? folderId;
  final String? initialName;

  const _FolderNameDialog({
    required this.ctrl,
    this.folderId,
    this.initialName,
  });

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _text;
  var _saving = false;
  String? _error;

  bool get _isRename => widget.folderId != null;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final name = _text.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the folder a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = _isRename
        ? await widget.ctrl.renameFolder(widget.folderId!, name)
        : await widget.ctrl.createFolder(name);

    if (result case Err(:final failure)) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = messageFor(failure);
        });
      }
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isRename ? 'Rename folder' : 'New folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRename
                ? 'Give the folder a clear, short name.'
                : 'Create a folder in this location.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            autofocus: true,
            enabled: !_saving,
            maxLength: 60,
            decoration: appInputDecoration(context, hint: 'Folder name'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 11.5, color: context.appDanger),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: appPrimaryButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(96, 42)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isRename ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

class _DeleteFolderDialog extends StatefulWidget {
  final FolderBrowserViewModel ctrl;
  final FolderModel folder;

  const _DeleteFolderDialog({required this.ctrl, required this.folder});

  @override
  State<_DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<_DeleteFolderDialog> {
  ViewState<FolderDeletePreviewModel> _state = const ViewStateLoading();
  var _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.ctrl.deletePreview(widget.folder.id);
    if (!mounted) return;
    setState(() {
      _state = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
  }

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    final result = await widget.ctrl.deleteFolder(widget.folder.id);
    if (result case Err(:final failure)) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = messageFor(failure);
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete "${widget.folder.name}"?'),
      content: _state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (failure) => Text(messageFor(failure)),
        loaded: (preview) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This removes the folder and everything inside it. This cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appDangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${preview.folders} sub-folders · ${preview.quizzes} quizzes · ${preview.attempts} attempts',
                style: TextStyle(fontSize: 11.5, color: context.appDanger),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 11.5, color: context.appDanger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _state is ViewStateLoaded && !_deleting ? _delete : null,
          style: appDangerButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(120, 42)),
          ),
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete folder'),
        ),
      ],
    );
  }
}

class _DeleteQuizDialog extends StatefulWidget {
  final FolderBrowserViewModel ctrl;
  final QuizSummaryModel quiz;

  const _DeleteQuizDialog({required this.ctrl, required this.quiz});

  @override
  State<_DeleteQuizDialog> createState() => _DeleteQuizDialogState();
}

class _DeleteQuizDialogState extends State<_DeleteQuizDialog> {
  var _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    final result = await widget.ctrl.deleteQuiz(widget.quiz.id);
    if (result case Err(:final failure)) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = messageFor(failure);
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete "${widget.quiz.title}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The quiz and its history will be removed. This cannot be undone.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appDangerSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.quiz.questionCount} questions · ${widget.quiz.attemptCount} attempts',
              style: TextStyle(fontSize: 11.5, color: context.appDanger),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 11.5, color: context.appDanger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _delete,
          style: appDangerButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(110, 42)),
          ),
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete quiz'),
        ),
      ],
    );
  }
}
