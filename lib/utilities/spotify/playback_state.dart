enum RepeatState { repeatOff, repeatOne, repeatContext }

enum ShuffleState { shuffleOn, shuffleOff }

class PlaybackState {
  bool playing;
  final ShuffleState shuffleState;
  final RepeatState repeatState;

  PlaybackState({
    required this.playing,
    required this.shuffleState,
    required this.repeatState,
  });
}
