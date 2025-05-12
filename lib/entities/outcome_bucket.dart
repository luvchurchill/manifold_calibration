import 'package:manifold_callibration/entities/bet.dart';
import 'package:manifold_callibration/entities/bet_outcome.dart';

class OutcomeBucket {
  final List<Bet> bets;
  final double yesRatio;
  final double noRatio;

  OutcomeBucket({
    required this.bets,
    required this.yesRatio,
    required this.noRatio,
  });
  List<Bet> getTopYesBets([int limit = 5]) {
    return bets
        .where((bet) => bet.outcome is BinaryBetOutcomeYes || bet.outcome is MultipleChoiceBetOutcomeYes)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount))
      ..length = limit > bets.length ? bets.length : limit;
  }

  List<Bet> getTopNoBets([int limit = 5]) {
    return bets
        .where((bet) => bet.outcome is BinaryBetOutcomeNo || bet.outcome is MultipleChoiceBetOutcomeNo)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount))
      ..length = limit > bets.length ? bets.length : limit;
  }
}
