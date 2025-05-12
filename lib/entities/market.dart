import 'package:manifold_callibration/entities/market_outcome.dart';

class Market {
  final String id;
  final String question;
  final MarketOutcome? outcome;
  final double? resolutionProbability;
  
  Market({
    required this.id,
    required this.outcome,
    required this.question,
    this.resolutionProbability,
  });
}
