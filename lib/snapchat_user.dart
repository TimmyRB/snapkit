class SnapchatUser {
  /// The unique ID of the user in your app.
  /// This ID is unqiue to every user and unqiue to your app.
  final String externalId;

  /// The display name of the user.
  /// This is not their username and can be changed by the user.
  final String displayName;

  /// The URL to the user's Bitmoji 2D avatar.
  final String? bitmoji2DAvatarUrl;

  /// The ID of the user's Bitmoji avatar.
  /// This is used to fetch the avatar from Snapchat's servers.
  final String? bitmojiAvatarId;

  const SnapchatUser(
    this.externalId,
    this.displayName,
    this.bitmoji2DAvatarUrl,
    this.bitmojiAvatarId,
  );
}
