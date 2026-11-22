import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/failure_messages.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/features/attempt/attempt_view_model.dart';
import 'package:quiz_app/features/result/result_view.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_return_model.dart';
import 'package:quiz_app/features/result/result_view_model.dart';

class AttemptView extends StatefulWidget {
  final AttemptBundle bundle;
  final AttemptViewModel? viewModel;

  const AttemptView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  @override
  State<AttemptView> createState() => _AttemptViewState();
}

class _AttemptViewState extends State<AttemptView> {
  late final AttemptViewModel ctrl;
  final ScrollController _scroll = ScrollController();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = widget.viewModel ??
        AttemptViewModel(
          bundle: widget.bundle,
          getQuizScreen: deps.getQuizScreen,
          completeAttempt: deps.completeAttempt,
        );
  }

  @override
  void dispose() {
    _scroll.dispose();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<QuizScreenModel>>(
      listenable: ctrl.loadState,
      builder: (state) => state.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Attempt'),
          ),
          body: const SkeletonList(),
        ),
        error: (failure) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Attempt'),
          ),
          body: ErrorState(failure: failure, onRetry: ctrl.refresh),
        ),
        loaded: (data) => ObxValue<AttemptPhase>(
          listenable: ctrl.phase,
          builder: (phase) => phase == AttemptPhase.preStart
              ? _buildPreStart(data.detail)
              : _buildRunning(data.detail),
        ),
      ),
    );
  }

  Widget _buildPreStart(QuizDetailModel detail) {
    final quiz = detail.quiz;
    final questions = detail.questions;
    final totalMarks =
        questions.fold<int>(0, (sum, question) => sum + question.marks);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Attempt'),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
          Text(quiz.title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill('${questions.length} questions'),
              _Pill('$totalMarks marks'),
              const _Pill('Unlimited attempts'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you start',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _Rule(
                  icon: Icons.timer_outlined,
                  text: 'The timer starts when you press Start.',
                ),
                _Rule(
                  icon: Icons.visibility_off_outlined,
                  text: 'Questions stay hidden until then.',
                ),
                _Rule(
                  icon: Icons.checklist_outlined,
                  text:
                      'MSQ is all-or-nothing. Unanswered questions score zero.',
                ),
                _Rule(
                  icon: Icons.check_circle_outline,
                  text:
                      'Press End when you are done; the attempt is saved to history.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: ctrl.start,
            icon: const Icon(Icons.play_arrow, size: 19),
            label: const Text('Start'),
            style: appPrimaryButtonStyle(context),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: appSecondaryButtonStyle(context),
            child: const Text('Cancel'),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunning(QuizDetailModel detail) {
    final total = detail.questions.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _confirmDiscard,
            icon: const Icon(Icons.close),
            tooltip: 'Close attempt',
          ),
          title: ObxValue<String>(
            listenable: ctrl.elapsed,
            builder: (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: context.appMuted),
                  const SizedBox(width: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _confirmEnd,
              child: const Text('End'),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageBody(
                    child: ObxValue<int>(
                      listenable: ctrl.answersRevision,
                      builder: (revision) => ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${ctrl.answeredCount} / $total answered',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.appInk,
                                ),
                              ),
                            ),
                            Text(
                              'Take your time',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.appMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: total == 0
                                ? 0
                                : ctrl.answeredCount / total,
                            minHeight: 5,
                            backgroundColor: context.appSurfaceAlt,
                            color: context.appAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < detail.questions.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _QuestionCard(
                              key: ValueKey(detail.questions[i].id),
                              number: i + 1,
                              question: detail.questions[i],
                              answer: ctrl.answers[detail.questions[i].id],
                              onChoose: (optionId) {
                                ctrl.chooseMcq(
                                  detail.questions[i].id,
                                  optionId,
                                );
                                setState(() {});
                              },
                              onToggle: (optionId) {
                                ctrl.toggleMsq(
                                  detail.questions[i].id,
                                  optionId,
                                );
                                setState(() {});
                              },
                              onNumerical: (text) {
                                ctrl.setNumerical(
                                  detail.questions[i].id,
                                  text,
                                );
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 11, 20, 14),
                    decoration: BoxDecoration(
                      color: context.appBg,
                      border: Border(top: BorderSide(color: context.appLine)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${ctrl.answeredCount} of $total answered',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.appMuted,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _saving ? null : _confirmEnd,
                          style: appPrimaryButtonStyle(context).copyWith(
                            minimumSize:
                                const WidgetStatePropertyAll(Size(140, 44)),
                          ),
                          child: const Text('End attempt'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_saving) ...[
              const ModalBarrier(dismissible: false, color: Colors.black38),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Saving attempt…'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEnd() async {
    final detail = ctrl.detail;
    if (detail == null || _saving) return;
    final answered = ctrl.answeredCount;
    final total = detail.questions.length;
    final unanswered = total - answered;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End this attempt?'),
        content: Text(
          'You answered $answered of $total questions.'
          '${unanswered > 0 ? ' $unanswered unanswered ${unanswered == 1 ? 'question' : 'questions'} will score zero.' : ''}',
          style: Theme.of(dialogContext).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: appPrimaryButtonStyle(dialogContext).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(150, 42)),
            ),
            child: const Text('End and see result'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await ctrl.end();
    if (!mounted) return;
    setState(() => _saving = false);

    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageFor(failure))),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultView(
          bundle: ResultBundle(attemptId: result.valueOrNull!.id),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard this attempt?'),
        content: Text(
          'Your answers will not be saved, and no history row will be created.',
          style: Theme.of(dialogContext).textTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: appDangerButtonStyle(dialogContext).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(130, 42)),
            ),
            child: const Text('Discard attempt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ctrl.discard();
    Navigator.pop(context);
  }
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Rule({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.appAccent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.appInk,
              ),
            ),
          ),
        ],
      ),
    );
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

class _QuestionCard extends StatelessWidget {
  final int number;
  final QuestionModel question;
  final dynamic answer;
  final ValueChanged<String> onChoose;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onNumerical;

  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.answer,
    required this.onChoose,
    required this.onToggle,
    required this.onNumerical,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appSurfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.appMuted,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _TypePill(type: question.type),
              const Spacer(),
              Text(
                '${question.marks} ${question.marks == 1 ? 'mark' : 'marks'}',
                style: TextStyle(fontSize: 10.5, color: context.appMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MathText(
            question.prompt,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: context.appInk,
            ),
          ),
          const SizedBox(height: 12),
          if (question.type == QuestionType.numerical)
            _NumericalField(
              key: ValueKey('numeric-${question.id}'),
              question: question,
              initialValue: answer?.toString() ?? '',
              onChanged: onNumerical,
            )
          else
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _OptionTile(
                  option: option,
                  isMsq: question.type == QuestionType.msq,
                  selected: question.type == QuestionType.mcq
                      ? answer == option.id
                      : (answer is List && answer.contains(option.id)),
                  onTap: () => question.type == QuestionType.mcq
                      ? onChoose(option.id)
                      : onToggle(option.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final QuestionType type;

  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    final background = switch (type) {
      QuestionType.mcq => context.appAccentSoft,
      QuestionType.msq => context.appSurfaceAlt,
      QuestionType.numerical => context.appMidSoft,
    };
    final foreground = switch (type) {
      QuestionType.mcq => context.appAccent,
      QuestionType.msq => context.appInk,
      QuestionType.numerical => context.appMid,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: foreground,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuestionOptionModel option;
  final bool isMsq;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isMsq,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.appAccentSoft : context.appSurface,
          border: Border.all(
            color: selected ? context.appAccent : context.appLine,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: selected ? context.appAccent : context.appSurface,
                border: Border.all(
                  color: selected ? context.appAccent : context.appLine,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(isMsq ? 5 : 99),
              ),
              child: selected
                  ? Icon(
                      isMsq ? Icons.check : Icons.circle,
                      size: isMsq ? 12 : 7,
                      color: context.appOnAccent,
                    )
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: MathText(
                option.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.appInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericalField extends StatefulWidget {
  final QuestionModel question;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _NumericalField({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_NumericalField> createState() => _NumericalFieldState();
}

class _NumericalFieldState extends State<_NumericalField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onChanged: widget.onChanged,
      decoration: appInputDecoration(context, hint: 'Enter a number').copyWith(
        suffixText: widget.question.unit,
        hintStyle: TextStyle(fontSize: 13, color: context.appMuted),
      ),
    );
  }
}
