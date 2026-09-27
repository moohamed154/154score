import 'package:flutter_test/flutter_test.dart';
import 'package:score154/core/utils/date_formatter.dart';
import 'package:score154/core/utils/match_status_helper.dart';
import 'package:score154/features/matches/data/models/match_dto.dart';

void main() {
  group('DateFormatter.formatDisplayTime', () {
    test('formats 24h correctly', () {
      expect(
        DateFormatter.formatDisplayTime(
          '20:30',
          timeFormat: '24h',
          isArabic: true,
        ),
        '20:30',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '08:15',
          timeFormat: '24h',
          isArabic: false,
        ),
        '08:15',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '00:05',
          timeFormat: '24h',
          isArabic: false,
        ),
        '00:05',
      );
    });

    test('formats 12h Arabic correctly with م and ص', () {
      expect(
        DateFormatter.formatDisplayTime(
          '20:30',
          timeFormat: '12h',
          isArabic: true,
        ),
        '08:30 م',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '08:15',
          timeFormat: '12h',
          isArabic: true,
        ),
        '08:15 ص',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '12:00',
          timeFormat: '12h',
          isArabic: true,
        ),
        '12:00 م',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '00:45',
          timeFormat: '12h',
          isArabic: true,
        ),
        '12:45 ص',
      );
    });

    test('formats 12h English correctly with PM and AM', () {
      expect(
        DateFormatter.formatDisplayTime(
          '20:30',
          timeFormat: '12h',
          isArabic: false,
        ),
        '08:30 PM',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '08:15',
          timeFormat: '12h',
          isArabic: false,
        ),
        '08:15 AM',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '12:00',
          timeFormat: '12h',
          isArabic: false,
        ),
        '12:00 PM',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '00:45',
          timeFormat: '12h',
          isArabic: false,
        ),
        '12:45 AM',
      );
    });

    test('handles already-tagged strings gracefully', () {
      expect(
        DateFormatter.formatDisplayTime(
          '08:30 م',
          timeFormat: '24h',
          isArabic: true,
        ),
        '20:30',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '08:30 PM',
          timeFormat: '24h',
          isArabic: false,
        ),
        '20:30',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '08:30 AM',
          timeFormat: '12h',
          isArabic: true,
        ),
        '08:30 ص',
      );
    });

    test('formats time strings with seconds (HH:mm:ss) correctly in 24h and 12h', () {
      expect(
        DateFormatter.formatDisplayTime(
          '21:45:00',
          timeFormat: '24h',
          isArabic: true,
        ),
        '21:45',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '21:45:00',
          timeFormat: '12h',
          isArabic: true,
        ),
        '09:45 م',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '21:45:00',
          timeFormat: '12h',
          isArabic: false,
        ),
        '09:45 PM',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '22:45:00',
          timeFormat: '12h',
          isArabic: true,
        ),
        '10:45 م',
      );
      expect(
        DateFormatter.formatDisplayTime(
          '2026-09-27 21:45:00',
          timeFormat: '24h',
          isArabic: true,
        ),
        '21:45',
      );
    });

    test('handles empty and dash strings', () {
      expect(
        DateFormatter.formatDisplayTime('-', timeFormat: '12h', isArabic: true),
        '-',
      );
      expect(
        DateFormatter.formatDisplayTime('', timeFormat: '12h', isArabic: true),
        '-',
      );
      expect(
        DateFormatter.formatDisplayTime(
          null,
          timeFormat: '12h',
          isArabic: true,
        ),
        '-',
      );
    });
  });

  group('MatchStatusHelper timestamp and timezone independence', () {
    test('future UTC timestamp is ALWAYS upcoming regardless of local/shifted time string', () {
      final nowUtc = DateTime.now().toUtc();
      // Match kickoff is 2 hours in the future
      final futureTimestamp = (nowUtc.millisecondsSinceEpoch ~/ 1000) + 7200;

      // Suppose local clock is 20:00, but API sent time shifted to UTC-3 as "14:00"
      // Naively 20:00 - 14:00 = 6 hours elapsed, which would flip to finished/live if string was used!
      final phase = MatchStatusHelper.parseStatus(
        'لم تبدأ',
        statusCode: 'UPCOMING',
        time: '14:00',
        timestamp: futureTimestamp,
      );

      expect(phase, MatchPhase.upcoming);
    });

    test('past UTC timestamp within match duration without finished indicator is live', () {
      final nowUtc = DateTime.now().toUtc();
      // Match started 30 minutes ago
      final liveTimestamp = (nowUtc.millisecondsSinceEpoch ~/ 1000) - 1800;

      final phase = MatchStatusHelper.parseStatus(
        'مباشر',
        statusCode: 'LIVE',
        time: '20:00',
        timestamp: liveTimestamp,
      );

      expect(phase, MatchPhase.live);
    });
  });

  group('MatchDto timestamp parsing', () {
    test('parses timestamp and match_timestamp correctly', () {
      final json1 = {
        'team_1': 'Al Ahly',
        'team_2': 'Zamalek',
        'timestamp': 1774396800,
      };
      final dto1 = MatchDto.fromJson(json1);
      expect(dto1.timestamp, 1774396800);
      expect(dto1.toEntity().timestamp, 1774396800);

      final json2 = {
        'team_1': 'Arsenal',
        'team_2': 'Chelsea',
        'match_timestamp': '1774396900',
      };
      final dto2 = MatchDto.fromJson(json2);
      expect(dto2.timestamp, 1774396900);
      expect(dto2.toEntity().timestamp, 1774396900);
    });
  });
}
