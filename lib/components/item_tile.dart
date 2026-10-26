import 'package:flutter/material.dart';
import 'package:lightify/utilities/spotify/search_item.dart';

/// A row in a selectable item list (search results, queue).
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.selected,
    this.icon,
  });

  final SearchItem item;
  final bool selected;
  // shown instead of the artwork, for rows that aren't a song or album
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
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
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF1DB954),
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.labelSmall,
      title: Text(item.name),
      subtitle: Text(item.artist),
    );
  }
}
