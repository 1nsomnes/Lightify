import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/item_tile.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/pages/profile_pages.dart';
import 'package:lightify/utilities/hold_to_scroll.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ProfileSection {
  const ProfileSection({
    required this.title,
    required this.items,
    this.numbered = false,
    this.contextUri,
  });

  final String title;
  final List<SearchItem> items;
  final bool numbered;
  // when set, Enter plays this album/playlist starting at the selected track
  final String? contextUri;
}

class ProfileData {
  const ProfileData({
    required this.name,
    required this.imageUrl,
    required this.details,
    required this.sections,
  });

  final String name;
  final String imageUrl;
  final String details;
  final List<ProfileSection> sections;
}

/// Popup page for something that owns music (an artist or a user): a header
/// with a badge naming the [kind], then [ProfileSection]s of playable items.
///
/// J/K select, Enter plays, q queues, Shift+A / Shift+P open the selected
/// item's album / artist or owner (replacing this popup).
class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.kind,
    required this.icon,
    required this.load,
    this.roundArtwork = true,
  });

  final String kind;
  final IconData icon;
  final Future<ProfileData> Function() load;
  // people get a round picture, albums keep square cover art
  final bool roundArtwork;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

sealed class _Row {}

class _HeaderRow extends _Row {}

class _TitleRow extends _Row {
  _TitleRow(this.title);
  final String title;
}

class _ItemRow extends _Row {
  _ItemRow(this.item, this.number, this.contextUri);
  final SearchItem item;
  final int? number;
  final String? contextUri;
}

class _ProfileViewState extends State<ProfileView> {
  final ItemScrollController _scroll = ItemScrollController();
  late final SpotifyService spotifyService;

  ProfileData? _data;
  String? _error;
  List<_Row> _rows = [];
  // row index of each selectable item, in order
  List<int> _itemRows = [];
  int _selected = 0;
  late final _hold = HoldToScroll(_moveSelection);

  @override
  void initState() {
    super.initState();
    spotifyService = GetIt.instance.get<SpotifyService>();
    _load();
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      final rows = <_Row>[_HeaderRow()];
      final itemRows = <int>[];
      for (final section in data.sections) {
        if (section.items.isEmpty) continue;
        rows.add(_TitleRow(section.title));
        for (int i = 0; i < section.items.length; i++) {
          itemRows.add(rows.length);
          rows.add(
            _ItemRow(
              section.items[i],
              section.numbered ? i + 1 : null,
              section.contextUri,
            ),
          );
        }
      }
      setState(() {
        _data = data;
        _rows = rows;
        _itemRows = itemRows;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            "Couldn't load this ${widget.kind.toLowerCase()} "
            "(${e.response?.statusCode ?? "no connection"})";
      });
    }
  }

  _ItemRow? get _selectedRow {
    if (_itemRows.isEmpty) return null;
    return _rows[_itemRows[_selected]] as _ItemRow;
  }

  void _moveSelection(int delta, Duration scrollDuration) {
    if (_itemRows.isEmpty) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, _itemRows.length - 1);
    });
    _scroll.scrollTo(
      index: _itemRows[_selected],
      duration: scrollDuration,
      alignment: 0.38,
    );
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (_hold.handle(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final row = _selectedRow;
    final item = row?.item;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.enter:
        if (row == null) break;
        final contextUri = row.contextUri;
        if (contextUri != null) {
          spotifyService.playInContext(
            contextUri,
            row.item.ctxUri,
            deviceId: spotifyService.getDeviceId,
          );
        } else {
          spotifyService.playUri(
            row.item.ctxUri,
            deviceId: spotifyService.getDeviceId,
          );
        }
      case LogicalKeyboardKey.keyQ when e.character == "q":
        if (item != null) {
          spotifyService.queueIfPlayable(
            item.ctxUri,
            deviceId: spotifyService.getDeviceId,
          );
        }
      case LogicalKeyboardKey.keyA when e.character == "A":
        if (item != null) openAlbumPage(context, item);
      case LogicalKeyboardKey.keyP when e.character == "P":
        if (item != null) openCreatorPage(context, item);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopupPage(title: "", onKey: _onKey, child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white54)),
      );
    }
    final data = _data;
    if (data == null) return const Center(child: CircularProgressIndicator());

    final selectedRow = _itemRows.isEmpty ? -1 : _itemRows[_selected];
    return ScrollablePositionedList.builder(
      physics: const ClampingScrollPhysics(),
      itemScrollController: _scroll,
      itemCount: _rows.length + 1,
      itemBuilder: (context, i) {
        // bottom padding, like the base page's list
        if (i == _rows.length) return const SizedBox(height: 16);
        return switch (_rows[i]) {
          _HeaderRow() => _ProfileHeader(
            kind: widget.kind,
            icon: widget.icon,
            roundArtwork: widget.roundArtwork,
            data: data,
          ),
          _TitleRow(:final title) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ItemRow(:final item, :final number, contextUri: _) => Row(
            children: [
              if (number != null)
                SizedBox(
                  width: 36,
                  child: Text(
                    "$number",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: i == selectedRow
                          ? const Color(0xFF1DB954)
                          : Colors.white54,
                    ),
                  ),
                ),
              Expanded(
                child: ItemTile(item: item, selected: i == selectedRow),
              ),
            ],
          ),
        };
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.kind,
    required this.icon,
    required this.roundArtwork,
    required this.data,
  });

  final String kind;
  final IconData icon;
  final bool roundArtwork;
  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    final hasImage = data.imageUrl.isNotEmpty;
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // blurred artwork backdrop fading into the panel
          if (hasImage)
            Opacity(
              opacity: 0.45,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00111215), Color(0xEB111215)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: roundArtwork ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: roundArtwork
                        ? null
                        : const BorderRadius.all(Radius.circular(6)),
                    color: const Color(0xFF2A2B30),
                    boxShadow: const [
                      BoxShadow(color: Color(0x99000000), blurRadius: 20),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? Image.network(
                          data.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, size: 48, color: Colors.white38),
                        )
                      : Icon(icon, size: 48, color: Colors.white38),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KindBadge(kind: kind, icon: icon),
                      const SizedBox(height: 10),
                      Text(
                        data.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      if (data.details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          data.details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, required this.icon});

  final String kind;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x261DB954),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x801DB954)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1DB954)),
          const SizedBox(width: 6),
          Text(
            kind.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
