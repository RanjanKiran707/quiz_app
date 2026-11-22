import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/format.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_return_model.dart';
import 'package:quiz_app/features/attempt_review/attempt_review_view_model.dart';

class AttemptReviewView extends StatefulWidget {
  final AttemptReviewBundle bundle;
  final AttemptReviewViewModel? viewModel;

  const AttemptReviewView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  @override
  State<AttemptReviewView> createState() => _AttemptReviewViewState();
}

class _AttemptReviewViewState extends State<AttemptReviewView> {
  late final AttemptReviewViewModel ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = widget.viewModel ??
        AttemptReviewViewModel(
          bundle: widget.bundle,
          getAttemptReview: AppDependencies.instance.getAttemptReview,
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
    return ObxValue<ViewState<AttemptReviewModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Review'),
          ),
          body: const SkeletonList(rows: 5),
        ),
        error: (failure) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Review'),
          ),
          body: ErrorState(failure: failure, onRetry: ctrl.load),
        ),
        loaded: _buildLoaded,
      ),
    );
  }

  Widget _buildLoaded(AttemptReviewModel data) {
    final attempt = data.attempt;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Review'),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'ANSWER REVIEW',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: context.appMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.quiz.title,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatDateTime(attempt.startedAt)} · '
              '${formatDurationMs(attempt.durationMs)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _StatsGrid(data: data),
            SectionHeader('Questions', count: data.reviews.length),
            if (data.reviews.isEmpty)
              const EmptyState(
                icon: Icons.help_outline,
                title: 'No questions to review',
                message: 'This quiz had no questions when the attempt ran.',
              )
            else
              for (var index = 0; index < data.reviews.length; index++)
                _ReviewCard(
                  index: index,
                  review: data.reviews[index],
                ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AttemptReviewModel data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        label: 'Score',
        value: '${data.attempt.score} / ${data.attempt.maxScore}',
        color: context.appInk,
      ),
      _StatData(
        label: 'Correct',
        value: '${data.correctCount}',
        color: context.appGood,
      ),
      _StatData(
        label: 'Wrong',
        value: '${data.incorrectCount}',
        color: context.appDanger,
      ),
      _StatData(
        label: 'Unanswered',
        value: '${data.unansweredCount}',
        color: context.appMid,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final rows = <Widget>[];
        for (var start = 0; start < stats.length; start += columns) {
          final row = <Widget>[];
          for (var index = start;
              index < start + columns && index < stats.length;
              index++) {
            if (row.isNotEmpty) row.add(const SizedBox(width: 8));
            row.add(Expanded(child: _StatCard(data: stats[index])));
          }
          if (row.isNotEmpty) {
            if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
            rows.add(Row(children: row));
          }
        }
        return Column(children: rows);
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: data.color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final AttemptAnswerReviewModel review;

  const _ReviewCard({required this.index, required this.review});

  @override
  Widget build(BuildContext context) {
    final question = review.question;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                (index + 1).toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.appMuted,
                ),
              ),
              const SizedBox(width: 8),
              _TypeChip(type: question.type),
              const SizedBox(width: 7),
              Text(
                '${question.marks} ${question.marks == 1 ? 'mark' : 'marks'}',
                style: TextStyle(fontSize: 10.5, color: context.appMuted),
              ),
              const Spacer(),
              _StatusChip(status: review.status),
            ],
          ),
          const SizedBox(height: 10),
          MathText(
            question.prompt,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: context.appInk,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerLine(
            label: 'Your answer',
            value: review.givenDisplay,
            color: review.isUnanswered
                ? context.appMuted
                : review.isCorrect
                    ? context.appGood
                    : context.appDanger,
          ),
          const SizedBox(height: 7),
          _AnswerLine(
            label: 'Correct answer',
            value: review.correctDisplay,
            color: context.appGood,
          ),
          if ((question.explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.appLine)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: context.appMuted,
                  collapsedIconColor: context.appMuted,
                  title: Text(
                    'Explanation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appMuted,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MathText(
                        question.explanation!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: context.appInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: context.appMuted,
              ),
            ),
          ),
        ),
        Expanded(
          child: MathText(
            value,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final QuestionType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.appAccentSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: context.appAccent,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AnswerReviewStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      AnswerReviewStatus.correct => (
          'Correct',
          context.appGood,
          context.appGoodSoft,
        ),
      AnswerReviewStatus.incorrect => (
          'Incorrect',
          context.appDanger,
          context.appDangerSoft,
        ),
      AnswerReviewStatus.unanswered => (
          'Unanswered',
          context.appMid,
          context.appMidSoft,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: foreground,
        ),
      ),
    );
  }
}
