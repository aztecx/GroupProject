import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'tts_service.dart';
import 'package:audioplayers/audioplayers.dart';


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  bool showTutorial = true;
  bool _isDataLoaded = false;
  double _dragDistance = 0.0;
  bool _isDragging = false;
  int _duration = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TtsService _tts = TtsService();
  Map<String, dynamic> _tutorialText= {}; 
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _loadTexts();
    _tts.init();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  Future<void> _loadTexts() async {
    final String response = await rootBundle.loadString('assets/onboarding/tutorial.json');
    setState(() {
      _tutorialText = json.decode(response);
      _isDataLoaded = true;
    });

    if(_isDataLoaded){
      _readTutorial();
    }
  }

  void _readTutorial() {
    _audioPlayer = AudioPlayer();
    
    try {
      _audioPlayer!.play(AssetSource('onboarding/tutorial.mp3'));
      
      _audioPlayer!.onPlayerComplete.listen((event) {
        _audioPlayer!.dispose();
        _audioPlayer = null;
      });
      
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          _audioPlayer!.dispose();
          _audioPlayer = null;
        } else if (state == PlayerState.stopped) {
          print('Stopped state in tutorial audio playback');
          _audioPlayer!.dispose();
          _audioPlayer = null;
        }
      });
    } catch (e) {
      print('Exception while playing tutorial audio: $e');
    }
  }


  @override
  void dispose() {
    // _tts.stop();
    // _tts.speakText('');
    // _tts.stop();
    _animationController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            // Background camera view simulation
            Image.asset(
              'assets/onboarding/corner_app_logo.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Tutorial overlay
            if (showTutorial)
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, _isDragging ? _dragDistance * 0.5 : 0, 0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      width: double.infinity,
                      height: double.infinity,
                      child: SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 20),

                              // App icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.remove_red_eye_outlined,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),

                              // Welcome text
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _isDataLoaded 
                                        ? _tutorialText['welcome']['title_prefix'] 
                                        : 'Welcome to "',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _isDataLoaded 
                                        ? _tutorialText['welcome']['title_app_name']
                                        : 'Speak Sight',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: 'Montserrat',
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _isDataLoaded 
                                        ? _tutorialText['welcome']['title_suffix']
                                        : '"!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Instructions
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  _isDataLoaded 
                                    ? _tutorialText['welcome']['intro']
                                    : "Loading...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                              SizedBox(height: 20),
                              ..._buildTutorial(),
                              SizedBox(height: 16),
                              Text(
                                _isDataLoaded
                                  ? _tutorialText['closing']['message']
                                  : "Enjoy discovering and exploring the world with",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.white70),
                              ),
                              
                              SizedBox(height: 40),
                              // Continue button
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              GestureDetector(
                onVerticalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragDistance = 0.0;
                  });
                },
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0) {
                    setState(() {
                      _dragDistance += details.delta.dy;
                    });
                    
                    if (_dragDistance > 10) {
                      HapticFeedback.heavyImpact();
                    }
                  }
                },
                onVerticalDragEnd: (details) {
                  if (_dragDistance > 100 || (details.primaryVelocity != null && details.primaryVelocity! > 300)) {
                    HapticFeedback.mediumImpact();
                    // _tts.forceStop();
                    Future.delayed(Duration(milliseconds: 200), () {
                      dispose();
                      Navigator.pop(context);
                    });
                  } else {
                    setState(() {
                      _isDragging = false;
                      _dragDistance = 0.0;
                    });
                  }
                },
                // 使这个GestureDetector覆盖整个屏幕
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent, // 透明背景
                ),
              ),
          ],
        ),
      
    );
  }

  List<Widget> _buildTutorial() {
    List<Widget> instructionWidgets = [];
    
    if (_isDataLoaded && _tutorialText.containsKey('instructions')) {
      List instructionsList = _tutorialText['instructions'];
      
      for (int i = 0; i < instructionsList.length; i++) {
        Map<String, dynamic> instruction = instructionsList[i];
        
        instructionWidgets.add(
          _buildInstructionItem(
            context,
            instruction['prefix'] ?? '',
            instruction['highlight'] ?? '',
            instruction['suffix'] ?? '',
          )
        );
        
        // Add spacing between instruction items
        if (i < instructionsList.length - 1) {
          instructionWidgets.add(SizedBox(height: 16));
        }
      }
    } else {
      // Fallback if JSON not loaded
      instructionWidgets.add(
        Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        )
      );
    }
    
    return instructionWidgets;
  }

  Widget _buildInstructionItem(
      BuildContext context, String prefix, String highlight, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: prefix + ' ',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            if (highlight.isNotEmpty)
              TextSpan(
                text: highlight,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            if (suffix.isNotEmpty)
              TextSpan(
                text: ' ' + suffix,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}