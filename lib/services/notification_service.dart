import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../app/routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String workoutChannelId = 'workout_session_v3';
  static const String workoutChannelName = 'Workout Active';
  static const String workoutChannelDescription = 'Ongoing notifications for active workout sessions';

  static const String alertChannelId = 'workout_alert_v3';
  static const String alertChannelName = 'Workout Alerts';
  static const String alertChannelDescription = 'Urgent alerts for rest timer completion';

  static const String chronoChannelId = 'chrono_timer_v1';
  static const String chronoChannelName = 'Timer & Stopwatch';
  static const String chronoChannelDescription = 'Ongoing countdown timer and stopwatch notifications';

  final _actionController = StreamController<String>.broadcast();
  Stream<String> get actionStream => _actionController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    if (!Platform.isAndroid && !Platform.isIOS) {
      _isInitialized = true;
      return;
    }

    try {
      const settingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings =
          InitializationSettings(android: settingsAndroid, iOS: settingsIOS);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.actionId != null) {
            _actionController.add(details.actionId!);
          } else if (details.payload != null) {
            _actionController.add(details.payload!);
          }
        },
      );

      if (Platform.isAndroid) {
        final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          workoutChannelId,
          workoutChannelName,
          description: workoutChannelDescription,
          importance: Importance.max,
          showBadge: true,
          enableVibration: false,
          playSound: false,
          ledColor: Color(0xFFE94560),
        );

        const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
          alertChannelId,
          alertChannelName,
          description: alertChannelDescription,
          importance: Importance.max,
          showBadge: false,
          enableVibration: true,
          playSound: true,
        );

        const AndroidNotificationChannel chronoChannel = AndroidNotificationChannel(
          chronoChannelId,
          chronoChannelName,
          description: chronoChannelDescription,
          importance: Importance.low,
          showBadge: false,
          enableVibration: false,
          playSound: false,
          ledColor: Color(0xFFE94560),
        );

        await androidImplementation?.createNotificationChannel(channel);
        await androidImplementation?.createNotificationChannel(alertChannel);
        await androidImplementation?.createNotificationChannel(chronoChannel);
      }

      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('GRIT ERROR: Failed to initialize Notification Service: $e');
      debugPrint('GRIT ERROR: Stack: $stack');
      _isInitialized = false;
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> updateWorkoutNotification({
    required String sessionName,
    String? exerciseName,
    String? setInfo,
    String? weightInfo,
    String? repsInfo,
    String? nextSetInfo,
    String? nextWeightRepsInfo,
    DateTime? startedAt,
    bool isResting = false,
    bool isFinished = false,
    int? progressMax,
    int? progressCurrent,
    int? restSecondsRemaining,
    int? currentVariation,
    int? totalVariations,
    int? sessionId,
  }) async {
    if (!_isInitialized) {
      await init();
    }
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isLimited) {
        return;
      }
    }

    final String title = isFinished 
        ? 'WORKOUT COMPLETED' 
        : (exerciseName?.toUpperCase() ?? sessionName.toUpperCase());
    
    final String header = sessionName.toUpperCase();
    
    String body;
    if (isFinished) {
      body = 'PROUD OF YOU. SESSION COMPLETE.';
    } else if (isResting) {
      final restSecs = restSecondsRemaining ?? 0;
      if (restSecs <= 0) {
        body = 'TIME TO LIFT';
      } else {
        if (nextSetInfo != null) {
          final String nextDetail = nextWeightRepsInfo != null ? ' ($nextWeightRepsInfo)' : '';
          body = 'Next: $nextSetInfo$nextDetail';
        } else {
          body = 'READY FOR NEXT SET';
        }
      }
    } else {
      final List<String> parts = [];
      if (currentVariation != null && totalVariations != null && totalVariations > 0) {
        parts.add('VARIATION $currentVariation OF $totalVariations');
      }
      
      if (setInfo != null) parts.add(setInfo);
      
      body = parts.join(' \u2022 ').toUpperCase();
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      workoutChannelId,
      workoutChannelName,
      channelDescription: workoutChannelDescription,
      importance: (isResting && restSecondsRemaining == 0) ? Importance.max : (isFinished ? Importance.defaultImportance : Importance.max),
      priority: (isResting && restSecondsRemaining == 0) ? Priority.max : (isFinished ? Priority.defaultPriority : Priority.max),
      ongoing: !isFinished,
      autoCancel: isFinished,
      showWhen: true,
      when: isResting ? (DateTime.now().add(Duration(seconds: restSecondsRemaining ?? 0)).millisecondsSinceEpoch) : startedAt?.millisecondsSinceEpoch,
      usesChronometer: (startedAt != null && !isFinished) || isResting,
      chronometerCountDown: isResting,
      color: const Color(0xFFE94560),
      colorized: false, 
      icon: '@mipmap/ic_launcher',
      playSound: (isResting && restSecondsRemaining == 0),
      onlyAlertOnce: true,
      showProgress: false, // Using native chronometer instead
      subText: header,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.workout,
      ticker: 'GRIT: $title',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: header,
      ),
      actions: <AndroidNotificationAction>[
        if (!isResting && !isFinished)
          const AndroidNotificationAction('log_set', 'LOG SET', showsUserInterface: true),
        if (isResting && !isFinished)
          const AndroidNotificationAction('skip_rest', 'SKIP REST', showsUserInterface: true),
        if (!isFinished)
          const AndroidNotificationAction('finish_workout', 'FINISH', showsUserInterface: true, titleColor: Color(0xFFE94560)),
      ],
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: (isResting && restSecondsRemaining == 0) || isFinished,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: (isResting && restSecondsRemaining == 0) 
          ? InterruptionLevel.timeSensitive 
          : InterruptionLevel.active,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        100,
        title,
        setInfo ?? 'Active Session',
        details,
        payload: isFinished && sessionId != null 
            ? GritRoutes.workoutSummary(sessionId) 
            : GritRoutes.activeWorkout,
      );
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to show workout notification: $e');
    }
  }

  Future<void> cancelWorkoutNotification() async {
    if (!_isInitialized) await init();
    await _notifications.cancel(100);
    await _notifications.cancel(101);
  }

  /// Shows an ongoing notification for the standalone chrono countdown timer.
  Future<void> showChronoTimerNotification({
    required int secondsRemaining,
    required int totalSeconds,
  }) async {
    if (!_isInitialized) await init();

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isLimited) return;
    }

    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final elapsed = totalSeconds - secondsRemaining;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      chronoChannelId,
      chronoChannelName,
      channelDescription: chronoChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: totalSeconds,
      progress: elapsed,
      color: const Color(0xFFE94560),
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      ticker: 'GRIT TIMER: $timeStr',
      styleInformation: BigTextStyleInformation(
        'TIME REMAINING: $timeStr',
        contentTitle: 'COUNTDOWN TIMER',
        summaryText: 'GRIT',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(102, 'COUNTDOWN TIMER', 'TIME REMAINING: $timeStr', details);
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to show chrono timer notification: $e');
    }
  }

  /// Shows an ongoing notification for the standalone stopwatch.
  Future<void> showStopwatchNotification({
    required int elapsedSeconds,
  }) async {
    if (!_isInitialized) await init();

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isLimited) return;
    }

    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      chronoChannelId,
      chronoChannelName,
      channelDescription: chronoChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      color: Color(0xFFE94560),
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      ticker: 'GRIT STOPWATCH',
      styleInformation: BigTextStyleInformation(
        'STOPWATCH RUNNING',
        contentTitle: 'STOPWATCH',
        summaryText: 'GRIT',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(103, 'STOPWATCH', timeStr, details);
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to show stopwatch notification: $e');
    }
  }

  /// Shows a completion alert when the chrono timer reaches zero.
  Future<void> showChronoCompleteAlert() async {
    if (!_isInitialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: true,
      color: Color(0xFFE94560),
      colorized: true,
      icon: '@mipmap/ic_launcher',
      timeoutAfter: 5000,
      fullScreenIntent: true,
      ticker: 'GRIT: TIMER COMPLETE',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(102, 'TIMER COMPLETE', "TIME TO GO!", details);
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to show chrono complete alert: $e');
    }
  }

  /// Cancels the chrono timer / stopwatch ongoing notifications.
  Future<void> cancelChronoNotification() async {
    if (!_isInitialized) await init();
    await _notifications.cancel(102);
    await _notifications.cancel(103);
  }

  Future<void> showRestCompleteAlert({String? exerciseName}) async {
    if (!_isInitialized) await init();

    final String title = 'REST COMPLETE';
    final String body = exerciseName != null 
        ? 'TIME TO LIFT \u2022 ${exerciseName.toUpperCase()}'
        : 'TIME TO LIFT';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: true,
      onlyAlertOnce: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      color: Color(0xFFE94560),
      colorized: true,
      icon: '@mipmap/ic_launcher',
      timeoutAfter: 5000,
      fullScreenIntent: true,
      ticker: 'GRIT: REST COMPLETE',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      101,
      title,
      body,
      details,
    );
  }

  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  Future<void> scheduleRestCompleteNotification({
    required int seconds,
    String? exerciseName,
  }) async {
    if (!_isInitialized) await init();

    final String title = 'REST COMPLETE';
    final String body = exerciseName != null 
        ? 'TIME TO LIFT \u2022 ${exerciseName.toUpperCase()}'
        : 'TIME TO LIFT';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: true,
      onlyAlertOnce: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      color: const Color(0xFFE94560),
      colorized: true,
      icon: '@mipmap/ic_launcher',
      timeoutAfter: 5000,
      fullScreenIntent: true,
      ticker: 'GRIT: REST COMPLETE',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.cancel(101);

      if (seconds > 0) {
        tz.TZDateTime scheduledTime;
        try {
          scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
        } catch (tzError) {
          debugPrint('GRIT WARNING: Timezone resolution failed, falling back to UTC: $tzError');
          scheduledTime = tz.TZDateTime.now(tz.UTC).add(Duration(seconds: seconds));
        }

        await _notifications.zonedSchedule(
          101,
          title,
          body,
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('GRIT: Scheduled background rest alert in $seconds seconds at $scheduledTime');
      }
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to schedule rest complete notification: $e');
    }
  }

  Future<void> cancelScheduledRestNotification() async {
    if (!_isInitialized) await init();
    try {
      await _notifications.cancel(101);
      debugPrint('GRIT: Cancelled scheduled background rest alert');
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to cancel scheduled rest notification: $e');
    }
  }
}
