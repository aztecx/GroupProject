import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;

  final List<Map<String, dynamic>> modes = [
    {
      'name': 'Object Detection',
      'icon': Icons.remove_red_eye_outlined,
      'color': Color(0xFF0080FF),
      'route': '/home'
    },
    {
      'name': 'Object Search',
      'icon': Icons.search,
      'color': Color(0xFF00C853),
      'route': '/home'
    },
    {
      'name': 'Text Recognition',
      'icon': Icons.description_outlined,
      'color': Color(0xFFFF8000),
      'route': '/textModel'
    }
  ];

  int currentModeIndex = 0;
  bool showHelp = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _switchMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      currentModeIndex = (currentModeIndex + 1) % modes.length;
    });
    if (modes[currentModeIndex]['route'] != '/home' &&
        modes[currentModeIndex]['route'] != null) {
      Navigator.pushNamed(context, modes[currentModeIndex]['route']);
    }
  }

  void _toggleHelp() {
    setState(() {
      showHelp = !showHelp;
    });
    if (showHelp) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Speak Sight',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _toggleHelp,
          ),
        ],
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? _buildLoadingScreen()
          : _buildCameraView(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Starting camera...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return GestureDetector(
      onDoubleTap: _switchMode,
      onTap: () => HapticFeedback.selectionClick(),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            // Swipe left
            if (!showHelp) _toggleHelp();
          } else if (details.primaryVelocity! > 0) {
            // Swipe right
            if (showHelp) _toggleHelp();
          }
        }
      },
      child: Stack(
        children: [
          // Camera preview
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: CameraPreview(_cameraController!),
          ),
          // Mode indicator
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(
                  modes.length,
                      (index) => _buildModeIndicator(index),
                ),
              ),
            ),
          ),
          // Right control panel (instead of bottom in portrait)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: 120,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeButton(0),
                  SizedBox(height: 16),
                  _buildModeButton(1),
                  SizedBox(height: 16),
                  _buildModeButton(2),
                  SizedBox(height: 24),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Current Mode: ${modes[currentModeIndex]['name']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modes[currentModeIndex]['color'],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Double-tap\nto switch',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Help overlay
          if (showHelp)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                      MediaQuery.of(context).size.width * _slideAnimation.value,
                      0),
                  child: child,
                );
              },
              child: Container(
                color: Colors.black.withOpacity(0.9),
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.all(24),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'How to use Speak Sight',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildInstructionItem(
                              context,
                              Icons.touch_app,
                              'Double-tap anywhere on the screen to switch between modes',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildInstructionItem(
                              context,
                              Icons.swipe,
                              'Swipe left to show this help screen, swipe right to close it',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildInstructionItem(
                              context,
                              Icons.mic,
                              'The app will speak out loud what it detects through your camera',
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: _toggleHelp,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 40),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Got It',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeIndicator(int index) {
    bool isActive = index == currentModeIndex;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? modes[index]['color'] : Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Icon(
        modes[index]['icon'],
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildModeButton(int index) {
    bool isActive = index == currentModeIndex;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          currentModeIndex = index;
        });
        if (modes[index]['route'] != '/home') {
          Navigator.pushNamed(context, modes[index]['route']);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? modes[index]['color'] : Colors.black38,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: modes[index]['color'].withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              modes[index]['icon'],
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              index == 0
                  ? 'Object'
                  : index == 1
                  ? 'Search'
                  : 'Text',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
      BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
