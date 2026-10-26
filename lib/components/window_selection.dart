import 'package:flutter/material.dart';
import 'package:lightify/components/pill_text_button.dart';
import 'package:lightify/components/search.dart';

/// The search filters: which kinds of results are shown (each one toggles,
/// T / A / P) and whether to search only your saved music (M).
class WindowSelection extends StatelessWidget {
  const WindowSelection({
    super.key,
    required this.kinds,
    required this.mine,
    required this.onToggleKind,
    required this.onToggleMine,
  });

  final Set<SearchKind> kinds;
  final bool mine;
  final void Function(SearchKind kind) onToggleKind;
  final VoidCallback onToggleMine;

  static const _labels = {
    SearchKind.track: "Tracks",
    SearchKind.album: "Albums",
    SearchKind.playlist: "Playlists",
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              for (final MapEntry(key: kind, value: label) in _labels.entries)
                PillButton(
                  label: label,
                  selected: kinds.contains(kind),
                  onPressed: () => onToggleKind(kind),
                ),
            ],
          ),

          PillButton(
            label: "Mine",
            icon: Icons.favorite,
            selected: mine,
            onPressed: onToggleMine,
          ),
        ],
      ),
    );
  }
}
