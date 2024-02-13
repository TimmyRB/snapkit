class SnapchatUser {
  /// The unique ID of the user in your app.
  /// This ID is unqiue to every user and unqiue to your app.
  final String externalId;

  /// The user's OIDC (OpenID Connect) token.
  final String openIdToken;

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
    this.openIdToken,
    this.displayName,
    this.bitmoji2DAvatarUrl,
    this.bitmojiAvatarId,
  );

  SnapchatUser.fromJson(Map<String, dynamic> json)
      : externalId = json['externalId'],
        openIdToken = json['openIdToken'],
        displayName = json['displayName'],
        bitmoji2DAvatarUrl = json['bitmoji2DAvatarUrl'],
        bitmojiAvatarId = json['bitmojiAvatarId'];
}
