import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_router/srs/base/hyper_build_context.dart';
import 'package:manifold_callibration/entities/outcome_bucket.dart';
import 'package:manifold_callibration/presentation/calibration/calibration_chart_widget.dart';
import 'package:manifold_callibration/presentation/calibration/calibration_controller.dart';
import 'package:manifold_callibration/presentation/calibration/calibration_route_value.dart';

class OutputBanner extends StatelessWidget {
  const OutputBanner({
    required this.routeValue,
    super.key,
  });

  final CalibrationRouteValue routeValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      surfaceTintColor: colors.surfaceTint,
      color: colors.surface,
      borderRadius: BorderRadius.circular(4),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildBetsCount(colors),
            buildChart(),
            const SizedBox(height: 16),
            buildBrierScore(context),
            const SizedBox(height: 16),
            buildBucketButtons(context, colors),
            buildWeightByMana(context, colors),
            buildExcludeMultipleChoice(context, colors),
          ],
        ),
      ),
    );
  }

  Widget buildHint(ColorScheme colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: colors.secondary, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explanation:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Green arrows show the YES bets,',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Red arrows show the NO bets.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colors.onSecondaryContainer,
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

  Widget buildChart() {
    return Consumer(builder: (context, ref, child) {
      final buckets = ref.watch(calibrationControllerProvider.select(
        (value) => value.maybeMap(
          data: (value) {
            return switch (value.value) {
              CalibrationStateData data => data.stats.buckets,
              _ => <OutcomeBucket>[],
            };
          },
          orElse: () => <OutcomeBucket>[],
        ),
      ));

      return AspectRatio(
        aspectRatio: 1,
        child: CalibrationChartWidget(buckets: buckets),
      );
    });
  }

  Widget buildWeightByMana(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Checkbox(
          value: routeValue.weightByMana,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            context.hyper.navigate(routeValue.copyWith(
              weightByMana: value,
            ));
          },
        ),
        Text(
          'Weight by mana',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget buildExcludeMultipleChoice(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Checkbox(
          value: routeValue.excludeMultipleChoice,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            context.hyper.navigate(routeValue.copyWith(
              excludeMultipleChoice: value,
            ));
          },
        ),
        Text(
          'Exclude multiple choice',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget buildBetsCount(ColorScheme colors) {
    return Consumer(builder: (context, ref, child) {
      final nofResolvedBets = ref.watch(calibrationControllerProvider.select(
        (value) {
          return value.maybeMap(
            data: (value) => switch (value.value) {
              CalibrationStateData data => data.stats.nofResolvedBets,
              _ => 0,
            },
            orElse: () => 0,
          );
        },
      ));

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '$nofResolvedBets resolved bets',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colors.onSurface,
          ),
        ),
      );
    });
  }

  Widget buildBrierScore(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final (brierScore, marketBaseline) = ref.watch(
        calibrationControllerProvider.select(
          (value) {
            return value.maybeMap(
              data: (value) => switch (value.value) {
                CalibrationStateData data => (
                    data.stats.brierScore,
                    data.stats.marketBaseline
                  ),
                _ => (0, 0),
              },
              orElse: () => (0, 0),
            );
          },
        ),
      );

      return DefaultTextStyle.merge(
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        child: Table(
          children: [
            TableRow(
              children: [
                SelectableText('Brier score: '),
                SelectableText(brierScore.toString()),
              ],
            ),
            TableRow(
              children: [
                SelectableText('Market baseline: '),
                SelectableText(marketBaseline.toString()),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget buildMarketBaseline(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final marketBaseline = ref.watch(calibrationControllerProvider.select(
        (value) {
          return value.maybeMap(
            data: (value) => switch (value.value) {
              CalibrationStateData data => data.stats.marketBaseline,
              _ => 0,
            },
            orElse: () => 0,
          );
        },
      ));

      return SelectableText(
        'Brier score: $marketBaseline',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      );
    });
  }

  Widget buildBucketButtons(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Text(
          'Buckets:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Consumer(builder: (context, ref, child) {
            return SegmentedButton<int>(
              selected: {routeValue.buckets},
              emptySelectionAllowed: false,
              multiSelectionEnabled: false,
              onSelectionChanged: (value) {
                context.hyper.navigate(routeValue.copyWith(
                  buckets: value.first,
                ));
              },
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 5,
                  label: Text('5'),
                ),
                ButtonSegment(
                  value: 10,
                  label: Text('10'),
                ),
                ButtonSegment(
                  value: 20,
                  label: Text('20'),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
