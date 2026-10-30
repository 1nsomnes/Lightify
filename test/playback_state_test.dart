import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';

void main() {
  test("the player's shuffle_mode 2 is Smart Shuffle", () {
    expect(ShuffleState.fromPlayer(0), ShuffleState.shuffleOff);
    expect(ShuffleState.fromPlayer(1), ShuffleState.shuffleOn);
    expect(ShuffleState.fromPlayer(2), ShuffleState.smartShuffle);
    expect(ShuffleState.fromPlayer(null), ShuffleState.shuffleOff);
  });

  test("the Web API's smart_shuffle flag wins over shuffle_state", () {
    expect(
      ShuffleState.fromApi({"shuffle_state": true, "smart_shuffle": true}),
      ShuffleState.smartShuffle,
    );
    expect(
      ShuffleState.fromApi({"shuffle_state": true, "smart_shuffle": false}),
      ShuffleState.shuffleOn,
    );
    expect(
      ShuffleState.fromApi({"shuffle_state": false}),
      ShuffleState.shuffleOff,
    );
  });

  test("S turns any shuffle off, and off turns regular shuffle on", () {
    expect(ShuffleState.smartShuffle.toggled, ShuffleState.shuffleOff);
    expect(ShuffleState.shuffleOn.toggled, ShuffleState.shuffleOff);
    expect(ShuffleState.shuffleOff.toggled, ShuffleState.shuffleOn);
    // sent to me/player/shuffle
    expect(ShuffleState.smartShuffle.toggled.value, "false");
  });
}
