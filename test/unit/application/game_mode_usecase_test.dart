import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/application/use_cases/game_mode_usecase.dart';
import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/repositories/game_mode_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

class MockGameModeRepository implements GameModeRepository {
  GameMode? _currentMode;
  GameSettings? _adultSettings;
  final List<ModeChangeLog> _changeLogs = [];
  final List<ChildModeAttempt> _childAttempts = [];

  @override
  Future<GameMode?> getCurrentMode() async {
    return _currentMode;
  }

  @override
  Future<void> saveMode(GameMode mode) async {
    _currentMode = mode;
  }

  @override
  Future<void> saveAdultSettings(GameSettings settings) async {
    _adultSettings = settings;
  }

  @override
  Future<GameSettings?> getAdultSettings() async {
    return _adultSettings;
  }

  @override
  Future<GameMode> getLastUsedMode() async {
    return _currentMode ?? GameMode.adult();
  }

  @override
  Future<void> logModeChange({
    required GameMode fromMode,
    required GameMode toMode,
    required DateTime timestamp,
    String? reason,
  }) async {
    _changeLogs.add(
      ModeChangeLog(
        fromMode: fromMode,
        toMode: toMode,
        timestamp: timestamp,
        reason: reason,
      ),
    );
  }

  @override
  Future<void> logChildModeAttempt({
    required String attemptType,
    required DateTime timestamp,
  }) async {
    _childAttempts.add(
      ChildModeAttempt(attemptType: attemptType, timestamp: timestamp),
    );
  }

  @override
  Future<List<ChildModeAttempt>> getChildModeAttempts({
    Duration? period,
  }) async {
    if (period == null) return _childAttempts;

    final cutoff = DateTime.now().subtract(period);
    return _childAttempts
        .where((attempt) => attempt.timestamp.isAfter(cutoff))
        .toList();
  }

  @override
  Future<void> resetToDefaults() async {
    _currentMode = null;
    _adultSettings = null;
    _changeLogs.clear();
    _childAttempts.clear();
  }

  @override
  Stream<GameMode> get modeChanges => Stream.empty();
}

