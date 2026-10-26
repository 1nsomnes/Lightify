import 'package:flutter/material.dart';
import 'package:lightify/utilities/spotify/search_item.dart';

/// A row in a selectable item list (search results, queue).
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.selected,
    this.icon,
    this.showKind = false,
  });

  final SearchItem item;
  final bool selected;
  // shown instead of the artwork, for rows that aren't a song or album
  final IconData? icon;
  // a T / A / P badge on the right, for lists that mix kinds
  final bool showKind;

  static const _kindLetters = {"track": "T", "album": "A", "playlist": "P"};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // inset so the selection's rounded background (the same as the player's
    // when it's selected) doesn't touch the edges. The row gets its own
    // Material: ListTile paints on the nearest one, which in a popup sits
    // under the panel's background
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          selectedTileColor: const Color(0x14FFFFFF),
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: icon != null
                ? Container(
                    width: 48,
                    height: 48,
                    color: const Color(0x261DB954),
                    child: Icon(icon, color: const Color(0xFF1DB954)),
                  )
                : Image.network(
                    item.imgUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
          ),
          selected: selected,
          selectedColor: const Color(0xFF1DB954),
          titleTextStyle: textTheme.titleMedium,
          subtitleTextStyle: textTheme.labelSmall,
          title: Text(item.name),
          subtitle: Text(item.artist),
          trailing: showKind ? _kindBadge() : null,
        ),
      ),
    );
  }

  Widget? _kindBadge() {
    final letter = _kindLetters[item.ctxUri.split(":").elementAtOrNull(1)];
    if (letter == null) return null;
    return Text(
      letter,
      style: TextStyle(
        color: selected ? const Color(0xFF1DB954) : Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
