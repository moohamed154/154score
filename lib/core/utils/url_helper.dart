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
}
