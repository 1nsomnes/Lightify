import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/utilities/hold_to_scroll.dart';
import 'package:lightify/utilities/settings.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const _green = Color(0xFF1DB954);

/// Popup listing every [Settings] section. J/K select, H/L (or ←/→) adjust,
/// R resets the selected setting to its default.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ItemScrollController _scroll = ItemScrollController();
  late final _hold = HoldToScroll(_moveSelection);

  // section titles and settings, in display order
  final List<Object> _rows = [];
  // row index of each setting, in order
  final List<int> _settingRows = [];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    for (final section in Settings.sections) {
      _rows.add(section.title);
      for (final setting in section.settings) {
        _settingRows.add(_rows.length);
        _rows.add(setting);
      }
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Setting? get _selectedSetting =>
      _settingRows.isEmpty ? null : _rows[_settingRows[_selected]] as Setting;

  void _moveSelection(int delta, Duration scrollDuration) {
    if (_settingRows.isEmpty) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, _settingRows.length - 1);
    });
    _scroll.scrollTo(
      index: _settingRows[_selected],
      duration: scrollDuration,
      alignment: 0.38,
    );
  }

  KeyEventResult _onKey(KeyEvent e) {
    if (_hold.handle(e)) return KeyEventResult.handled;
    // let H/L repeat so values can be swept by holding them
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final setting = _selectedSetting;
    if (setting == null) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyH:
        setting.nudge(-1);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyL:
        setting.nudge(1);
      case LogicalKeyboardKey.keyR when e is KeyDownEvent:
        setting.reset();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRow = _settingRows.isEmpty ? -1 : _settingRows[_selected];
    return PopupPage(
      title: "Settings",
      onKey: _onKey,
      child: Column(
        children: [
          Expanded(
            child: ScrollablePositionedList.builder(
              physics: const ClampingScrollPhysics(),
              itemScrollController: _scroll,
              itemCount: _rows.length,
              itemBuilder: (context, i) => switch (_rows[i]) {
                Setting setting => _SettingTile(
                  setting: setting,
                  selected: i == selectedRow,
                  onTap: () => setState(() {
                    _selected = _settingRows.indexOf(i);
                  }),
                ),
                final title => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
                  child: Text(
                    "$title".toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              "J/K select  ·  H/L adjust  ·  R reset  ·  Esc back",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.setting,
    required this.selected,
    required this.onTap,
  });

  final Setting setting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: setting,
      builder: (context, _) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0x141DB954) : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0x801DB954) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      setting.label,
                      style: TextStyle(
                        color: selected ? _green : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!setting.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        "edited",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  Text(
                    setting.display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (setting.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    setting.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              _control(setting),
            ],
          ),
        ),
      ),
    );
  }

  // the mouse control for each kind of setting
  Widget _control(Setting setting) => switch (setting) {
    NumberSetting s => SliderTheme(
      data: const SliderThemeData(
        activeTrackColor: _green,
        thumbColor: _green,
        inactiveTrackColor: Color(0x33FFFFFF),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        value: s.value.toDouble(),
        min: s.min.toDouble(),
        max: s.max.toDouble(),
        divisions: (s.max - s.min) ~/ s.step,
        onChanged: (v) => s.value = v.round(),
      ),
    ),
    _ => const SizedBox(height: 12),
  };
}
