import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  UrlHelper._();

  /// Normalizes image and asset URLs from the API.
  /// Handles protocol-relative URLs (`//imgs...`), non-secure `http:`, and trims whitespace.
  static String? normalizeImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'undefined') {
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

    return trimmed;
  }

  /// Checks if a normalized URL is a valid web image URL.
  static bool isValidImageUrl(String? url) {
    final normalized = normalizeImageUrl(url);
    if (normalized == null) return false;
    return normalized.startsWith('https://') ||
        normalized.startsWith('http://');
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
}