void main() {
  group('GameModeUseCase', () {
    late GameModeUseCase useCase;
    late MockGameModeRepository mockRepository;

    setUp(() {
      mockRepository = MockGameModeRepository();
      useCase = GameModeUseCase(mockRepository);
    });

    group('initialize', () {
      test('should return last used mode when available', () async {
        // Given
        final savedMode = GameMode.child();
        await mockRepository.saveMode(savedMode);

        // When
        final mode = await useCase.initialize();

        // Then
        expect(mode.isChildMode, isTrue);
      });

      test('should return default adult mode when no saved mode', () async {
        // Given
        // No saved mode in repository

        // When
        final mode = await useCase.initialize();

        // Then
        expect(mode.isAdultMode, isTrue);
        expect(mode.settings.treasureCount, equals(5));
      });
    });

    group('switchToChildMode', () {
      test('should switch from adult to child mode successfully', () async {
        // Given
        final adultMode = GameMode.adult();
        await mockRepository.saveMode(adultMode);

        // When
        final childMode = await useCase.switchToChildMode();

        // Then
        expect(childMode.isChildMode, isTrue);
        expect(childMode.settings.treasureCount, equals(3)); // Child-friendly
        expect(childMode.settings.discoveryRange, equals(2.0)); // Wider range

        // Verify adult settings were saved
        final savedAdultSettings = await mockRepository.getAdultSettings();
        expect(savedAdultSettings, isNotNull);
        expect(savedAdultSettings!.treasureCount, equals(5));
      });

      test('should log mode change when switching to child mode', () async {
        // Given
        final adultMode = GameMode.adult();
        await mockRepository.saveMode(adultMode);

        // When
        await useCase.switchToChildMode();

        // Then
        expect(mockRepository._changeLogs, hasLength(1));
        final log = mockRepository._changeLogs.first;
        expect(log.fromMode.isAdultMode, isTrue);
        expect(log.toMode.isChildMode, isTrue);
        expect(log.reason, equals('switched_to_child'));
      });

      test('should return current mode if already in child mode', () async {
        // Given
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        // When
        final result = await useCase.switchToChildMode();

        // Then
        expect(result.isChildMode, isTrue);
        expect(mockRepository._changeLogs, isEmpty); // No change logged
      });
    });

    group('switchToAdultMode', () {
      test('should switch from child to adult mode with long press', () async {
        // Given
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        final originalAdultSettings = GameSettings(
          treasureCount: 7,
          gameTimeLimit: const Duration(minutes: 12),
          discoveryRange: 1.5,
          showHints: false,
          playSounds: true,
        );
        await mockRepository.saveAdultSettings(originalAdultSettings);

        // When
        final adultMode = await useCase.switchToAdultModeWithLongPress();

        // Then
        expect(adultMode.isAdultMode, isTrue);
        expect(
          adultMode.settings.treasureCount,
          equals(7),
        ); // Restored settings
        expect(
          adultMode.settings.gameTimeLimit,
          equals(const Duration(minutes: 12)),
        );
      });

      test(
        'should throw exception when trying to switch without long press',
        () async {
          // Given
          final childMode = GameMode.child();
          await mockRepository.saveMode(childMode);

          // When & Then
          expect(
            () => useCase.switchToAdultMode(),
            throwsA(isA<UnauthorizedModeSwitchException>()),
          );
        },
      );

      test(
        'should log child mode attempt when unauthorized switch is tried',
        () async {
          // Given
          final childMode = GameMode.child();
          await mockRepository.saveMode(childMode);

          // When
          try {
            await useCase.switchToAdultMode();
          } catch (e) {
            // Expected to throw
          }

          // Then
          expect(mockRepository._childAttempts, hasLength(1));
          final attempt = mockRepository._childAttempts.first;
          expect(attempt.attemptType, equals('unauthorized_mode_switch'));
        },
      );

      test('should use default adult settings if none saved', () async {
        // Given
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        // When
        final adultMode = await useCase.switchToAdultModeWithLongPress();

        // Then
        expect(adultMode.isAdultMode, isTrue);
        expect(adultMode.settings.treasureCount, equals(5)); // Default
        expect(
          adultMode.settings.gameTimeLimit,
          equals(const Duration(minutes: 10)),
        );
      });
    });

    group('updateSettings', () {
      test('should update settings in adult mode', () async {
        // Given
        final adultMode = GameMode.adult();
        await mockRepository.saveMode(adultMode);

        final newSettings = GameSettings(
          treasureCount: 8,
          gameTimeLimit: const Duration(minutes: 15),
          discoveryRange: 1.2,
          showHints: false,
          playSounds: true,
        );

        // When
        final updatedMode = await useCase.updateSettings(newSettings);

        // Then
        expect(updatedMode.isAdultMode, isTrue);
        expect(updatedMode.settings.treasureCount, equals(8));
        expect(
          updatedMode.settings.gameTimeLimit,
          equals(const Duration(minutes: 15)),
        );
      });

      test(
        'should throw exception when trying to update settings in child mode',
        () async {
          // Given
          final childMode = GameMode.child();
          await mockRepository.saveMode(childMode);

          final newSettings = GameSettings(
            treasureCount: 8,
            gameTimeLimit: const Duration(minutes: 15),
            discoveryRange: 1.2,
            showHints: false,
            playSounds: true,
          );

          // When & Then
          expect(
            () => useCase.updateSettings(newSettings),
            throwsA(isA<UnauthorizedSettingsChangeException>()),
          );
        },
      );

      test(
        'should log child mode attempt when unauthorized settings change is tried',
        () async {
          // Given
          final childMode = GameMode.child();
          await mockRepository.saveMode(childMode);

          final newSettings = GameSettings.defaultAdult();

          // When
          try {
            await useCase.updateSettings(newSettings);
          } catch (e) {
            // Expected to throw
          }

          // Then
          expect(mockRepository._childAttempts, hasLength(1));
          expect(
            mockRepository._childAttempts.first.attemptType,
            equals('unauthorized_settings_change'),
          );
        },
      );
    });

    group('getCurrentMode', () {
      test('should return current mode from repository', () async {
        // Given
        final mode = GameMode.child();
        await mockRepository.saveMode(mode);

        // When
        final currentMode = await useCase.getCurrentMode();

        // Then
        expect(currentMode, isNotNull);
        expect(currentMode!.isChildMode, isTrue);
      });

      test('should return null when no current mode saved', () async {
        // Given (no current mode saved - using default state)
        
        // When
        final currentMode = await useCase.getCurrentMode();

        // Then
        expect(currentMode, isNull);
      });
    });

    group('canAccessFeature', () {
      test('should allow access to settings in adult mode', () async {
        // Given
        final adultMode = GameMode.adult();
        await mockRepository.saveMode(adultMode);

        // When
        final canAccess = await useCase.canAccessFeature(GameFeature.settings);

        // Then
        expect(canAccess, isTrue);
      });

      test('should deny access to settings in child mode', () async {
        // Given
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        // When
        final canAccess = await useCase.canAccessFeature(GameFeature.settings);

        // Then
        expect(canAccess, isFalse);
      });

      test('should allow play feature in both modes', () async {
        // Given
        final adultMode = GameMode.adult();
        await mockRepository.saveMode(adultMode);

        // When
        final adultCanPlay = await useCase.canAccessFeature(GameFeature.play);

        // Given child mode
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        // When
        final childCanPlay = await useCase.canAccessFeature(GameFeature.play);

        // Then
        expect(adultCanPlay, isTrue);
        expect(childCanPlay, isTrue);
      });
    });

    group('getChildModeSecurityReport', () {
      test('should return security report with recent attempts', () async {
        // Given
        final now = DateTime.now();
        await mockRepository.logChildModeAttempt(
          attemptType: 'unauthorized_mode_switch',
          timestamp: now.subtract(const Duration(minutes: 5)),
        );
        await mockRepository.logChildModeAttempt(
          attemptType: 'unauthorized_settings_change',
          timestamp: now.subtract(const Duration(minutes: 2)),
        );

        // When
        final report = await useCase.getChildModeSecurityReport(
          period: const Duration(hours: 1),
        );

        // Then
        expect(report.totalAttempts, equals(2));
        expect(report.recentAttempts, hasLength(2));
        expect(report.isSecurityConcern, isFalse); // Below threshold
      });

      test('should identify security concern with many attempts', () async {
        // Given
        final now = DateTime.now();
        for (int i = 0; i < 10; i++) {
          await mockRepository.logChildModeAttempt(
            attemptType: 'unauthorized_mode_switch',
            timestamp: now.subtract(Duration(minutes: i)),
          );
        }

        // When
        final report = await useCase.getChildModeSecurityReport(
          period: const Duration(hours: 1),
        );

        // Then
        expect(report.totalAttempts, equals(10));
        expect(report.isSecurityConcern, isTrue); // Above threshold
      });
    });

    group('resetToDefaults', () {
      test('should reset to default adult mode', () async {
        // Given
        final childMode = GameMode.child();
        await mockRepository.saveMode(childMode);

        // When
        final defaultMode = await useCase.resetToDefaults();

        // Then
        expect(defaultMode.isAdultMode, isTrue);
        expect(defaultMode.settings.treasureCount, equals(5)); // Default
      });

      test('should clear all stored data when resetting', () async {
        // Given
        await mockRepository.saveMode(GameMode.child());
        await mockRepository.saveAdultSettings(GameSettings.defaultAdult());
        await mockRepository.logChildModeAttempt(
          attemptType: 'test',
          timestamp: DateTime.now(),
        );

        // When
        await useCase.resetToDefaults();

        // Then
        final currentMode = await mockRepository.getCurrentMode();
        final adultSettings = await mockRepository.getAdultSettings();
        final attempts = await mockRepository.getChildModeAttempts();

        expect(currentMode, isNull);
        expect(adultSettings, isNull);
        expect(attempts, isEmpty);
      });
    });
  });
}
