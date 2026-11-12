/// When an interstitial may follow a level win: none until [firstAfter] levels are won, then on that win and
/// every [every] wins after it (5, 8, 11… with the defaults). The numbers will come from Remote Config.
class LevelAdPacer {
  const LevelAdPacer({this.firstAfter = 5, this.every = 3}) : assert(firstAfter > 0 && every > 0);

  final int firstAfter;
  final int every;

  /// [levelsWon]: total level wins, counting the one just won.
  bool shouldShow(int levelsWon) => levelsWon >= firstAfter && (levelsWon - firstAfter) % every == 0;
}
