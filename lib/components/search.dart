import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/window_selection.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify.dart';
import 'package:http/http.dart' as http;
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_list.dart';
import 'package:lightify/utilities/spotify/search_result.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:lightify/utilities/spotify_auth.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Search extends StatefulWidget {
  const Search({
    super.key,
    required this.token,
    required this.deviceId,
    required this.skip,
    required this.prev,
    required this.pause,
    required this.setPlaying,
    required this.updateToken,
  });

  final String token;
  final String deviceId;

  final Function skip;
  final Function prev;
  final Function pause;
  final Function updateToken;

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

  late AuthProvider authProvider;
  late FlutterSecureStorage storage;
  late SpotifyService spotifyService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context);

    makeNetworkCall(
      () {
        return spotifyService.getLikedPlaylists(50, 0);
      },
      process: (body) {
        debugPrint("liked playlist");

        final json = jsonDecode(body);
        //debugPrint("items: " + json["total"].toString());
        //debugPrint(json.toString());
        debugPrint("token: ${widget.token}");
        for (dynamic playlist in json["items"]) {
          //debugPrint("\n");
          //debugPrint(playlist.toString());
          //if (playlist == null) continue;
          var item = SearchItem(
            name: playlist["name"] ?? "",
            artist: playlist["owner"]["display_name"] ?? "",
            imgUrl: playlist["images"][0]["url"] ?? "",
            ctxUri: playlist["uri"] ?? "",
          );
          _myPlaylists.items.add(item);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchNode.requestFocus();
    });

    final getIt = GetIt.instance;
    storage = getIt.get<FlutterSecureStorage>();
    spotifyService = getIt.get<SpotifyService>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.removeListener(_onSearchChanged);
    _textController.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    final lk = e.logicalKey;
    var relevantList = getRelevantList();

    switch (lk) {
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyJ:
        setState(() {
          relevantList.selected = (relevantList.selected + 1).clamp(
            0,
            relevantList.items.length - 1,
          );
        });

        _scroll.scrollTo(
          index: relevantList.selected,
          duration: Duration(milliseconds: 200),
          alignment: 0.38,
        );

      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyK:
        setState(() {
          relevantList.selected = (relevantList.selected - 1).clamp(
            0,
            relevantList.items.length - 1,
          );
        });
        _scroll.scrollTo(
          index: relevantList.selected,
          duration: Duration(milliseconds: 200),
          alignment: 0.38,
        );

      case LogicalKeyboardKey.tab:
        setState(() => relevantList.selected = -1);
        _searchNode.requestFocus();

      case LogicalKeyboardKey.keyS:
        //TODO: add stuff here lol
        

      case LogicalKeyboardKey.keyQ:
        if (relevantList.selected >= 0 &&
            relevantList.selected < relevantList.items.length) {
          var ctxUri = relevantList.items[relevantList.selected].ctxUri;
          makeNetworkCall(() {
            return spotifyService.queue(ctxUri);
          });
        }
      case LogicalKeyboardKey.space:
        widget.pause();
      case LogicalKeyboardKey.keyH:
        widget.prev();
      case LogicalKeyboardKey.keyL:
        widget.skip();

      case LogicalKeyboardKey.keyP:
        setState(() {
          searchKind = SearchKind.playlist;
        });

      case LogicalKeyboardKey.keyA:
        setState(() {
          searchKind = SearchKind.album;
        });

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
          var ctxUri = relevantList.items[relevantList.selected].ctxUri;
          playSelected(ctxUri);
        }

      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  SearchList getRelevantList() {
    if (mine) {
      if (searchKind == SearchKind.album) {
        return _myAlbums;
      } else if (searchKind == SearchKind.track) {
        return _myTracks;
      } else {
        return _myPlaylists;
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

  // We expect universal handling of some response status codes such as 401.
  // This method attempts to consolidate them
  Future<T> makeNetworkCall<T>(
    Future<http.Response> Function() call, {
    T Function(String)? process,
  }) async {
    http.Response response = await call();

    // authentication error, try to refresh token and call the method again if anything
    if (response.statusCode == 401) {
      if (await attemptRefresh(
        authProvider.getRefreshToken,
        authProvider,
        storage,
      )) {
        debugPrint(
          "Successfully refreshed token, attempting to reinject token",
        );
        widget.updateToken(authProvider.getToken);
      }
    } else if (response.statusCode == 200) {
    } else {}

    if (process != null) {
      return process(response.body);
    }
    return null as T;
  }

  void playSelected(String? ctxUri) {
    if (ctxUri != null) {
      if (ctxUri.split(":")[1] == "track") {
        makeNetworkCall(() {
          return spotifyService.playTracks([ctxUri], deviceId: widget.deviceId);
        });
      } else {
        makeNetworkCall(() {
          return spotifyService.playPlaylistOrAlbums(
            ctxUri,
            deviceId: widget.deviceId,
          );
        });
      }

      widget.setPlaying(true);
    }
  }

  void _populateResults(String query) async {
    setState(() {
      updateAllLists((list) {
        list.items.clear();
        list.selected = 0;
      });
    });

    SearchResult result = await makeNetworkCall(
      () {
        return spotifyService.searchSpotify(query, 20, 0);
      },
      process: (String body) {
        return ProcessResponse.parseSearchResults(body);
      },
    );

    setState(() {
      _albums.items = result.albums;
      _playlists.items = result.playlists;
      _tracks.items = result.tracks;
    });
  }

  void _search() async {
    final query = _textController.text.trim();
    debugPrint("searching");
    if (query.isNotEmpty) {
      _populateResults(query);
    } else {
      setState(() => updateAllLists((list) => list.items.clear()));
    }
  }

  void _flushDebounce() {
    if (_debounce?.isActive ?? true) {
      _debounce!.cancel();
      _search();
    }
  }

  void _onSearchChanged() {
    String curr = _textController.text;
    if (curr != _lastQuery) {
      _lastQuery = curr;
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _search);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        Focus(
          focusNode: _keyNode,
          onKeyEvent: _onKey,
          child: Builder(
            builder: (BuildContext ctx) {
              SearchList relevantList = getRelevantList();

              if (relevantList.items.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 350,
                child: ScrollablePositionedList.builder(
                  physics: const ClampingScrollPhysics(),
                  itemScrollController: _scroll,
                  itemCount: relevantList.items.length,
                  itemBuilder: (context, dynamic i) {
                    SearchItem info = relevantList.items[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          info.imgUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.broken_image),
                        ),
                      ),
                      selected: i == relevantList.selected,
                      selectedColor: Color(0xFF1DB954),
                      titleTextStyle: Theme.of(context).textTheme.titleMedium,
                      subtitleTextStyle: Theme.of(context).textTheme.labelSmall,
                      title: Text(info.name),
                      subtitle: Text(info.artist),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
