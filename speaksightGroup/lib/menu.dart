import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tts_service.dart';
import 'onboarding.dart';

/// MenuPage provides the main navigation hub for the application.
///
/// This is the primary entry point for users, offering:
/// - Accessible buttons for core app features
/// - Voice feedback on button focus and selection
/// - Access to the onboarding tutorial
///
/// The menu is designed to be fully accessible to visually impaired users
/// with large touch targets, clear labels, and audio guidance.
class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

/// State for MenuPage handling UI rendering and user interactions.
///
/// This state manages:
/// - Animations for page transitions and UI elements
/// - Text-to-speech feedback for menu items
/// - Gesture detection for tutorial access
/// - Navigation to other app sections
class _MenuPageState extends State<MenuPage>
  with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TtsService _tts = TtsService();
  double _dragDistance = 0.0;
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    _tts.init();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
  );

  _animationController.forward();
  }

  /// Opens the tutorial/onboarding page.
  /// 
  /// Stops any ongoing speech, transitions to the tutorial page
  /// with a fade animation, and ensures speech is stopped when
  /// returning from the tutorial.
  void _openTutorial() {
    _tts.forceStop();

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OnboardingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _tts.forceStop();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Builds the main UI for the menu page.
  /// 
  /// Creates a page with:
  /// 1. App title and logo
  /// 2. Welcome message
  /// 3. Menu buttons for main features (camera, settings)
  /// 4. Gesture detector for swipe-to-tutorial
  /// 
  /// The UI includes animations for page transitions and visual feedback
  /// for gestures to improve accessibility.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Speak Sight',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 40),
                      // App logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.remove_red_eye_outlined,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Text(
                        'Welcome to Speak Sight',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'An assistant to help you understand your surroundings through audio feedback',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                      _buildMenuButton(
                        context,
                        'Activate Camera',
                        'Start object detection and text recognition',
                        Icons.camera_alt_rounded,
                        '/home',
                        Theme.of(context).primaryColor,
                        0,
                      ),
                      _buildMenuButton(
                        context,
                        'Settings',
                        'Customize your experience',
                        Icons.settings,
                        '/settings',
                        Color(0xFFFF8000),
                        1,
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          'Swipe up for tutorial',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragStart: (details) {
                setState(() {
                  _isDragging = true;
                  _dragDistance = 0.0;
                });
              },
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < 0) {
                  setState(() {
                    _dragDistance -= details.delta.dy;
                  });
                  
                  if (_dragDistance > 10) {
                    HapticFeedback.lightImpact();
                  }
                }
              },
              onVerticalDragEnd: (details) {
                print("Drag distance: $_dragDistance, velocity: ${details.primaryVelocity}");
                if (_dragDistance > 50 || (details.primaryVelocity != null && details.primaryVelocity! < -300)) {
                  HapticFeedback.mediumImpact();
                  _openTutorial();
                }
                setState(() {
                  _isDragging = false;
                  _dragDistance = 0.0;
                });
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a styled menu button with icon, title, and subtitle.
  /// 
  /// Each button provides:
  /// - Visual feedback with color and icon
  /// - Audio feedback on single tap (reads button purpose)
  /// - Navigation on double tap (activates the feature)
  /// - Haptic feedback for both interactions
  /// 
  /// The buttons use staggered animations when the page loads, with
  /// buttons appearing in sequence for a polished experience.
  Widget _buildMenuButton(BuildContext context, String title, String subtitle,
      IconData icon, String route, Color color, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (title == 'Activate Camera') {
              _tts.stop();
              _tts.speakText("Activate camera. Double tap to start object detection.");
              // _tts.stop();
            } else if (title == 'Settings') {
              _tts.stop();
              _tts.speakText("Settings menu. Double tap to customize application preferences.");
              
            } else {
              _tts.speakText(title);
            }
          },
          onDoubleTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, route);
          },

          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 80), // Reduce height to prevent overflow
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Prevent overflow by allowing flexible size
                children: [
                  // Left Icon Container
                  Container(
                    width: 80, // Reduced width to allow more space for content
                    height: 80, // Match container height to avoid overflow
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Title and Subtitle
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // Reduced padding to prevent overflow
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18, // Slightly smaller to avoid overflow
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            overflow: TextOverflow.ellipsis, // Prevent wrapping
                          ),
                          if (subtitle.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow
                              maxLines: 1,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  // Right Arrow Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}