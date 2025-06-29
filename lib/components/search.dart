import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightify/utilities/spotify.dart';
import 'package:http/http.dart' as http;

class Search extends StatefulWidget {
  const Search({
    super.key,
    required this.token,
    required this.deviceId,
    required this.skip,
    required this.prev,
    required this.pause,
    required this.setPlaying,
  });

  final String token;
  final String deviceId;

  final Function skip;
  final Function prev;
  final Function pause;

  final Function setPlaying;

  @override
  State<Search> createState() => _SearchState();
}

enum SearchKind { playlist, track, album }

class _SearchState extends State<Search> {
  final FocusNode _keyNode = FocusNode();
  final FocusNode _searchNode = FocusNode();
  final ScrollController _scroll = ScrollController();
  int _selected = -1;
  SearchKind searchKind = SearchKind.track;

  final _textController = TextEditingController();
  String _lastQuery = "";
  Timer? _debounce;

  // TODO: maybe add loading when searching?
  // bool _isLoading = false;
  final List<Map<String, String>> _tracks = [];
  final List<Map<String, String>> _playists = [];
  final List<Map<String, String>> _albums = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchNode.requestFocus();
    });
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

    switch (lk) {
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyJ:
        setState(() {
          _selected = (_selected + 1).clamp(0, _tracks.length - 1);
        });
        _scroll.animateTo(
          _selected * 56.0,
          duration: Duration(milliseconds: 100),
          curve: Curves.ease,
        );

      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyK:
        setState(() {
          _selected = (_selected - 1).clamp(0, _tracks.length - 1);
        });
        _scroll.animateTo(
          _selected * 56.0,
          duration: Duration(milliseconds: 100),
          curve: Curves.ease,
        );
      case LogicalKeyboardKey.keyS:
        setState(() => _selected = -1);
        _searchNode.requestFocus();

      case LogicalKeyboardKey.keyQ:
        if (_selected >= 0 && _selected < _tracks.length) {
          var ctxUri = _tracks[_selected]["ctxUri"];
          if (ctxUri != null) {
            makeNetworkCall(() {
              return queue(ctxUri, widget.token);
            });
          }
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
      case LogicalKeyboardKey.enter:
        var relevantList = getRelevantList();
        if (_selected >= 0 && _selected < relevantList.length) {
          var ctxUri = relevantList[_selected]["ctxUri"];
          playSelected(ctxUri);
        }

      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  List<Map<String, String>> getRelevantList() {
    if (searchKind == SearchKind.album) {
      return _albums;
    } else if (searchKind == SearchKind.track) {
      return _tracks;
    } else {
      return _playists;
    }
  }

  void updateAllLists(Function(List<Map<String, String>>) action) {
    action(_albums);
    action(_tracks);
    action(_playists);
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
          return playTracks([ctxUri], widget.token, deviceId: widget.deviceId);
        });
      } else {
        makeNetworkCall(() {
          return playPlaylistOrAlbums(
            ctxUri,
            widget.token,
            deviceId: widget.deviceId,
          );
        });
      }

      widget.setPlaying(true);
    }
  }

  void _populateResults(String query) async {
    setState(() {
      updateAllLists((list) => list.clear());
    });

    String body = await makeNetworkCall(
      () {
        return searchSpotify(query, 20, 0, widget.token);
      },
      process: (String body) {
        return body;
      },
    );
    final json = jsonDecode(body);

    setState(() {
      List<dynamic> tracks = json["tracks"]["items"];
      List<dynamic> albums = json["albums"]["items"];

      for (dynamic album in albums) {
        Map<String, String> values = <String, String>{};
        values["name"] = album["name"];
        values["artist"] = album["artists"][0]["name"];
        values["imgUrl"] = album["images"][2]["url"];
        values["ctxUri"] = album["uri"];

        _albums.add(values);
      }

      for (dynamic track in tracks) {
        Map<String, String> values = <String, String>{};
        values["name"] = track["name"];
        values["artist"] = track["artists"][0]["name"];
        values["imgUrl"] = track["album"]["images"][2]["url"];
        values["ctxUri"] = track["uri"];

        _tracks.add(values);
      }
    });
  }

  void _search() async {
    final query = _textController.text.trim();
    debugPrint("searching");
    if (query.isNotEmpty) {
      _populateResults(query);
    } else {
      setState(() => updateAllLists((list) => list.clear()));
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
                _selected = 0;
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
        Focus(
          focusNode: _keyNode,
          onKeyEvent: _onKey,
          child: Builder(
            builder: (BuildContext ctx) {
              var relevantList = getRelevantList();

              if (relevantList.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 350,
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: relevantList.length,
                  itemBuilder: (context, dynamic i) {
                    dynamic info = relevantList[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          info['imgUrl'] as String,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.broken_image),
                        ),
                      ),
                      selected: i == _selected,
                      title: Text(info["name"]),
                      subtitle: Text(info["artist"]),
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
