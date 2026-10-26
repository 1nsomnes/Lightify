import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';

/// The player at the top of the home page: artwork, title and artist, the
/// transport controls, and a progress bar you can click or drag to seek.
class NowPlaying extends StatelessWidget {
  const NowPlaying({
    super.key,
    required this.song,
    required this.artist,
    required this.imageUrl,
    required this.state,
    required this.positionMs,
    required this.durationMs,
    required this.positionAt,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.onShuffle,
    required this.onRepeat,
    required this.onSeek,
    this.selected = false,
  });

  final String song;
  final String artist;
  // empty when there's no artwork
  final String imageUrl;
  final PlaybackState state;
  // where the song was at [positionAt]; the bar advances from there while
  // playing
  final int positionMs;
  final int durationMs;
  final DateTime positionAt;

  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final void Function(int positionMs) onSeek;
  // highlighted like a selected list row (K from the top of the results)
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final shuffleOn = state.shuffleState == ShuffleState.shuffleOn;
    final repeat = state.repeatState;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0x14FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Artwork(url: imageUrl),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              // the same green as a selected list row
                              color: selected
                                  ? const Color(0xFF1DB954)
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ControlButton(
                      icon: Icons.shuffle,
                      tooltip: "Shuffle (S)",
                      active: shuffleOn,
                      onPressed: onShuffle,
                    ),
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      tooltip: "Previous (H)",
                      onPressed: onPrevious,
                      size: 26,
                    ),
                    _PlayButton(
                      playing: state.playing,
                      onPressed: onTogglePlay,
                    ),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      tooltip: "Next (L)",
                      onPressed: onNext,
                      size: 26,
                    ),
                    _ControlButton(
                      icon: repeat == RepeatState.repeatOne
                          ? Icons.repeat_one
                          : Icons.repeat,
                      tooltip: "Repeat (R)",
                      active: repeat != RepeatState.repeatOff,
                      onPressed: onRepeat,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ProgressBar(
                  positionMs: positionMs,
                  durationMs: durationMs,
                  positionAt: positionAt,
                  playing: state.playing,
                  onSeek: onSeek,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.url});

  final String url;

  static const _size = 92.0;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFF2A2B30),
      child: Center(
        child: Icon(Icons.music_note, color: Colors.white38, size: 36),
      ),
    );
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 16)],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// A borderless icon button. [active] (shuffle / repeat on) brightens the
/// icon and puts a small dot under it.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active,
    this.size = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  // null for buttons that aren't toggles
  final bool? active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (active) {
      null => Colors.white70,
      true => Colors.white,
      false => Colors.white38,
    };
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkResponse(
        onTap: onPressed,
        // keep keyboard focus on the list when a control is clicked
        canRequestFocus: false,
        radius: 20,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: size, color: color),
              if (active == true)
                const Positioned(
                  bottom: 3,
                  child: CircleAvatar(radius: 2, backgroundColor: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: playing ? "Pause (Space)" : "Play (Space)",
      waitDuration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            canRequestFocus: false,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elapsed time, a thin bar and the song length. The bar moves on its own
/// while [playing] (the player only reports its position when something
/// changes), and clicking or dragging it seeks.
class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.positionMs,
    required this.durationMs,
    required this.positionAt,
    required this.playing,
    required this.onSeek,
  });

  final int positionMs;
  final int durationMs;
  final DateTime positionAt;
  final bool playing;
  final void Function(int positionMs) onSeek;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  Timer? _ticker;
  // the position the bar counts from, and when it was there
  late int _baseMs;
  late DateTime _baseAt;
  // where the bar is being dragged to, as a fraction
  double? _dragFraction;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _rebase(widget.positionMs, widget.positionAt);
    _syncTicker();
  }

  @override
  void didUpdateWidget(ProgressBar old) {
    super.didUpdateWidget(old);
    if (widget.positionMs != old.positionMs ||
        widget.positionAt != old.positionAt) {
      _rebase(widget.positionMs, widget.positionAt);
    } else if (widget.playing != old.playing) {
      // play/pause was pressed before the player reported a new position:
      // freeze or resume from where the bar is now
      _rebase(_currentMs(old.playing), DateTime.now());
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _rebase(int ms, DateTime at) {
    _baseMs = ms;
    _baseAt = at;
  }

  void _syncTicker() {
    if (widget.playing && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => setState(() {}),
      );
    } else if (!widget.playing) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  int _currentMs(bool playing) {
    final elapsed = playing
        ? DateTime.now().difference(_baseAt).inMilliseconds
        : 0;
    return (_baseMs + elapsed).clamp(0, widget.durationMs);
  }

  double _fractionAt(double dx, double width) =>
      width <= 0 ? 0 : (dx / width).clamp(0.0, 1.0);

  void _seekTo(double fraction) {
    if (widget.durationMs <= 0) return;
    final ms = (fraction * widget.durationMs).round();
    setState(() {
      _dragFraction = null;
      _rebase(ms, DateTime.now());
    });
    widget.onSeek(ms);
  }

  static String _format(int ms) {
    final seconds = ms ~/ 1000;
    return "${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.durationMs;
    final current = _currentMs(widget.playing);
    final fraction =
        _dragFraction ?? (duration <= 0 ? 0.0 : current / duration);
    final active = _hovering || _dragFraction != null;
    const timeStyle = TextStyle(
      color: Colors.white54,
      fontSize: 11,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            _format(
              _dragFraction == null ? current : (fraction * duration).round(),
            ),
            style: timeStyle,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return MouseRegion(
                cursor: duration > 0
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: (_) => setState(() => _hovering = true),
                onExit: (_) => setState(() => _hovering = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) =>
                      _seekTo(_fractionAt(d.localPosition.dx, width)),
                  onHorizontalDragUpdate: (d) => setState(() {
                    _dragFraction = _fractionAt(d.localPosition.dx, width);
                  }),
                  onHorizontalDragEnd: (_) {
                    if (_dragFraction != null) _seekTo(_dragFraction!);
                  },
                  child: SizedBox(
                    height: 16,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: active ? 5 : 3,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: width * fraction,
                          height: active ? 5 : 3,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white70,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        if (active && duration > 0)
                          Positioned(
                            left: width * fraction - 6,
                            child: const CircleAvatar(
                              radius: 6,
                              backgroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            _format(duration),
            textAlign: TextAlign.right,
            style: timeStyle,
          ),
        ),
      ],
    );
  }
}
