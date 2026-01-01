import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/helpers/helper.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ProfileImageCacheManager extends CacheManager {
  static const key = 'profileImageCache';
  static final ProfileImageCacheManager _instance =
      ProfileImageCacheManager._internal();

  factory ProfileImageCacheManager() => _instance;

  ProfileImageCacheManager._internal()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}

String normalizeImageCacheKey(String rawUrl) {
  final uri = Uri.parse(rawUrl.trim());

  return uri
      .replace(
        scheme: uri.scheme.toLowerCase(),
        host: uri.host.toLowerCase(),
        query: '', // remove tokens / tracking params
        fragment: '',
      )
      .toString();
}

class CustomProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const CustomProfileImage({
    super.key,
    this.imageUrl,
    this.username,
    this.radius = 40.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final String initials = Helper.getInitials(username);
    final Color bgColor = Colors.blue; //here color
    final double diameter = radius * 2;
    Widget avatarContent;
    final normalizedKey = normalizeImageCacheKey(imageUrl!);
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      avatarContent = CachedNetworkImage(
        cacheKey: normalizedKey,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        cacheManager: ProfileImageCacheManager(),
        imageUrl: imageUrl!.trim(),
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(initials, bgColor),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(initials, bgColor),
        imageBuilder: (context, imageProvider) =>
            _buildImageAvatar(imageProvider),
        memCacheWidth: diameter.toInt(),
        memCacheHeight: diameter.toInt(),
      );
    } else {
      avatarContent = _buildInitialsAvatar(initials, bgColor);
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: borderColor ?? Colors.white, width: borderWidth)
            : null,
      ),
      child: ClipOval(child: avatarContent),
    );
  }

  Widget _buildImageAvatar(ImageProvider imageProvider) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize:
              radius *
              0.75, // Matches React's ~text-lg + size*0.3 feel perfectly
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String initials, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildInitialsAvatar(initials, bgColor),
          Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> clearProfileImageCache() async {
    await ProfileImageCacheManager().emptyCache();
  }
}
