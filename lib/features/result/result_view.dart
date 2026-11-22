import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/format.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';
import 'package:quiz_app/features/attempt/attempt_view.dart';
import 'package:quiz_app/features/result/result_view_model.dart';
import 'package:quiz_app/core/widgets/obx_value.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_return_model.dart';
import 'package:quiz_app/features/attempt/attempt_view_model.dart';

class ResultView extends StatefulWidget {
  final ResultBundle bundle;
  final ResultViewModel? viewModel;

  const ResultView({
    super.key,
    required this.bundle,
    this.viewModel,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  late final ResultViewModel ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = widget.viewModel ??
        ResultViewModel(
          bundle: widget.bundle,
          getAttemptScreen: AppDependencies.instance.getAttemptScreen,
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
    return ObxValue<ViewState<AttemptScreenModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Result'),
          ),
          body: const SkeletonList(rows: 4),
        ),
        error: (failure) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Result'),
          ),
          body: ErrorState(failure: failure, onRetry: ctrl.load),
        ),
        loaded: _buildLoaded,
      ),
    );
  }

  Widget _buildLoaded(AttemptScreenModel data) {
    final attempt = data.attempt;
    final quiz = data.quiz;
    final percent = percentage(attempt.score, attempt.maxScore);
    final ringColor = percent >= 80
        ? context.appGood
        : percent >= 60
            ? context.appMid
            : context.appDanger;
    final message = percent >= 80
        ? 'Excellent work'
        : percent >= 60
            ? 'Good progress'
            : 'Keep practising';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Result'),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Center(
            child: SizedBox(
              width: 158,
              height: 158,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 158,
                    height: 158,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: context.appSurfaceAlt,
                      color: ringColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontFamily: 'InstrumentSerif',
                          fontSize: 42,
                          height: 1,
                          color: context.appInk,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${attempt.score} / ${attempt.maxScore}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ATTEMPT RESULT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 6),
          Text(
            quiz?.title ?? 'Quiz unavailable',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.appGoodSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 13, color: context.appGood),
                  const SizedBox(width: 5),
                  Text(
                    'Saved to history',
                    style: TextStyle(fontSize: 11, color: context.appGood),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Score',
                  value: '${attempt.score} / ${attempt.maxScore}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(label: 'Accuracy', value: '$percent%'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Time taken',
                  value: formatDurationMs(attempt.durationMs),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Date',
                  value: formatDateTime(attempt.startedAt),
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (quiz != null) ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttemptView(
                      bundle: AttemptBundle(quizId: quiz.id),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Try again'),
              style: appPrimaryButtonStyle(context),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: appSecondaryButtonStyle(context),
              child: const Text('Back to quiz'),
            ),
          ] else
            OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => route.isFirst),
              style: appSecondaryButtonStyle(context),
              child: const Text('Go to library'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _Stat({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.appMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 11.5 : 14.5,
              fontWeight: small ? FontWeight.w500 : FontWeight.w600,
              color: context.appInk,
            ),
          ),
        ],
      ),
    );
  }
}
