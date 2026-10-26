import 'package:flutter/material.dart';
import 'package:lightify/utilities/spotify/search_item.dart';

/// A row in a selectable item list (search results, queue).
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, required this.selected});

  final SearchItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: Image.network(
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
