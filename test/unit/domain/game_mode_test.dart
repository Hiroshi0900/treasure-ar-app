import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/entities/game_mode_state.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

void main() {
  group('GameMode', () {
    group('AdultMode', () {
      test('should create adult mode with default settings', () {
        // Given (no specific setup needed - testing default creation)
        
        // When
        final gameMode = GameMode.adult();

        // Then
        expect(gameMode.isAdultMode, isTrue);
        expect(gameMode.isChildMode, isFalse);
        expect(gameMode.state, isA<AdultModeState>());
        expect(gameMode.settings.treasureCount, equals(5));
        expect(gameMode.settings.gameTimeLimit, equals(Duration(minutes: 10)));
        expect(gameMode.settings.discoveryRange, equals(1.0));
        expect(gameMode.settings.showHints, isTrue);
        expect(gameMode.settings.playSounds, isTrue);
      });

      test('should allow custom settings for adult mode', () {
        // Given
        final customSettings = GameSettings(
          treasureCount: 8,
          gameTimeLimit: Duration(minutes: 15),
          discoveryRange: 1.5,
          showHints: false,
          playSounds: false,
        );

        // When
        final gameMode = GameMode.adult(settings: customSettings);

        // Then
        expect(gameMode.isAdultMode, isTrue);
        expect(gameMode.settings.treasureCount, equals(8));
        expect(gameMode.settings.gameTimeLimit, equals(Duration(minutes: 15)));
        expect(gameMode.settings.discoveryRange, equals(1.5));
        expect(gameMode.settings.showHints, isFalse);
        expect(gameMode.settings.playSounds, isFalse);
      });

      test('should enable advanced features in adult mode', () {
        // Given (no specific setup needed - testing default features)
        
        // When
        final gameMode = GameMode.adult();

        // Then
        expect(gameMode.canAccessSettings, isTrue);
        expect(gameMode.canResetGame, isTrue);
        expect(gameMode.canChangeMode, isTrue);
        expect(gameMode.hasAdvancedUI, isTrue);
      });
    });

    group('ChildMode', () {
      test('should create child mode with child-friendly settings', () {
        // Given (no specific setup needed - testing default child mode)
        
        // When
        final gameMode = GameMode.child();

        // Then
        expect(gameMode.isChildMode, isTrue);
        expect(gameMode.isAdultMode, isFalse);
        expect(gameMode.state, isA<ChildModeState>());
        expect(gameMode.settings.treasureCount, equals(3)); // Fewer treasures
        expect(
          gameMode.settings.gameTimeLimit,
          equals(Duration(minutes: 5)),
        ); // Shorter time
        expect(gameMode.settings.discoveryRange, equals(2.0)); // Wider range
        expect(gameMode.settings.showHints, isTrue); // More guidance
        expect(gameMode.settings.playSounds, isTrue); // Audio feedback
      });

      test('should restrict advanced features in child mode', () {
        // Given (no specific setup needed - testing restrictions)
        
        // When
        final gameMode = GameMode.child();

        // Then
        expect(gameMode.canAccessSettings, isFalse);
        expect(gameMode.canResetGame, isFalse);
        expect(gameMode.canChangeMode, isFalse);
        expect(gameMode.hasAdvancedUI, isFalse);
      });

      test('should have child-specific behavior settings', () {
        // Given (no specific setup needed - testing child-specific behaviors)
        
        // When
        final gameMode = GameMode.child();
        final childState = gameMode.state as ChildModeState;

        // Then
        expect(childState.requiresLongPressToExit, isTrue);
        expect(childState.hasSimplifiedUI, isTrue);
        expect(childState.autoShowHints, isTrue);
        expect(childState.preventAccidentalActions, isTrue);
      });
    });

    group('Mode Switching', () {
      test('should switch from adult to child mode', () {
        // Given
        final adultMode = GameMode.adult();

        // When
        final childMode = adultMode.switchToChild();

        // Then
        expect(childMode.isChildMode, isTrue);
        expect(childMode.isAdultMode, isFalse);
        expect(childMode.state, isA<ChildModeState>());
      });

      test(
        'should switch from child to adult mode with long press confirmation',
        () {
          // Given
          final childMode = GameMode.child();

          // When
          final adultMode = childMode.switchToAdultWithLongPress();

          // Then
          expect(adultMode.isAdultMode, isTrue);
          expect(adultMode.isChildMode, isFalse);
          expect(adultMode.state, isA<AdultModeState>());
        },
      );

      test(
        'should throw exception when trying to switch from child mode without long press',
        () {
          // Given
          final childMode = GameMode.child();

          // When & Then
          expect(
            () => childMode.switchToAdult(),
            throwsA(isA<UnauthorizedModeSwitchException>()),
          );
        },
      );

      test('should preserve custom settings when switching modes', () {
        // Given
        final customSettings = GameSettings(
          treasureCount: 7,
          gameTimeLimit: Duration(minutes: 12),
          discoveryRange: 1.2,
          showHints: false,
          playSounds: true,
        );
        final adultMode = GameMode.adult(settings: customSettings);

        // When
        final childMode = adultMode.switchToChild();
        final backToAdult = childMode.switchToAdultWithLongPress();

        // Then - Child mode should have child-appropriate settings
        expect(childMode.settings.treasureCount, equals(3));
        expect(childMode.settings.discoveryRange, equals(2.0));

        // But when switching back to adult, custom settings should be restored
        expect(backToAdult.settings.treasureCount, equals(7));
        expect(
          backToAdult.settings.gameTimeLimit,
          equals(Duration(minutes: 12)),
        );
        expect(backToAdult.settings.discoveryRange, equals(1.2));
      });
    });

    group('Game Settings Validation', () {
      test('should validate treasure count is within valid range', () {
        // Given (no specific setup needed - testing validation boundaries)
        
        // When & Then
        expect(
          () => GameSettings(
            treasureCount: 0, // Invalid: too few
            gameTimeLimit: Duration(minutes: 5),
            discoveryRange: 1.0,
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );

        expect(
          () => GameSettings(
            treasureCount: 21, // Invalid: too many
            gameTimeLimit: Duration(minutes: 5),
            discoveryRange: 1.0,
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );
      });

      test('should validate game time limit is within valid range', () {
        // Given (no specific setup needed - testing validation boundaries)
        
        // When & Then
        expect(
          () => GameSettings(
            treasureCount: 5,
            gameTimeLimit: Duration(seconds: 30), // Invalid: too short
            discoveryRange: 1.0,
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );

        expect(
          () => GameSettings(
            treasureCount: 5,
            gameTimeLimit: Duration(hours: 2), // Invalid: too long
            discoveryRange: 1.0,
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );
      });

      test('should validate discovery range is within valid range', () {
        // Given (no specific setup needed - testing validation boundaries)
        
        // When & Then
        expect(
          () => GameSettings(
            treasureCount: 5,
            gameTimeLimit: Duration(minutes: 5),
            discoveryRange: 0.1, // Invalid: too small
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );

        expect(
          () => GameSettings(
            treasureCount: 5,
            gameTimeLimit: Duration(minutes: 5),
            discoveryRange: 11.0, // Invalid: too large
            showHints: true,
            playSounds: true,
          ),
          throwsA(isA<InvalidGameSettingsException>()),
        );
      });
    });

    group('Age-Appropriate Settings', () {
      test('should enforce minimum discovery range for child mode', () {
        // Given (no specific setup needed - testing child mode constraints)
        
        // When
        final childMode = GameMode.child();

        // Then - Child mode should have wider discovery range for easier gameplay
        expect(childMode.settings.discoveryRange, greaterThanOrEqualTo(1.5));
      });

      test('should limit maximum treasure count for child mode', () {
        // Given (no specific setup needed - testing child mode constraints)
        
        // When
        final childMode = GameMode.child();

        // Then - Child mode should have fewer treasures to avoid overwhelm
        expect(childMode.settings.treasureCount, lessThanOrEqualTo(5));
      });

      test('should enforce shorter game time for child mode', () {
        // Given (no specific setup needed - testing child mode constraints)
        
        // When
        final childMode = GameMode.child();

        // Then - Child mode should have shorter sessions for attention span
        expect(
          childMode.settings.gameTimeLimit,
          lessThanOrEqualTo(Duration(minutes: 8)),
        );
      });

      test('should always enable hints and sounds for child mode', () {
        // Given (no specific setup needed - testing child mode requirements)
        
        // When
        final childMode = GameMode.child();

        // Then - Child mode should always provide guidance
        expect(childMode.settings.showHints, isTrue);
        expect(childMode.settings.playSounds, isTrue);
      });
    });

    group('Safety Features', () {
      test('should prevent accidental mode switches in child mode', () {
        // Given
        final childMode = GameMode.child();
        final childState = childMode.state as ChildModeState;

        // When & Then
        expect(childState.requiresLongPressToExit, isTrue);
        expect(childState.preventAccidentalActions, isTrue);
      });

      test(
        'should require confirmation for sensitive actions in child mode',
        () {
          // Given
          final childMode = GameMode.child();

          // When & Then
          expect(childMode.canResetGame, isFalse);
          expect(childMode.canAccessSettings, isFalse);
          expect(childMode.canChangeMode, isFalse);
        },
      );
    });

    group('Equality and Hash', () {
      test('should be equal when same mode and settings', () {
        // Given
        final settings1 = GameSettings(
          treasureCount: 5,
          gameTimeLimit: Duration(minutes: 10),
          discoveryRange: 1.0,
          showHints: true,
          playSounds: true,
        );
        final settings2 = GameSettings(
          treasureCount: 5,
          gameTimeLimit: Duration(minutes: 10),
          discoveryRange: 1.0,
          showHints: true,
          playSounds: true,
        );

        // When
        final mode1 = GameMode.adult(settings: settings1);
        final mode2 = GameMode.adult(settings: settings2);

        // Then
        expect(mode1, equals(mode2));
        expect(mode1.hashCode, equals(mode2.hashCode));
      });

      test('should not be equal when different modes', () {
        // Given
        final adultMode = GameMode.adult();
        final childMode = GameMode.child();

        // When & Then
        expect(adultMode, isNot(equals(childMode)));
        expect(adultMode.hashCode, isNot(equals(childMode.hashCode)));
      });
    });
  });
}
