/// Social meta tags for link previews (Firebase API parity).
class SocialMetaTagParameters {
  final String? title;
  final String? description;
  final Uri? imageUrl;

  const SocialMetaTagParameters({
    this.title,
    this.description,
    this.imageUrl,
  });
}
