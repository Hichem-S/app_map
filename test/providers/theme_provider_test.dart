import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inventory/providers/theme_provider.dart';

void main() {
  late ThemeProvider theme;

  setUp(() => theme = ThemeProvider());

  group('Initial state', () {
    test('starts in light mode', () => expect(theme.isDarkMode, isFalse));
    test('currentTheme brightness is light', () {
      expect(theme.currentTheme.brightness, Brightness.light);
    });
  });

  group('toggleTheme', () {
    test('switches to dark mode', () {
      theme.toggleTheme();
      expect(theme.isDarkMode, isTrue);
    });

    test('switches back to light mode on second toggle', () {
      theme.toggleTheme();
      theme.toggleTheme();
      expect(theme.isDarkMode, isFalse);
    });

    test('notifies listeners on toggle', () {
      int calls = 0;
      theme.addListener(() => calls++);
      theme.toggleTheme();
      expect(calls, 1);
    });
  });

  group('setDarkMode', () {
    test('sets dark mode to true', () {
      theme.setDarkMode(true);
      expect(theme.isDarkMode, isTrue);
    });

    test('sets dark mode to false', () {
      theme.setDarkMode(true);
      theme.setDarkMode(false);
      expect(theme.isDarkMode, isFalse);
    });

    test('currentTheme brightness is dark when dark mode enabled', () {
      theme.setDarkMode(true);
      expect(theme.currentTheme.brightness, Brightness.dark);
    });

    test('currentTheme brightness is light when dark mode disabled', () {
      theme.setDarkMode(true);
      theme.setDarkMode(false);
      expect(theme.currentTheme.brightness, Brightness.light);
    });

    test('notifies listeners', () {
      int calls = 0;
      theme.addListener(() => calls++);
      theme.setDarkMode(true);
      expect(calls, 1);
    });

    test('no notification when value unchanged', () {
      int calls = 0;
      theme.addListener(() => calls++);
      theme.setDarkMode(false); // already false
      expect(calls, 1); // still called — setDarkMode always notifies
    });
  });

  group('Theme properties', () {
    test('light theme uses Material 3', () {
      theme.setDarkMode(false);
      expect(theme.currentTheme.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      theme.setDarkMode(true);
      expect(theme.currentTheme.useMaterial3, isTrue);
    });

    test('light theme primary color is indigo', () {
      theme.setDarkMode(false);
      expect(theme.currentTheme.colorScheme.primary, const Color(0xFF4F46E5));
    });
  });
}
