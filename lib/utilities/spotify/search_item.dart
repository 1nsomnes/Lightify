class SearchItem {
  final String name;
  final String artist;
  final String imgUrl;
  final String ctxUri;
  // spotify:artist:… for tracks/albums, spotify:user:… for playlists
  final String? creatorUri;
  // spotify:album:… for tracks (albums link to themselves via ctxUri)
  final String? albumUri;

  const SearchItem({
    required this.name,
    required this.artist,
    required this.imgUrl,
    required this.ctxUri,
    this.creatorUri,
    this.albumUri,
  });
}
