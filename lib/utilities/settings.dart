import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One user-adjustable value, saved under [key]. It's a [ValueNotifier], so
/// code that depends on it can read `.value` or listen for changes.
///
/// To add a setting: create it in [Settings] and put it in a section of
/// [Settings.sections]; the settings page lists it automatically.
abstract class Setting<T> extends ValueNotifier<T> {
  Setting({
    required this.key,
    required this.label,
    required this.defaultValue,
    this.description = "",
  }) : super(defaultValue);

  final String key;
  final String label;
  final String description;
  final T defaultValue;

  /// The value as shown on the settings page.
  String get display;

  /// Step the value up (+) or down (-), as H/L do on the settings page.
  void nudge(int steps);

  void reset() => value = defaultValue;

  bool get isDefault => value == defaultValue;

  @override
  set value(T newValue) {
    if (newValue == super.value) return;
    super.value = newValue;
    final prefs = Settings._prefs;
    if (prefs != null) _write(prefs);
  }

  T? _read(SharedPreferences prefs);
  Future<void> _write(SharedPreferences prefs);

  void _load(SharedPreferences prefs) {
    // assign through super so loading doesn't write the value back
    super.value = _read(prefs) ?? defaultValue;
  }
}

/// A whole number between [min] and [max], adjusted in [step]s.
class NumberSetting extends Setting<int> {
  NumberSetting({
    required super.key,
    required super.label,
    required super.defaultValue,
    super.description,
    required this.min,
    required this.max,
    this.step = 1,
    this.unit = "",
    this.format,
  });

  final int min;
  final int max;
  final int step;
  final String unit;
  final String Function(int value)? format;

  @override
  set value(int newValue) => super.value = newValue.clamp(min, max);

  @override
  String get display => format?.call(value) ?? "$value$unit";

  @override
  void nudge(int steps) => value += steps * step;

  @override
  int? _read(SharedPreferences prefs) => prefs.getInt(key)?.clamp(min, max);

  @override
  Future<void> _write(SharedPreferences prefs) => prefs.setInt(key, value);
}

class SettingsSection {
  const SettingsSection({required this.title, required this.settings});

  final String title;
  final List<Setting> settings;
}

/// Every setting in the app, saved with shared_preferences.
abstract final class Settings {
  static final holdScrollDelay = NumberSetting(
    key: "hold_scroll_delay_ms",
    label: "Hold delay",
    description: "How long J/K, ↑/↓ or Shift+H/L must be held to repeat",
    defaultValue: 300,
    min: 100,
    max: 1000,
    step: 50,
    unit: " ms",
  );

  static final holdScrollInterval = NumberSetting(
    key: "hold_scroll_interval_ms",
    label: "Scroll speed",
    description: "Time between items while a key is held; lower is faster",
    defaultValue: 150,
    min: 30,
    max: 500,
    step: 10,
    format: (ms) => "$ms ms · ${(1000 / ms).toStringAsFixed(1)} items/s",
  );

  static final seekStep = NumberSetting(
    key: "seek_step_s",
    label: "Seek step",
    description: "How far Shift+H / Shift+L jump in the song",
    defaultValue: 5,
    min: 1,
    max: 60,
    unit: " s",
  );

  static final holdSeekInterval = NumberSetting(
    key: "hold_seek_interval_ms",
    label: "Seek speed",
    description: "Time between jumps while Shift+H/L is held; lower is faster",
    defaultValue: 250,
    min: 50,
    max: 1000,
    step: 50,
    unit: " ms",
  );

  static final sections = [
    SettingsSection(
      title: "Scrolling",
      settings: [holdScrollDelay, holdScrollInterval],
    ),
    SettingsSection(title: "Seeking", settings: [seekStep, holdSeekInterval]),
  ];

  static SharedPreferences? _prefs;

  /// Loads saved values; call once before the UI starts.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final section in sections) {
      for (final setting in section.settings) {
        setting._load(prefs);
      }
    }
    _prefs = prefs;
  }
}
