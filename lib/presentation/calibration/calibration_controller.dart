import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manifold_callibration/data/bets_repository.dart';
import 'package:manifold_callibration/domain/calibration_service.dart'; // Ensure this import is correct
import 'package:manifold_callibration/domain/market_baseline_calculator.dart'; // Ensure this import is correct
import 'package:manifold_callibration/entities/bet.dart';
import 'package:manifold_callibration/entities/outcome_bucket.dart';
//import 'package:logger/logger.dart'; // Import the logger package

class CalibrationController extends AutoDisposeAsyncNotifier<CalibrationState> {
  @override
  FutureOr<CalibrationState> build() async {
    return CalibrationStateEmpty();
  }

  void setParams({
    required String username,
    required int nofBuckets,
    required bool weighByMana,
    required bool excludeMultipleChoice,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) {
      return;
    }

    final List<Bet> bets;

    switch (state) {
      case AsyncData(value: CalibrationStateData data)
          when data.username == username && !forceRefresh:
        bets = data.bets;
      default:
        state = AsyncLoading();
        final betsRepo = ref.read(betsRepositoryProvider);

        try {
          bets = await betsRepo.getUserBets(username);
        } on Exception catch (e, s) {
          state = AsyncError(e, s);
          return;
        }
    }

    final stats = _calculateStats(
      bets: bets,
      nofBuckets: nofBuckets,
      weighByMana: weighByMana,
      excludeMultipleChoice: excludeMultipleChoice,
    );

    state = AsyncData(CalibrationStateData(
      username: username,
      bets: bets,
      stats: stats,
    ));
  }

  CalibrationStats _calculateStats({
    required List<Bet> bets,
    required int nofBuckets,
    required bool weighByMana,
    required bool excludeMultipleChoice,
  }) {
    final calibrationService = ref.read(calibrationServiceProvider);
    final buckets = calibrationService.calculateCalibration(
      bets: bets,
      nofBuckets: nofBuckets,
      weighByMana: weighByMana,
      excludeMultipleChoice: excludeMultipleChoice,
    );
    final brierScore = calibrationService.calculateBrierScore(
      bets,
      excludeMultipleChoice: excludeMultipleChoice,
    );
    final marketBaseline = MarketBaselineCalculator.calculate(
      bets,
      excludeMultipleChoice: excludeMultipleChoice,
    );
    final nofResolvedBets = bets.where((e) => e.market!.outcome != null).length;

    return CalibrationStats(
      buckets: buckets,
      brierScore: brierScore,
      marketBaseline: marketBaseline,
      nofResolvedBets: nofResolvedBets,
    );
  }
}

sealed class CalibrationState {}

class CalibrationStateEmpty extends CalibrationState {}

class CalibrationStateData extends CalibrationState {
  final List<Bet> bets;
  final String username;
  final CalibrationStats stats;

  CalibrationStateData({
    required this.username,
    required this.bets,
    required this.stats,
  });

  CalibrationStateData copyWith({
    List<Bet>? bets,
    String? username,
    CalibrationStats? stats,
  }) {
    return CalibrationStateData(
      bets: bets ?? this.bets,
      username: username ?? this.username,
      stats: stats ?? this.stats,
    );
  }
}

class CalibrationStats {
  final List<OutcomeBucket> buckets;
  final double brierScore;
  final double marketBaseline;
  final int nofResolvedBets;

  CalibrationStats({
    required this.buckets,
    required this.brierScore,
    required this.marketBaseline,
    required this.nofResolvedBets,
  });
}

final calibrationControllerProvider =
    AsyncNotifierProvider.autoDispose<CalibrationController, CalibrationState>(
  CalibrationController.new,
);

