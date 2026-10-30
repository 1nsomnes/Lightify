import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/item_tile.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/components/window_selection.dart';
import 'package:lightify/pages/profile_pages.dart';
import 'package:lightify/pages/queue_page.dart';
import 'package:lightify/pages/settings_page.dart';
import 'package:lightify/utilities/hold_to_scroll.dart';
import 'package:lightify/utilities/settings.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_list.dart';
import 'package:lightify/utilities/spotify/search_result.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Search extends StatefulWidget {
  const Search({
    super.key,
    required this.skip,
    required this.prev,
    required this.pause,
    required this.setPlaying,
    required this.updateToken,
    required this.toggleRepeat,
    required this.toggleShuffle,
    required this.seekBy,
    required this.nowPlaying,
    required this.nowPlayingSelected,
  });

  final Function skip;
  final Function prev;
  final Function pause;
  final Function updateToken;
  final Function toggleRepeat;
  final Function toggleShuffle;
  // seeks the playing song by this many ms (negative goes back)
  final void Function(int ms) seekBy;

  final Function setPlaying;

  // the song in the player above the list; K from the top of the list
  // selects it (null when nothing is playing)
  final SearchItem? nowPlaying;
  // true while that song is the selection; the player highlights itself
  final ValueNotifier<bool> nowPlayingSelected;

  @override
  State<Search> createState() => _SearchState();
}

enum SearchKind { track, album, playlist }

const _searchBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(999)),
  borderSide: BorderSide(color: Colors.white24),
);

class _SearchState extends State<Search> {
  final FocusNode _keyNode = FocusNode();
  final FocusNode _searchNode = FocusNode();
  final ItemScrollController _scroll = ItemScrollController();
  // which kinds of results are shown; each one toggles (T / A / P)
  final Set<SearchKind> kinds = {...SearchKind.values};
  bool mine = false;

  final _textController = TextEditingController();
  String _lastQuery = "";
  // the selection and query when Tab moved to the search field, restored on
  // Enter if the query didn't change
  int _selectionBeforeSearch = 0;
  bool _playerBeforeSearch = false;
  String _queryBeforeSearch = "";
  Timer? _debounce;

  // TODO: maybe add loading when searching?
  // bool _isLoading = false;
  final SearchList _tracks = SearchList();
  final SearchList _playlists = SearchList();
  final SearchList _albums = SearchList();

  // personal saved stuff.
  final SearchList _myTracks = SearchList();
  final SearchList _myPlaylists = SearchList();
  final SearchList _myAlbums = SearchList();

  // full list
  final SearchList _myFullTracks = SearchList();
  final SearchList _myFullPlaylists = SearchList();
  final SearchList _myFullAlbums = SearchList();

  // what's on screen: the enabled kinds of the current source, merged
  final SearchList _shown = SearchList();

  late final SpotifyService spotifyService;
  late final _hold = HoldToScroll(
    (delta, duration) => _moveSelection(_shown, delta, duration),
  );
  late final _seekHold = HoldToSeek(
    (direction) => widget.seekBy(direction * Settings.seekStep.value * 1000),
  );

