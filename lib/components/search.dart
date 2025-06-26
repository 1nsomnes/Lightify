import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({super.key, required this.token});

  final String token;

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, String>> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _populateResults(String query) async {
    final response = await searchSpotify(query, 20, 0, widget.token);
    final json = jsonDecode(response.body);
    setState(() {
      _results.clear();
      //debugPrint(json["tracks"]["items"].toString());
      List<dynamic> tracks = json["tracks"]["items"];

      for (dynamic track in tracks) {
        Map<String, String> values = Map<String, String>();
        debugPrint("TRACK!!");
        debugPrint(track.toString());
        debugPrint(track["album"]["images"].toString());
        values["name"] = track["name"];
        values["artist"] = track["artists"][0]["name"];
        values["url"] = track["album"]["images"][2]["url"];

        _results.add(values);
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = _controller.text.trim();
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
            controller: _controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Type to search…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ),
        Builder(
          builder: (BuildContext ctx) {
            if (_results.isEmpty) return const SizedBox.shrink();

            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, dynamic i) {
                  dynamic info = _results[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        info['url'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(info["name"]),
                    subtitle: Text(info["artist"]),
                    onTap: () {
                      // do something with item
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
