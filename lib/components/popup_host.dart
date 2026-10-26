import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Hosts a single popup page that slides up over [child] (the base page).
///
/// Showing a popup while one is open slides the new one in over it and then
/// drops the old one, so closing always returns to the base page. When the
/// window loses focus (clicked away, Esc) the popup is dropped immediately,
/// so the window always reopens on the base page.
class PopupHost extends StatefulWidget {
  const PopupHost({super.key, required this.child});

  final Widget child;

  static PopupHostState of(BuildContext context) =>
      context.findAncestorStateOfType<PopupHostState>()!;

  @override
  State<PopupHost> createState() => PopupHostState();
}

class _PopupEntry {
  _PopupEntry(this.page, this.controller)
    : animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

  final Widget page;
  final AnimationController controller;
  final CurvedAnimation animation;
  final Key key = UniqueKey();

  void dispose() {
    animation.dispose();
    controller.dispose();
  }
}

class PopupHostState extends State<PopupHost>
    with TickerProviderStateMixin, WindowListener {
  static const _duration = Duration(milliseconds: 280);

  // The last entry is the visible popup; any before it are being covered by
  // a replacement and get dropped once it has finished sliding in.
  final List<_PopupEntry> _entries = [];
  FocusNode? _baseFocus;

  bool get isOpen => _entries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void onWindowBlur() => dismiss();

  /// Removes any popup without animating, e.g. when the window is hidden.
  void dismiss() {
    if (_entries.isEmpty) return;
    final removed = List.of(_entries);
    setState(_entries.clear);
    for (final e in removed) {
      e.dispose();
    }
    _restoreBaseFocus();
  }

  void show(Widget page) {
    if (_entries.isEmpty) _baseFocus = FocusManager.instance.primaryFocus;

    final entry = _PopupEntry(
      page,
      AnimationController(vsync: this, duration: _duration),
    );
    setState(() => _entries.add(entry));

    entry.controller.forward().whenCompleteOrCancel(() {
      if (!mounted || !_entries.contains(entry)) return;
      final covered = _entries.sublist(0, _entries.indexOf(entry));
      if (covered.isEmpty) return;
      setState(() => _entries.removeRange(0, covered.length));
      for (final e in covered) {
        e.dispose();
      }
    });
  }

  void close() {
    if (_entries.isEmpty) return;
    final top = _entries.last;
    final covered = _entries.sublist(0, _entries.length - 1);
    setState(() => _entries.removeRange(0, covered.length));
    for (final e in covered) {
      e.dispose();
    }

    top.controller.reverse().whenCompleteOrCancel(() {
      if (!mounted || !_entries.contains(top)) return;
      setState(() => _entries.remove(top));
      top.dispose();
      _restoreBaseFocus();
    });
  }

  void _restoreBaseFocus() {
    final node = _baseFocus;
    _baseFocus = null;
    // wait a frame so the base page is no longer excluded from focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node != null && node.context != null) node.requestFocus();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(excluding: _entries.isNotEmpty, child: widget.child),
        for (int i = 0; i < _entries.length; i++)
          _buildPopup(_entries[i], withScrim: i == 0),
      ],
    );
  }

  Widget _buildPopup(_PopupEntry entry, {required bool withScrim}) {
    return Stack(
      key: entry.key,
      fit: StackFit.expand,
      children: [
        // only the bottom-most popup dims the base page, so replacing a
        // popup doesn't stack two scrims
        if (withScrim)
          FadeTransition(
            opacity: entry.animation,
            child: const AbsorbPointer(
              child: ColoredBox(color: Color(0x59000000)),
            ),
          ),
        SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(entry.animation),
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xEB111215),
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: entry.page,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Layout shared by every popup: a back button (bound to B) and a title,
/// above the page's content. Unhandled keys are passed to [onKey].
class PopupPage extends StatefulWidget {
  const PopupPage({
    super.key,
    required this.title,
    required this.child,
    this.onKey,
  });

  final String title;
  final Widget child;
  final KeyEventResult Function(KeyEvent event)? onKey;

  @override
  State<PopupPage> createState() => _PopupPageState();
}

class _PopupPageState extends State<PopupPage> {
  final FocusNode _focus = FocusNode(debugLabel: "PopupPage");

  @override
  void initState() {
    super.initState();
    // take focus explicitly: autofocus is ignored when a popup replaces one
    // that still holds focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyB) {
          PopupHost.of(context).close();
          return KeyEventResult.handled;
        }
        return widget.onKey?.call(event) ?? KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  tooltip: "Back (B)",
                  onPressed: () => PopupHost.of(context).close(),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