  void loadPersonalCatalog(
    Future<Response> Function(int, int) call,
    Function(List<dynamic>, List<dynamic>, {bool savedResult}) parser,
    SearchList list,
  ) async {
    int offset = 0;
    while (true) {
      var response = await call(50, offset);
      if (!mounted || response.statusCode != 200) break;

      var data = response.data;
      setState(() {
        parser(data["items"], list.items, savedResult: true);
        _updateShown();
      });

      if (data["next"] == null) break;
      offset += 50;
    }
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchNode.requestFocus();
    });

    spotifyService = GetIt.instance.get<SpotifyService>();
    loadPersonalCatalog(
      spotifyService.getLikedAlbums,
      ProcessResponse.processAlbumsJson,
      _myFullAlbums,
    );
    loadPersonalCatalog(
      spotifyService.getLikedSongs,
      ProcessResponse.processTracksJson,
      _myFullTracks,
    );
    loadPersonalCatalog(
      spotifyService.getLikedPlaylists,
      ProcessResponse.processPlaylistsJson,
      _myFullPlaylists,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.removeListener(_onSearchChanged);
    _textController.dispose();
    _keyNode.dispose();
    _searchNode.dispose();
    _hold.dispose();
    _seekHold.dispose();
    super.dispose();
  }

  void _moveSelection(SearchList list, int delta, Duration scrollDuration) {
    final onPlayer = widget.nowPlayingSelected;
    if (onPlayer.value) {
      // down from the player goes back to the top of the list
      if (delta > 0 && list.items.isNotEmpty) {
        onPlayer.value = false;
        setState(() => list.selected = 0);
      }
      return;
    }
    if (delta < 0 && list.selected <= 0 && widget.nowPlaying != null) {
      onPlayer.value = true;
      setState(() {});
      return;
    }
    if (list.items.isEmpty) return;
    setState(() {
      list.selected = (list.selected + delta).clamp(0, list.items.length - 1);
    });
    _scroll.scrollTo(
      index: list.selected,
      duration: scrollDuration,
      alignment: 0.38,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (_hold.handle(e) || _seekHold.handle(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    final lk = e.logicalKey;
    final relevantList = _shown;
    final selectedItem = _selectedItem;

    switch (lk) {
      case LogicalKeyboardKey.tab:
        _selectionBeforeSearch = relevantList.selected;
        _playerBeforeSearch = widget.nowPlayingSelected.value;
        _queryBeforeSearch = _textController.text.trim();
        widget.nowPlayingSelected.value = false;
        setState(() => relevantList.selected = -1);
        _searchNode.requestFocus();

      case LogicalKeyboardKey.keyS:
        if (e.character == "S") {
          PopupHost.of(context).show(const SettingsPage());
        } else {
          widget.toggleShuffle();
        }

      case LogicalKeyboardKey.keyR:
        widget.toggleRepeat();

      case LogicalKeyboardKey.keyQ:
        // read shift from this event: the global keyboard state can still
        // think shift is held from the Meta+Shift+S that opened the window
        if (e.character == "Q") {
          PopupHost.of(context).show(const QueuePage());
        } else if (selectedItem != null) {
          spotifyService.queueIfPlayable(
            selectedItem.ctxUri,
            deviceId: spotifyService.getDeviceId,
          );
        }
      case LogicalKeyboardKey.space:
        widget.pause();
      case LogicalKeyboardKey.keyH:
        widget.prev();
      case LogicalKeyboardKey.keyL:
        widget.skip();

      case LogicalKeyboardKey.keyP:
        if (e.character == "P") {
          if (selectedItem != null) openCreatorPage(context, selectedItem);
        } else {
          _toggleKind(SearchKind.playlist);
        }

      case LogicalKeyboardKey.keyA:
        if (e.character == "A") {
          if (selectedItem != null) openAlbumPage(context, selectedItem);
        } else {
          _toggleKind(SearchKind.album);
        }

      case LogicalKeyboardKey.keyT:
        _toggleKind(SearchKind.track);

      case LogicalKeyboardKey.keyM:
        _toggleMine();

      case LogicalKeyboardKey.keyO when e.character == "O":
        if (selectedItem != null) openCollectionPage(context, selectedItem);

      // jump to the playing song (same as K from the top of the list), and
      // bring the list back to the top, where J leaves the player
      case LogicalKeyboardKey.keyC when e.character == "C":
        if (widget.nowPlaying != null) {
          widget.nowPlayingSelected.value = true;
          setState(() {});
          if (relevantList.items.isNotEmpty) {
            _scroll.scrollTo(index: 0, duration: tapScrollDuration);
          }
        }

      // the playing song is already playing, so Enter leaves it alone
      case LogicalKeyboardKey.enter when !widget.nowPlayingSelected.value:
        if (relevantList.selected >= 0 &&
            relevantList.selected < relevantList.items.length) {
          final selected = relevantList.items[relevantList.selected];
          if (mine && _kindOf(selected) == SearchKind.track) {
            _playLikedSong(selected);
          } else {
            playSelected(relevantList.items[relevantList.selected].ctxUri);
          }
        }

      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // the playing song when it's selected, otherwise the list's selection
  SearchItem? get _selectedItem {
    if (widget.nowPlayingSelected.value) return widget.nowPlaying;
    final list = _shown;
    return list.selected >= 0 && list.selected < list.items.length
        ? list.items[list.selected]
        : null;
  }

  // the per-kind lists results currently come from
  Map<SearchKind, SearchList> get _sources {
    if (!mine) {
      return {
        SearchKind.track: _tracks,
        SearchKind.album: _albums,
        SearchKind.playlist: _playlists,
      };
    }
    final searching = _textController.text.trim().isNotEmpty;
    return {
      SearchKind.track: searching ? _myTracks : _myFullTracks,
      SearchKind.album: searching ? _myAlbums : _myFullAlbums,
      SearchKind.playlist: searching ? _myPlaylists : _myFullPlaylists,
    };
  }

  static SearchKind? _kindOf(SearchItem item) =>
      switch (item.ctxUri.split(":").elementAtOrNull(1)) {
        "track" => SearchKind.track,
        "album" => SearchKind.album,
        "playlist" => SearchKind.playlist,
        _ => null,
      };

  // Rebuilds the on-screen list (call inside setState). With [keepSelection]
  // the same item stays selected when it's still there; otherwise the
  // selection goes back to the top.
  void _updateShown({bool keepSelection = true}) {
    if (!keepSelection && _shown.selected >= 0) _shown.selected = 0;
    final previous =
        keepSelection &&
            _shown.selected >= 0 &&
            _shown.selected < _shown.items.length
        ? _shown.items[_shown.selected].ctxUri
        : null;
    final sources = _sources;
    _shown.items = SearchList.merge(
      [
        for (final kind in SearchKind.values)
          if (kinds.contains(kind)) sources[kind]!.items,
      ],
      // search results mix by rank; your whole library reads better grouped
      interleave: !mine || _textController.text.trim().isNotEmpty,
    );
    if (_shown.selected < 0) return; // focus is in the search field
    final index = _shown.items.indexWhere((i) => i.ctxUri == previous);
    _shown.selected = index >= 0
        ? index
        : _shown.selected.clamp(
            0,
            _shown.items.isEmpty ? 0 : _shown.items.length - 1,
          );
  }

  void _toggleKind(SearchKind kind) {
    // keep at least one kind on, so the list is never empty by accident
    if (kinds.contains(kind) && kinds.length == 1) return;
    setState(() {
      if (!kinds.remove(kind)) kinds.add(kind);
      _updateShown();
    });
  }

  void _toggleMine() {
    setState(() {
      mine = !mine;
      _updateShown();
    });
  }

  void updateAllLists(Function(SearchList) action) {
    action(_albums);
    action(_tracks);
    action(_playlists);
  }

  void playSelected(String? ctxUri) {
    if (ctxUri != null) {
      spotifyService.playUri(ctxUri, deviceId: spotifyService.getDeviceId);
      widget.setPlaying(true);
    }
  }

  // plays the selected liked song inside "Liked Songs", so the rest of the
  // liked songs (then Spotify's autoplay) follow it
  Future<void> _playLikedSong(SearchItem song) async {
    widget.setPlaying(true);
    final tracks = [
      for (final item in _shown.items)
        if (_kindOf(item) == SearchKind.track) item.ctxUri,
    ];
    try {
      await spotifyService.playTrackInContext(
        await spotifyService.likedSongsUri(),
        tracks,
        tracks.indexOf(song.ctxUri),
        deviceId: spotifyService.getDeviceId,
      );
    } on DioException catch (e) {
      debugPrint("couldn't look up the liked songs: $e");
    }
  }

  void _populateResults(String query) async {
    final lowerQuery = query.toLowerCase();
    setState(() {
      updateAllLists((list) {
        list.items.clear();
        list.selected = 0;
      });
      for (final (scopedList, fullList) in [
        (_myTracks, _myFullTracks),
        (_myAlbums, _myFullAlbums),
        (_myPlaylists, _myFullPlaylists),
      ]) {
        scopedList.items = fullList.items
            .where(
              (item) => "${item.name} ${item.artist}".toLowerCase().contains(
                lowerQuery,
              ),
            )
            .toList();
        scopedList.selected = 0;
      }
      _updateShown(keepSelection: false);
    });

    var response = await spotifyService.searchSpotify(query, 30, 0);
    // drop stale responses: the query changed (or widget went away) meanwhile.
    if (!mounted || query != _textController.text.trim()) return;
    if (response.statusCode == 200) {
      SearchResult result = ProcessResponse.parseSearchResults(response.data);
      setState(() {
        _albums.items = result.albums;
        _playlists.items = result.playlists;
        _tracks.items = result.tracks;
        _updateShown();
      });
    }
  }

  void _search() {
    final query = _textController.text.trim();
    debugPrint("searching");
    if (query.isNotEmpty) {
      _populateResults(query);
    } else {
      setState(() {
        updateAllLists((list) => list.items.clear());
        _updateShown();
      });
    }
  }

  void _flushDebounce() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _search();
    }
  }

  void _onSearchChanged() {
    String curr = _textController.text;
    if (curr != _lastQuery) {
      _lastQuery = curr;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _search);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relevantList = _shown;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            focusNode: _searchNode,
            controller: _textController,
            onSubmitted: (val) {
              final unchanged =
                  _textController.text.trim() == _queryBeforeSearch;
              if (unchanged) {
                // the results on screen are still for this query (edits that
                // ended back where they started don't need a new search)
                _debounce?.cancel();
              } else {
                _flushDebounce();
              }
              _keyNode.requestFocus();
              final index = unchanged
                  ? _selectionBeforeSearch.clamp(
                      0,
                      _shown.items.isEmpty ? 0 : _shown.items.length - 1,
                    )
                  : 0;
              widget.nowPlayingSelected.value =
                  unchanged && _playerBeforeSearch;
              setState(() => _shown.selected = index);
              if (_shown.items.isNotEmpty && _scroll.isAttached) {
                _scroll.jumpTo(index: index, alignment: unchanged ? 0.38 : 0);
              }
            },
            // matches the filter chips below, but stays gray when focused
            cursorColor: Colors.white70,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Color(0x0FFFFFFF),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              prefixIcon: Icon(Icons.search, size: 20),
              prefixIconColor: Colors.white54,
              hintText: 'Search…',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
              enabledBorder: _searchBorder,
              focusedBorder: _searchBorder,
            ),
          ),
        ),
        WindowSelection(
          kinds: kinds,
          mine: mine,
          onToggleKind: _toggleKind,
          onToggleMine: _toggleMine,
        ),
        Expanded(
          child: Focus(
            focusNode: _keyNode,
            onKeyEvent: _onKey,
            child: relevantList.items.isEmpty
                ? const SizedBox.shrink()
                : ScrollablePositionedList.builder(
                    physics: const ClampingScrollPhysics(),
                    itemScrollController: _scroll,
                    itemCount: relevantList.items.length,
                    itemBuilder: (context, i) => ItemTile(
                      item: relevantList.items[i],
                      selected:
                          i == relevantList.selected &&
                          !widget.nowPlayingSelected.value,
                      showKind: true,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
