enum RepeatState {
  repeatOff("0"),
  repeatOne("1"),
  repeatContext("2");

  final String value;

  const RepeatState(this.value);
}

enum ShuffleState {
  shuffleOn("true"),
  shuffleOff("false");

  final String value;

  const ShuffleState(this.value);
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
