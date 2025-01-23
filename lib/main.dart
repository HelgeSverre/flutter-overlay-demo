/// This is a demo application that showcases how to create a positioned overlay with a
/// backdrop cutout in Flutter. The demo uses a calendar interface where clicking a day
/// shows an overlay with additional information.
///
/// Key components:
/// - CalendarOverlayService: Singleton service managing overlay state and visibility
/// - CalendarCellOverlay: Main overlay widget handling positioning and animations
/// - HoleBackgroundPainter: Custom painter for creating the backdrop with cutout
/// - DemoOverlayContent: Example overlay content
///
/// The implementation can be used for:
/// - Tooltips
/// - Contextual menus
/// - Feature tours
/// - Educational overlays
/// - Detail previews

import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overlay Demo',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFDE146),
        title: const Text(
          'How to: Overlay!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PreferredSize(
            preferredSize: const Size.square(100),
            child: Image.asset("assets/face.png"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ].map((dayName) {
                        return Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        return CalendarCell(day: index + 1);
                      },
                      itemCount: 31,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Long press any cell to show overlay',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarCell extends StatelessWidget {
  final int day;

  const CalendarCell({required this.day, super.key});

  void onCellHighlighted(BuildContext context) {
    final position =
        (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
    final cellRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      context.size!.width,
      context.size!.height,
    );

    CalendarOverlayService().showOverlay(
      context,
      DemoOverlayContent(day: day),
      cellRect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onCellHighlighted(context),
      onTap: () => onCellHighlighted(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$day',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class DemoOverlayContent extends StatelessWidget {
  final int day;

  const DemoOverlayContent({required this.day, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade400,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'January $day',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '2 events scheduled',
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Team Meeting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarOverlayService {
  static final CalendarOverlayService _instance = CalendarOverlayService._();

  factory CalendarOverlayService() => _instance;

  CalendarOverlayService._();

  /// Currently active overlay entry
  OverlayEntry? _currentOverlay;

  /// Controls the visibility state for fade animations
  final _visibilityNotifier = ValueNotifier<bool>(false);

  /// Shows an overlay with the provided child widget anchored to the specified position
  /// [context] - BuildContext for accessing the overlay
  /// [child] - Widget to show in the overlay
  /// [position] - Rectangle defining the anchor position
  void showOverlay(
    BuildContext context,
    Widget child,
    Rect position,
  ) {
    _currentOverlay?.remove();
    _visibilityNotifier.value = false;

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => CalendarCellOverlay(
        position: position,
        onDismiss: hideOverlay,
        visibilityNotifier: _visibilityNotifier,
        child: child,
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  Future<void> hideOverlay() async {
    _visibilityNotifier.value = false;
    // NOTE: Allow time for the "close" animation to finish, there is likely a better way to do this, but basically, keep this the same or slightly longer than the animation duration of the "AnimatedOpacity" further below in the code.
    await Future.delayed(const Duration(milliseconds: 200));
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  void dispose() {
    _visibilityNotifier.dispose();
  }
}

// Calendar Cell Overlay (same as in the real implementation)
class CalendarCellOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;
  final Rect position;
  final ValueNotifier<bool> visibilityNotifier;

  const CalendarCellOverlay({
    required this.child,
    required this.onDismiss,
    required this.position,
    required this.visibilityNotifier,
    super.key,
  });

  @override
  State<CalendarCellOverlay> createState() => _CalendarCellOverlayState();
}

class _CalendarCellOverlayState extends State<CalendarCellOverlay> {
  static const double overlayWidth = 200.0;
  static const double horizontalPadding = 12.0;
  static const double verticalPadding = 12.0;
  static const double centerZonePercentage = 0.30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.visibilityNotifier.value = true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.visibilityNotifier,
      builder: (context, isVisible, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final size = MediaQuery.of(context).size;
          final viewportCenterX = size.width / 2;

          var position = widget.position;

          // Calculate center zone bounds
          final centerZoneWidth = size.width * centerZonePercentage;
          final centerZoneStart = viewportCenterX - (centerZoneWidth / 2);
          final centerZoneEnd = viewportCenterX + (centerZoneWidth / 2);

          // Check if cell is in center zone
          final isCellInCenterZone = position.center.dx >= centerZoneStart &&
              position.center.dx <= centerZoneEnd;

          // Available space calculation
          final availableSpaceLeft = position.left;
          final availableSpaceRight = size.width - position.right;

          double leftPosition;

          /// Three positioning scenarios:
          /// 1. Center zone: Overlay is centered on the anchor
          /// 2. Right side: Overlay aligns its right edge with anchor
          /// 3. Left side: Overlay aligns its left edge with anchor
          ///
          /// Each scenario also considers available space to prevent
          /// overflow and ensures the overlay stays within screen bounds.
          if (isCellInCenterZone) {
            // Center align
            leftPosition = position.center.dx - (overlayWidth / 2);
            leftPosition = leftPosition.clamp(
              horizontalPadding,
              size.width - overlayWidth - horizontalPadding,
            );
          } else if (position.center.dx > viewportCenterX) {
            // Right side positioning
            if (overlayWidth <= position.width + availableSpaceLeft) {
              leftPosition = position.right - overlayWidth;
            } else {
              leftPosition = position.left;
            }
          } else {
            // Left side positioning
            if (overlayWidth <= position.width + availableSpaceRight) {
              leftPosition = position.left;
            } else {
              leftPosition = position.right - overlayWidth;
            }
          }

          // Final bounds check
          leftPosition = leftPosition.clamp(
            horizontalPadding,
            size.width - overlayWidth - horizontalPadding,
          );

          return AnimatedOpacity(
            // Note: Change this duration to control how fast the overlay fades in.
            duration: const Duration(milliseconds: 200),
            // Note: You can also change the Animation curve
            curve: Curves.easeInOutQuad,
            opacity: isVisible ? 1.0 : 0.0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onDismiss,
              child: Stack(
                children: [
                  // Backdrop fills the entire screen, and uses a custom painter class to "cut out a hole" where the "focused widget" is visible through
                  Positioned.fill(
                    child: CustomPaint(
                      painter: HoleBackgroundPainter(
                        holeRect: widget.position,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),

                  // Overlay content (The thing that says "January xx, 2 events scheduled, team meeting - close"
                  Positioned(
                    left: leftPosition,
                    top: widget.position.bottom + verticalPadding,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 4,
                      child: SizedBox(
                        width: overlayWidth,
                        child: widget.child,
                      ),
                    ),
                  ),

                  // Add a border around the "hole" in the backdrop
                  Positioned.fromRect(
                    rect: widget.position,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.cyan,
                          width: 4,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

/// Custom painter that creates a semi-transparent backdrop with a "hole"
/// where the anchor widget should be visible.
///
/// Uses Path.combine with PathOperation.difference to cut out the hole
/// from the backdrop rectangle.
class HoleBackgroundPainter extends CustomPainter {
  final Rect holeRect;
  final Color backgroundColor;

  HoleBackgroundPainter({
    required this.holeRect,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Create path for entire screen
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create path for hole
    final holePath = Path()..addRect(holeRect);

    // Cut hole from background
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(HoleBackgroundPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
