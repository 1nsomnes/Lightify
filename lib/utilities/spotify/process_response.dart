import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_result.dart';

class ProcessResponse {
  static SearchResult parseSearchResults(dynamic json) {

    List<dynamic> tracks = json["tracks"]["items"];
    List<dynamic> albums = json["albums"]["items"];
    List<dynamic> playlists = json["playlists"]["items"];

    SearchResult result = SearchResult(); 

    for (dynamic track in tracks) {
      var item = SearchItem(
        name: track["name"],
        artist: track["artists"][0]["name"],
        imgUrl: track["album"]["images"][2]["url"],
        ctxUri: track["uri"],
      );
      result.tracks.add(item);
    }

    for (dynamic album in albums) {
      var item = SearchItem(
        name: album["name"],
        artist: album["artists"][0]["name"],
        imgUrl: album["images"][2]["url"],
        ctxUri: album["uri"],
      );
      result.albums.add(item);
    }

    for (dynamic playlist in playlists) {
      //debugPrint(playlist.toString());
      if(playlist == null) continue;
      var item = SearchItem(
        name: playlist["name"] ?? "",
        artist: playlist["owner"]["display_name"] ?? "",
        imgUrl: playlist["images"][0]["url"] ?? "",
        ctxUri: playlist["uri"] ?? "",
      );
      result.playlists.add(item);
    }

    return result;
  }
}
