import 'package:flutter/material.dart';
import 'package:lightify/components/pill_text_button.dart';
import 'package:lightify/components/search.dart';

class WindowSelection extends StatelessWidget {
  const WindowSelection({super.key, required this.screen});

  final SearchKind screen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PillButton(
          label: 'Tracks',
          selected: screen == SearchKind.track,
          onPressed: () {},
        ),
        PillButton(
          label: 'Albums',
          selected: screen == SearchKind.album,
          onPressed: () {},
        ),
        PillButton(
          label: 'Playlists',
          selected: screen == SearchKind.playlist,
          onPressed: () {},
        ),
      ],
    );
  }
}
