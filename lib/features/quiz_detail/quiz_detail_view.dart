import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/failure_messages.dart';
import 'package:quiz_app/core/utils/format.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/features/attempt/attempt_view.dart';
import 'package:quiz_app/features/quiz_detail/quiz_detail_view_model.dart';
import 'package:quiz_app/features/result/result_view.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_return_model.dart';
import 'package:quiz_app/features/attempt/attempt_view_model.dart';
import 'package:quiz_app/features/result/result_view_model.dart';

class QuizDetailView extends StatefulWidget {
  final QuizDetailBundle bundle;
  final QuizDetailViewModel? viewModel;

  const QuizDetailView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  @override
  State<QuizDetailView> createState() => _QuizDetailViewState();
}

class _QuizDetailViewState extends State<QuizDetailView> {
  late final QuizDetailViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = widget.viewModel ??
        QuizDetailViewModel(
          bundle: widget.bundle,
          getQuizScreen: deps.getQuizScreen,
          deleteQuiz: deps.deleteQuiz,
        );
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<QuizScreenModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Quiz'),
          ),
          body: const SkeletonList(),
        ),
        error: (failure) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Quiz'),
          ),
          body: ErrorState(failure: failure, onRetry: ctrl.refresh),
        ),
        loaded: _buildLoaded,
      ),
    );
  }

  Widget _buildLoaded(QuizScreenModel data) {
    final detail = data.detail;
    final quiz = detail.quiz;
    final questions = detail.questions;
    final attempts = data.attempts;
    final totalMarks =
        questions.fold<int>(0, (sum, question) => sum + question.marks);
    final counts = <QuestionType, int>{};
    for (final question in questions) {
      counts.update(question.type, (value) => value + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Quiz'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (_) => _confirmDelete(data),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete quiz')),
            ],
          ),
        ],
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'QUIZ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          if (quiz.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              quiz.subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill('${questions.length} questions'),
              _Pill('$totalMarks marks'),
              for (final entry in counts.entries)
                _Pill('${entry.value} ${entry.key.label}'),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttemptView(
                  bundle: AttemptBundle(quizId: quiz.id),
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow, size: 19),
            label: const Text('Start attempt'),
            style: appPrimaryButtonStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlimited attempts · the timer starts on Start',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: context.appMuted),
          ),
          SectionHeader('Attempts', count: attempts.length),
          if (attempts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appLine),
              ),
              child: Text(
                'Your first score will appear here after you press End.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.appMuted),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.appLine)),
              ),
              child: Column(
                children: [
                  for (final attempt in attempts)
                    _AttemptRow(attempt: attempt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(QuizScreenModel data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${data.detail.quiz.title}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The quiz and its history will be removed. This cannot be undone.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
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
                '${data.detail.questions.length} questions · ${data.attempts.length} attempts',
                style: TextStyle(fontSize: 11.5, color: context.appDanger),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: appDangerButtonStyle(dialogContext),
            child: const Text('Delete quiz'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ctrl.deleteQuiz();
    if (!mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(failure))),
      );
      return;
    }
    Navigator.pop(context);
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        border: Border.all(color: context.appLine),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w500,
          color: context.appMuted,
        ),
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final AttemptModel attempt;

  const _AttemptRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final percent = percentage(attempt.score, attempt.maxScore);
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultView(
                bundle: ResultBundle(attemptId: attempt.id),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                ScoreBadge(
                  score: attempt.score,
                  maxScore: attempt.maxScore,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.appInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatDurationMs(attempt.durationMs)} · ${formatDateTime(attempt.startedAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: context.appMuted),
              ],
            ),
          ),
        ),
        Divider(color: context.appLine, height: 1),
      ],
    );
  }
}
