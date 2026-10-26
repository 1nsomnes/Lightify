import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/item_tile.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/pages/profile_pages.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final ItemScrollController _scroll = ItemScrollController();
  late final SpotifyService spotifyService;
  late final StreamSubscription _playbackSubscription;
  Timer? _reloadDebounce;

  SearchItem? _current;
  List<SearchItem> _queue = [];
  int _selected = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    spotifyService = GetIt.instance.get<SpotifyService>();
    _load();
    // the queue moves when the track changes; player events can come in
    // bursts, so reload once things settle
    _playbackSubscription = spotifyService.onPlaybackStateChanged.listen((_) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 400), _load);
    });
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _playbackSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await spotifyService.getQueue();
      if (!mounted) return;
      final data = response.data;
      setState(() {
        _current = data["currently_playing"] == null
            ? null
            : ProcessResponse.queueItem(data["currently_playing"]);
        _queue = [
          for (final item in data["queue"] ?? [])
            ProcessResponse.queueItem(item),
        ];
        _selected = _queue.isEmpty ? 0 : _selected.clamp(0, _queue.length - 1);
        _loading = false;
        _error = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            "Couldn't load the queue (${e.response?.statusCode ?? "no connection"})";
      });
    }
  }

  void _moveSelection(int delta) {
    if (_queue.isEmpty) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, _queue.length - 1);
    });
    _scroll.scrollTo(
      index: _selected,
      duration: const Duration(milliseconds: 200),
      alignment: 0.38,
    );
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyJ:
        _moveSelection(1);
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyK:
        _moveSelection(-1);
      // Shift+Q toggles the queue, so it also closes it
      case LogicalKeyboardKey.keyA when e.character == "A":
        if (_selected < _queue.length) {
          openAlbumPage(context, _queue[_selected]);
        }
      case LogicalKeyboardKey.keyP when e.character == "P":
        if (_selected < _queue.length) {
          openCreatorPage(context, _queue[_selected]);
        }
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopupPage(title: "Queue", onKey: _onKey, child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white54,
      letterSpacing: 0.8,
    );

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: labelStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_current != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text("NOW PLAYING", style: labelStyle),
          ),
          ItemTile(item: _current!, selected: false),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text("NEXT UP", style: labelStyle),
        ),
        Expanded(
          child: _queue.isEmpty
              ? Center(child: Text("Nothing queued", style: labelStyle))
              : ScrollablePositionedList.builder(
                  physics: const ClampingScrollPhysics(),
                  itemScrollController: _scroll,
                  itemCount: _queue.length,
                  itemBuilder: (context, i) =>
                      ItemTile(item: _queue[i], selected: i == _selected),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
