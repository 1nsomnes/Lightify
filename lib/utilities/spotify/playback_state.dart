enum RepeatState {
  repeatOff("off"),
  repeatOne("track"),
  repeatContext("context");

  final String value;

  const RepeatState(this.value);
}

enum ShuffleState {
  shuffleOn("true"),
  shuffleOff("false"),
  // Spotify's Smart Shuffle (shuffle plus recommended songs). The Web API
  // can't turn it on, only off (by setting shuffle to false)
  smartShuffle("true");

  /// The `state` sent to `me/player/shuffle`.
  final String value;

  const ShuffleState(this.value);

  bool get isOn => this != shuffleOff;

  /// What S switches to: any shuffle turns off, off turns regular shuffle on.
  ShuffleState get toggled => isOn ? shuffleOff : shuffleOn;

  /// From the web player's state, whose `shuffle_mode` is 0 (off), 1
  /// (shuffle) or 2 (Smart Shuffle).
  static ShuffleState fromPlayer(Object? shuffleMode) => switch (shuffleMode) {
    1 => shuffleOn,
    2 => smartShuffle,
    _ => shuffleOff,
  };

  /// From the Web API's `me/player`, which reports Smart Shuffle as a separate
  /// flag next to `shuffle_state`.
  static ShuffleState fromApi(Map<String, dynamic> json) =>
      json["smart_shuffle"] == true
      ? smartShuffle
      : json["shuffle_state"] == true
      ? shuffleOn
      : shuffleOff;
}

class PlaybackState {
  bool playing;
  ShuffleState shuffleState;
  RepeatState repeatState;

  PlaybackState({
    required this.playing,
    required this.shuffleState,
    required this.repeatState,
  });
}
