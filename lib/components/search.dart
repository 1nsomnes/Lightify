import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({
    super.key,
    required this.token,
    required this.deviceId,
    required this.skip,
    required this.prev,
    required this.pause,
  });

  final String token;
  final String deviceId;

  final Function skip;
  final Function prev;
  final Function pause;

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final FocusNode _keyNode = FocusNode();
  final FocusNode _searchNode = FocusNode();
  final ScrollController _scroll = ScrollController();
  int _selected = -1;

  final _textController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, String>> _results = [];

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
          _selected = (_selected + 1).clamp(0, _results.length - 1);
        });
        _scroll.animateTo(
          _selected * 56.0,
          duration: Duration(milliseconds: 100),
          curve: Curves.ease,
        );

      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyK:
        setState(() {
          _selected = (_selected - 1).clamp(0, _results.length - 1);
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
        if (_selected >= 0 && _selected < _results.length) {
          var ctxUri = _results[_selected]["ctxUri"];
          if (ctxUri != null) {
            queue(ctxUri, widget.token);
          }
        }
      case LogicalKeyboardKey.space:
        widget.pause();
      case LogicalKeyboardKey.keyP:
        widget.prev();
      case LogicalKeyboardKey.keyN:
        widget.skip();
      case LogicalKeyboardKey.enter:
        if (_selected >= 0 && _selected < _results.length) {
          var ctxUri = _results[_selected]["ctxUri"];
          if (ctxUri != null) {
            playSongs([ctxUri], widget.token, deviceId: widget.deviceId);
          }
        }

      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _populateResults(String query) async {
    final response = await searchSpotify(query, 20, 0, widget.token);
    final json = jsonDecode(response.body);
    setState(() {
      _results.clear();
      //debugPrint(json["tracks"]["items"].toString());
      List<dynamic> tracks = json["tracks"]["items"];

      for (dynamic track in tracks) {
        Map<String, String> values = <String, String>{};
        values["name"] = track["name"];
        values["artist"] = track["artists"][0]["name"];
        values["imgUrl"] = track["album"]["images"][2]["url"];
        values["ctxUri"] = track["uri"];

        _results.add(values);
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = _textController.text.trim();
      debugPrint("searching");
      if (query.isNotEmpty) {
        _populateResults(query);
      } else {
        setState(() => _results.clear());
      }
    });
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
              if (_results.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 350,
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: _results.length,
                  itemBuilder: (context, dynamic i) {
                    dynamic info = _results[i];
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
                      onTap: () {
                        playSongs(
                          [info["ctxUri"]],
                          widget.token,
                          deviceId: widget.deviceId,
                        );
                      },
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
