import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/theme/theme_controller.dart';
import 'package:quiz_app/core/utils/failure_messages.dart';

class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const MathText(this.text, {super.key, this.style, this.textAlign});

  static final _math = RegExp(r'(\\\([\s\S]*?\\\)|\\\[[\s\S]*?\\\])');

  @override
  Widget build(BuildContext context) {
    final effective = style ?? DefaultTextStyle.of(context).style;
    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in _math.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final token = match.group(0)!;
      final isDisplay = token.startsWith(r'\[');
      final tex = token.substring(2, token.length - 2);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            tex,
            mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
            textStyle: effective,
            onErrorFallback: (error) => Text(tex, style: effective),
          ),
        ),
      );
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    if (spans.isEmpty) return Text(text, style: effective, textAlign: textAlign);
    if (spans.length == 1 && spans.first is TextSpan) {
      return Text(text, style: effective, textAlign: textAlign);
    }
    return Text.rich(
      TextSpan(children: spans),
      style: effective,
      textAlign: textAlign,
    );
  }
}

class ScoreBadge extends StatelessWidget {
  final int score;
  final int maxScore;
  final bool large;

  const ScoreBadge({
    super.key,
    required this.score,
    required this.maxScore,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxScore == 0 ? 0 : (score / maxScore * 100).round();
    final background = percentage >= 80
        ? context.appGoodSoft
        : percentage >= 60
            ? context.appMidSoft
            : context.appDangerSoft;
    final foreground = percentage >= 80
        ? context.appGood
        : percentage >= 60
            ? context.appMid
            : context.appDanger;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$score/$maxScore',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: large ? 13 : 10.5,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const SectionHeader(this.label, {super.key, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.appMuted,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: context.appMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: context.appMuted),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: appPrimaryButtonStyle(context).copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size(170, 46)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.appDangerSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.error_outline, color: context.appDanger),
            ),
            const SizedBox(height: 14),
            Text(
              "Couldn't load this screen",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              messageFor(failure),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: appSecondaryButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int rows;

  const SkeletonList({super.key, this.rows = 7});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: rows,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 170,
                    height: 10,
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.appSurfaceAlt,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageBody({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.mode,
      builder: (context, mode, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 17,
                color: context.appMuted,
              ),
              const SizedBox(width: 2),
              Transform.scale(
                scale: 0.78,
                child: Switch(
                  value: isDark,
                  onChanged: AppThemeController.setDark,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

ButtonStyle appPrimaryButtonStyle(BuildContext context) => FilledButton.styleFrom(
      backgroundColor: context.appAccent,
      foregroundColor: context.appOnAccent,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );

ButtonStyle appSecondaryButtonStyle(BuildContext context) =>
    OutlinedButton.styleFrom(
      foregroundColor: context.appInk,
      side: BorderSide(color: context.appLine),
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

ButtonStyle appDangerButtonStyle(BuildContext context) => FilledButton.styleFrom(
      backgroundColor: context.appDanger,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );

InputDecoration appInputDecoration(
  BuildContext context, {
  String? hint,
  String? label,
}) =>
    InputDecoration(
      hintText: hint,
      labelText: label,
      filled: true,
      fillColor: context.appBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.appLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.appLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: context.appAccent),
      ),
    );
