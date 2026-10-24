import 'package:flutter_test/flutter_test.dart';
import 'package:app_routine/core/services/notification_service.dart';
import 'package:app_routine/core/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Full Screen Intent & Notification Tests', () {
    test('NotificationService tracks alarm screen open state', () {
      expect(NotificationService.isAlarmScreenOpen, isFalse);
      NotificationService.isAlarmScreenOpen = true;
      expect(NotificationService.isAlarmScreenOpen, isTrue);
      NotificationService.isAlarmScreenOpen = false;
      expect(NotificationService.isAlarmScreenOpen, isFalse);
    });

    test('SystemPermissionStatus handles full screen intent and count', () {
      const status = SystemPermissionStatus(
        hasNotification: true,
        hasExactAlarm: true,
        hasBatteryOptimizationExemption: true,
      );
      expect(status.isAllGranted, isTrue);
      expect(status.grantedCount, equals(3));
    });
  });
}
