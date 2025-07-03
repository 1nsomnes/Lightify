import 'package:flutter/material.dart';
import 'package:lightify/components/pill_text_button.dart';
import 'package:lightify/components/search.dart';

class WindowSelection extends StatelessWidget {
  const WindowSelection({super.key, required this.screen, required this.mine});

  final SearchKind screen;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: mine,
                onChanged: (_) {},
                activeColor:
                    Colors.purple ?? Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text("Mine"),
            ],
          ),
        ),
      ],
    );
  }
}
