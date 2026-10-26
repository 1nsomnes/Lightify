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
import 'package:lightify/utilities/spotify/process_response.dart';
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
  });

  final Function skip;
  final Function prev;
  final Function pause;
  final Function updateToken;
  final Function toggleRepeat;
  final Function toggleShuffle;

  final Function setPlaying;

  @override
  State<Search> createState() => _SearchState();
}

enum SearchKind { playlist, track, album }

class _SearchState extends State<Search> {
  final FocusNode _keyNode = FocusNode();
  final FocusNode _searchNode = FocusNode();
  final ItemScrollController _scroll = ItemScrollController();
  SearchKind searchKind = SearchKind.track;
  bool mine = false;

  final _textController = TextEditingController();
  String _lastQuery = "";
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

  late final SpotifyService spotifyService;
  late final _hold = HoldToScroll(
    (delta, duration) => _moveSelection(getRelevantList(), delta, duration),
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
    super.dispose();
  }

  void _moveSelection(SearchList list, int delta, Duration scrollDuration) {
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
    if (_hold.handle(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    final lk = e.logicalKey;
    var relevantList = getRelevantList();

    switch (lk) {
      case LogicalKeyboardKey.tab:
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
        } else if (relevantList.selected >= 0 &&
            relevantList.selected < relevantList.items.length) {
          spotifyService.queueIfPlayable(
            relevantList.items[relevantList.selected].ctxUri,
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
          if (relevantList.selected >= 0 &&
              relevantList.selected < relevantList.items.length) {
            openCreatorPage(context, relevantList.items[relevantList.selected]);
          }
        } else {
          setState(() {
            searchKind = SearchKind.playlist;
          });
        }

      case LogicalKeyboardKey.keyA:
        if (e.character == "A") {
          if (relevantList.selected >= 0 &&
              relevantList.selected < relevantList.items.length) {
            openAlbumPage(context, relevantList.items[relevantList.selected]);
          }
        } else {
          setState(() {
            searchKind = SearchKind.album;
          });
        }

      case LogicalKeyboardKey.keyT:
        setState(() {
          searchKind = SearchKind.track;
        });

      case LogicalKeyboardKey.keyM:
        // personal saved stuffe
        setState(() {
          mine = !mine;
        });

      case LogicalKeyboardKey.enter:
        if (relevantList.selected >= 0 &&
            relevantList.selected < relevantList.items.length) {
          playSelected(relevantList.items[relevantList.selected].ctxUri);
        }

      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  SearchList getRelevantList() {
    if (mine) {
      if (_textController.text.trim().isNotEmpty) {
        if (searchKind == SearchKind.album) {
          return _myAlbums;
        } else if (searchKind == SearchKind.track) {
          return _myTracks;
        } else {
          return _myPlaylists;
        }
      } else {
        if (searchKind == SearchKind.album) {
          return _myFullAlbums;
        } else if (searchKind == SearchKind.track) {
          return _myFullTracks;
        } else {
          return _myFullPlaylists;
        }
      }
    } else {
      if (searchKind == SearchKind.album) {
        return _albums;
      } else if (searchKind == SearchKind.track) {
        return _tracks;
      } else {
        return _playlists;
      }
    }
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
      });
    }
  }

  void _search() {
    final query = _textController.text.trim();
    debugPrint("searching");
    if (query.isNotEmpty) {
      _populateResults(query);
    } else {
      setState(() => updateAllLists((list) => list.items.clear()));
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
    final relevantList = getRelevantList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            focusNode: _searchNode,
            controller: _textController,
            onSubmitted: (val) {
              _flushDebounce();
              _keyNode.requestFocus();
              setState(() {
                updateAllLists((list) => list.selected = 0);
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Type to search…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ),
        WindowSelection(screen: searchKind, mine: mine),
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
                      selected: i == relevantList.selected,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
