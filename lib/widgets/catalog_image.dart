import 'package:flutter/material.dart';

class CatalogImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final String fallbackAsset;

  const CatalogImage({
    Key key,
    @required this.imagePath,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/popular_foods/ic_popular_food_1.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String path = imagePath == null ? '' : imagePath.trim();
    if (_isNetworkUrl(path)) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallbackAsset, fit: fit);
        },
      );
    }

    return Image.asset(path.isEmpty ? fallbackAsset : path, fit: fit);
  }

  bool _isNetworkUrl(String value) {
    final Uri uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
