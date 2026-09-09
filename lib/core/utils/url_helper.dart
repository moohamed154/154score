import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  UrlHelper._();

  /// Normalizes image and asset URLs from the API.
  /// Handles protocol-relative URLs (`//imgs...`), non-secure `http:`, and trims whitespace.
  static String? normalizeImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty ||
        trimmed == 'null' ||
        trimmed == 'undefined' ||
        trimmed == '0' ||
        trimmed == '-1') {
      return null;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    if (trimmed.startsWith('http://')) {
      return trimmed.replaceFirst('http://', 'https://');
    }

    if (trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('/')) {
      return 'https://www.ysscores.com$trimmed';
    }

    // Only resolve known CDN relative filenames (e.g. numeric filenames "9541690196746.png" or paths like "teams/150/...")
    if (trimmed.endsWith('.png') ||
        trimmed.endsWith('.jpg') ||
        trimmed.endsWith('.jpeg') ||
        trimmed.endsWith('.webp')) {
      if (RegExp(r'^\d+\.(png|jpg|jpeg|webp)$', caseSensitive: false).hasMatch(trimmed)) {
        return 'https://imgs.ysscores.com/teams/150/$trimmed';
      } else if (trimmed.startsWith('teams/') ||
          trimmed.startsWith('player/') ||
          trimmed.startsWith('championship/') ||
          trimmed.startsWith('flags/') ||
          trimmed.startsWith('country/')) {
        return 'https://imgs.ysscores.com/$trimmed';
      }
    }

    return trimmed;
  }

  /// Checks if a normalized URL is a valid web image URL.
  static bool isValidImageUrl(String? url) {
    final normalized = normalizeImageUrl(url);
    if (normalized == null) return false;

    final lower = normalized.toLowerCase();

    // 1. Android ImageDecoder cannot decode SVGs (causes DecodeException 'unimplemented')
    if (lower.endsWith('.svg') || lower.contains('.svg?')) {
      return false;
    }

    // 2. Reject known broken CDN paths that return HTTP 200 text/html (<!-- 404 -->)
    if (lower.contains('/champ/64/')) {
      return false;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (!uri.isScheme('http') && !uri.isScheme('https')) ||
        !uri.hasAuthority) {
      return false;
    }

    return true;
  }

  /// Resolves canonical championship logo for known competitions if current logo is missing or broken.
  static String? resolveChampionshipLogo(String? leagueId, {String? currentLogo}) {
    if (currentLogo != null && isValidImageUrl(currentLogo)) {
      return currentLogo;
    }
    return switch (leagueId) {
      '12048' || '943230' || '288' || '904988' =>
        'https://imgs.ysscores.com/championship/128/5171696546919.png', // UEFA Champions League
      '6811' || '937599' || '284' =>
        'https://imgs.ysscores.com/championship/128/3411694791422.png', // Premier League
      '1933' || '938652' || '285' =>
        'https://imgs.ysscores.com/championship/128/8641690196626.png', // LaLiga
      '3734' || '936357' || '287' =>
        'https://imgs.ysscores.com/championship/128/6281692568873.png', // Serie A
      '2606' || '938769' || '286' =>
        'https://imgs.ysscores.com/championship/128/6171690288722.png', // Bundesliga
      '1985' || '937873' =>
        'https://imgs.ysscores.com/championship/128/9551719862665.png', // Ligue 1
      '7167' || '941825' =>
        'https://imgs.ysscores.com/championship/128/2121751062605.png', // Saudi Pro League
      '88013' || '59771441' =>
        'https://imgs.ysscores.com/championship/128/5481703687014.png', // Supercopa
      '943009' =>
        'https://imgs.ysscores.com/championship/128/451723403406.png', // Egyptian League
      _ => null,
    };
  }

  /// Normalizes video URLs from various API fields and video providers.
  /// Safely resolves YouTube links, embeds, direct streams, and protocol-relative URLs.
  static String? normalizeVideoUrl(String? url, {String? thumbnail}) {
    if (url == null && thumbnail == null) return null;

    String? candidate = url?.trim();

    if (candidate != null &&
        candidate.isNotEmpty &&
        candidate != 'null' &&
        candidate != 'undefined') {
      // Protocol-relative URL
      if (candidate.startsWith('//')) {
        candidate = 'https:$candidate';
      } else if (candidate.startsWith('/')) {
        candidate = 'https://www.ysscores.com$candidate';
      }

      // Check if it's already a direct video platform or stream link
      if (candidate.startsWith('https://www.youtube.com') ||
          candidate.startsWith('https://m.youtube.com') ||
          candidate.startsWith('https://youtu.be') ||
          candidate.startsWith('http://www.youtube.com') ||
          candidate.startsWith('http://youtu.be') ||
          candidate.contains('vimeo.com') ||
          candidate.contains('dailymotion.com') ||
          candidate.contains('x.com') ||
          candidate.contains('twitter.com') ||
          candidate.endsWith('.mp4') ||
          candidate.endsWith('.m3u8')) {
        return candidate;
      }
    }

    // Fallback: If URL is an internal webpage or missing, extract YouTube ID from thumbnail
    if (thumbnail != null && thumbnail.isNotEmpty) {
      final ytMatch = RegExp(r'vi(?:_webp)?/([a-zA-Z0-9_-]{11})')
          .firstMatch(thumbnail);
      if (ytMatch != null && ytMatch.group(1) != null) {
        return 'https://www.youtube.com/watch?v=${ytMatch.group(1)}';
      }
    }

    // Return candidate if it is a valid HTTP/HTTPS URL
    if (candidate != null &&
        (candidate.startsWith('http://') || candidate.startsWith('https://'))) {
      return candidate;
    }

    return null;
  }

  /// Validates whether a video URL is non-empty and well-formed.
  static bool isValidVideoUrl(String? url) {
    final normalized = normalizeVideoUrl(url);
    if (normalized == null) return false;
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.hasAuthority;
  }

  /// Safely launches a video URL in the external application/browser.
  /// Handles failures gracefully and presents a user-friendly message.
  static Future<bool> launchVideoUrl(
    String? url, {
    String? thumbnail,
    BuildContext? context,
    String? fallbackErrorMessage,
  }) async {
    final targetUrl = normalizeVideoUrl(url, thumbnail: thumbnail) ?? url;

    if (targetUrl == null || targetUrl.trim().isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'رابط الفيديو غير متوفر'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final uri = Uri.tryParse(targetUrl.trim());
    if (uri == null) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'رابط الفيديو غير صالح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'تعذر فتح مشغل الفيديو'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return launched;
    } catch (_) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (launched) return true;
      } catch (_) {}
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'تعذر تشغيل الفيديو'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Universal video navigator: navigates to internal app route or launches external video URL.
  static Future<bool> navigateToVideo(
    BuildContext context, {
    required String? url,
    String? thumbnail,
    String? fallbackErrorMessage,
  }) async {
    if (url == null || url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'رابط الفيديو غير متوفر'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    final trimmed = url.trim();

    // Check internal route or video ID
    final videoMatch = RegExp(r'/video/(\d+)').firstMatch(trimmed);
    if (videoMatch != null) {
      unawaited(context.push('/video/${videoMatch.group(1)}'));
      return true;
    }

    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      unawaited(context.push('/video/$trimmed'));
      return true;
    }

    if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
      unawaited(context.push(trimmed));
      return true;
    }

    // External URL or stream (e.g. x.com, youtube, web)
    return launchVideoUrl(
      trimmed,
      thumbnail: thumbnail,
      context: context,
      fallbackErrorMessage: fallbackErrorMessage,
    );
  }

  /// Safely launches any external URL in the browser or external application.
  static Future<bool> launchExternalUrl(
    String? url, {
    BuildContext? context,
    String? fallbackErrorMessage,
  }) async {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim();
    final uri = Uri.tryParse(
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : 'https://$trimmed',
    );
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackErrorMessage ?? 'تعذر فتح الرابط'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Safely decodes a URI component or slug without throwing an [ArgumentError] on illegal percent encodings.
  static String safeDecodeComponent(String input) {
    if (input.isEmpty) return input;
    try {
      return Uri.decodeComponent(input);
    } catch (_) {
      try {
        return Uri.decodeFull(input);
      } catch (_) {
        return input;
      }
    }
  }

  /// Converts a URL slug into a clean human-readable name safely.
  static String slugToName(String slug) {
    if (slug.isEmpty) return slug;
    return safeDecodeComponent(slug).replaceAll('-', ' ').trim();
  }
}
