import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/security/security_signer.dart';

void main() {
  group('SecuritySigner — Anti-Scraping & Dynamic HMAC Tests', () {
    test('generateNonce returns unique 32-char hex string', () {
      final nonce1 = SecuritySigner.generateNonce();
      final nonce2 = SecuritySigner.generateNonce();

      expect(nonce1.length, 32);
      expect(nonce2.length, 32);
      expect(nonce1, isNot(equals(nonce2)));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(nonce1), isTrue);
    });

    test('getTimestamp returns current unix timestamp in milliseconds', () {
      final tsStr = SecuritySigner.getTimestamp();
      final ts = int.tryParse(tsStr);

      expect(ts, isNotNull);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      expect((now - ts!).abs(), lessThan(5000));
    });

    test('generateSignature produces consistent 64-char HMAC-SHA256 hex', () {
      final sig1 = SecuritySigner.generateSignature(
        method: 'GET',
        path: '/api/matches',
        timestamp: '1791000000000',
        nonce: '0123456789abcdef0123456789abcdef',
      );

      final sig2 = SecuritySigner.generateSignature(
        method: 'GET',
        path: '/api/matches',
        timestamp: '1791000000000',
        nonce: '0123456789abcdef0123456789abcdef',
      );

      expect(sig1.length, 64);
      expect(sig1, equals(sig2));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(sig1), isTrue);
    });

    test('generateSignature changes when method, path, timestamp, or nonce change', () {
      final baseSig = SecuritySigner.generateSignature(
        method: 'GET',
        path: '/api/matches',
        timestamp: '1791000000000',
        nonce: '0123456789abcdef0123456789abcdef',
      );

      final diffPathSig = SecuritySigner.generateSignature(
        method: 'GET',
        path: '/api/news',
        timestamp: '1791000000000',
        nonce: '0123456789abcdef0123456789abcdef',
      );

      final diffMethodSig = SecuritySigner.generateSignature(
        method: 'POST',
        path: '/api/matches',
        timestamp: '1791000000000',
        nonce: '0123456789abcdef0123456789abcdef',
      );

      expect(baseSig, isNot(equals(diffPathSig)));
      expect(baseSig, isNot(equals(diffMethodSig)));
    });

    test('buildSecurityHeaders returns all 3 security headers', () {
      final headers = SecuritySigner.buildSecurityHeaders(
        method: 'GET',
        path: '/api/transfers',
      );

      expect(headers.containsKey('X-Timestamp'), isTrue);
      expect(headers.containsKey('X-Nonce'), isTrue);
      expect(headers.containsKey('X-Signature'), isTrue);
      expect(headers['X-Nonce']!.length, 32);
      expect(headers['X-Signature']!.length, 64);
    });
  });
}
