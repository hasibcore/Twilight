import 'package:flutter_test/flutter_test.dart';
import 'package:melody_tube/core/utils/formatters.dart';

void main() {
  test('formatDuration under hour', () {
    final d = Duration(minutes: 3, seconds: 5);
    expect(Formatters.formatDuration(d), '03:05');
  });

  test('formatDuration with hours', () {
    final d = Duration(hours: 2, minutes: 4, seconds: 9);
    expect(Formatters.formatDuration(d), '2:04:09');
  });

  test('formatSeconds delegates to formatDuration', () {
    expect(Formatters.formatSeconds(65), '01:05');
  });

  test('formatViews formatting', () {
    expect(Formatters.formatViews(999), '999');
    expect(Formatters.formatViews(1000), '1.0K');
    expect(Formatters.formatViews(1500000), '1.5M');
    expect(Formatters.formatViews(2500000000), '2.5B');
  });

  test('parseFormattedDuration two part', () {
    expect(Formatters.parseFormattedDuration('03:05'), 185);
  });

  test('parseFormattedDuration three part', () {
    expect(Formatters.parseFormattedDuration('1:02:03'), 3723);
  });

  test('parseFormattedDuration invalid fallback', () {
    // parseFormattedDuration returns 0 when parts are unparsable (m/s fallback to 0)
    expect(Formatters.parseFormattedDuration('bad:data'), 0);
  });
}
