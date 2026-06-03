// ignore_for_file: avoid_print
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Back Navigation Test', () {
    FlutterDriver? driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('Back button from Workout tab redirects to This Week', () async {
      print('STEP: Ensuring we start on THIS WEEK');
      await driver!.waitFor(find.text('THIS WEEK'),
          timeout: const Duration(seconds: 10));

      print('STEP: Tapping WORKOUT tab');
      await driver!.tap(find.text('WORKOUT'));

      print('STEP: Waiting for WORKOUT screen to load');
      await driver!.waitFor(find.text('MY ROUTINES'),
          timeout: const Duration(seconds: 10));

      print('STEP: Simulating Hardware Back Button');
      final result =
          await Process.run('adb', ['shell', 'input', 'keyevent', '4']);
      if (result.exitCode != 0) {
        print('ERROR: adb command failed: ${result.stderr}');
      }

      // Delay to let the animation finish and logic process
      await Future.delayed(const Duration(seconds: 2));

      print('STEP: Verifying we are back on THIS WEEK screen');
      try {
        await driver!.waitFor(find.text('THIS WEEK'),
            timeout: const Duration(seconds: 10));
        print('SUCCESS: Back button redirected to dashboard.');
      } catch (e) {
        print('FAILURE: Did not return to THIS WEEK. Current state unknown.');
        // We can try to get the tree here
        rethrow;
      }
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('Back button from Detail page returns to list', () async {
      print('STEP: Navigating to WORKOUT');
      await driver!.tap(find.text('WORKOUT'));
      await driver!.waitFor(find.text('MY ROUTINES'),
          timeout: const Duration(seconds: 10));

      print('STEP: Tapping CHEST routine');
      await driver!.tap(find.text('CHEST'));

      print('STEP: Waiting for CHEST detail header');
      await driver!.waitFor(find.text('CHEST'),
          timeout: const Duration(seconds: 10));

      print('STEP: Simulating Hardware Back Button');
      await Process.run('adb', ['shell', 'input', 'keyevent', '4']);

      await Future.delayed(const Duration(seconds: 2));

      print('STEP: Verifying we are back on MY ROUTINES');
      await driver!.waitFor(find.text('MY ROUTINES'),
          timeout: const Duration(seconds: 10));

      print('SUCCESS: Back button from detail page returned to list.');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
