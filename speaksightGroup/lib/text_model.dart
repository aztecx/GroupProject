/// DEPRECATED FILE
/// 
/// This file contains a previous implementation of the Text Recognition UI
/// that has been deprecated. The text recognition functionality has been
/// integrated directly into homepage.dart for a more streamlined user experience.
/// 
/// This file is kept for reference purposes only and is not used in the current
/// application. The implementation shows a standalone text recognition page with:
///   - Camera preview
///   - Text detection animation
///   - Detected text display area
///   - Controls for capturing, reading, and copying text
///
/// For the current implementation, please see the text recognition functionality
/// in homepage.dart.
///
/// Original implementation is commented out below:


// import 'package:flutter/material.dart';
//  import 'package:vibration/vibration.dart';
//  import 'package:flutter/services.dart';
 


//  class TextModelPage extends StatefulWidget {
//    @override
//    _TextModelPageState createState() => _TextModelPageState();
//  }
 
//  class _TextModelPageState extends State<TextModelPage> with SingleTickerProviderStateMixin {
//    late AnimationController _animationController;
//    late Animation<double> _fadeAnimation;
//    String? detectedText;
//    bool isProcessing = false;
 
//    @override
//    void initState() {
//      super.initState();
//      _animationController = AnimationController(
//        vsync: this,
//        duration: Duration(milliseconds: 1500),
//      );
 
//      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//          CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
//      );
 
//      _animationController.forward();
 
//      // Simulate text detection after a delay
//      Future.delayed(Duration(seconds: 2), () {
//        setState(() {
//          isProcessing = true;
//        });
 
//        Future.delayed(Duration(seconds: 3), () {
//          setState(() {
//            detectedText = "Sample detected text. This feature would use OCR to read text from the camera.";
//            isProcessing = false;
//          });
//        });
//      });
//    }
 
//    @override
//    void dispose() {
//      _animationController.dispose();
//      super.dispose();
//    }
 
//    @override
//    Widget build(BuildContext context) {
//      return Scaffold(
//        extendBodyBehindAppBar: true,
//        appBar: AppBar(
//          backgroundColor: Colors.transparent,
//          elevation: 0,
//          title: Text(
//            'Text Recognition',
//            style: TextStyle(
//              fontWeight: FontWeight.bold,
//              fontSize: 24,
//            ),
//          ),
//          leading: IconButton(
//            icon: Icon(Icons.arrow_back_ios),
//            onPressed: () => Navigator.pop(context),
//          ),
//        ),
//        body: Container(
//          decoration: BoxDecoration(
//            gradient: LinearGradient(
//              begin: Alignment.topCenter,
//              end: Alignment.bottomCenter,
//              colors: [
//                Colors.black,
//                Color(0xFF1E1E1E),
//              ],
//            ),
//          ),
//          child: FadeTransition(
//            opacity: _fadeAnimation,
//            child: SafeArea(
//              child: Column(
//                children: [
//                  // Camera placeholder (mockup)
//                  Expanded(
//                    flex: 2,
//                    child: Container(
//                      margin: EdgeInsets.all(16),
//                      decoration: BoxDecoration(
//                        color: Colors.black38,
//                        borderRadius: BorderRadius.circular(24),
//                        border: Border.all(
//                          color: Theme.of(context).primaryColor,
//                          width: 2,
//                        ),
//                      ),
//                      child: Stack(
//                        children: [
//                          Center(
//                            child: Icon(
//                              Icons.document_scanner,
//                              size: 100,
//                              color: Colors.white.withOpacity(0.3),
//                            ),
//                          ),
//                          if (isProcessing)
//                            Center(
//                              child: Column(
//                                mainAxisSize: MainAxisSize.min,
//                                children: [
//                                  SizedBox(
//                                    width: 60,
//                                    height: 60,
//                                    child: CircularProgressIndicator(
//                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8000)),
//                                      strokeWidth: 3,
//                                    ),
//                                  ),
//                                  SizedBox(height: 16),
//                                  Text(
//                                    'Processing text...',
//                                    style: TextStyle(
//                                      color: Colors.white,
//                                      fontSize: 18,
//                                    ),
//                                  ),
//                                ],
//                              ),
//                            ),
//                          // Scanning effect
//                          AnimatedBuilder(
//                            animation: _animationController,
//                            builder: (context, child) {
//                              return Positioned(
//                                left: 0,
//                                right: 0,
//                                top: _animationController.value * 300,
//                                child: Container(
//                                  height: 2,
//                                  color: Color(0xFFFF8000),
//                                ),
//                              );
//                            },
//                          ),
//                        ],
//                      ),
//                    ),
//                  ),
 
//                  // Detected text area
//                  Expanded(
//                    flex: 1,
//                    child: Container(
//                      margin: EdgeInsets.all(16),
//                      padding: EdgeInsets.all(16),
//                      decoration: BoxDecoration(
//                        color: Colors.white.withOpacity(0.1),
//                        borderRadius: BorderRadius.circular(16),
//                      ),
//                      child: Column(
//                        crossAxisAlignment: CrossAxisAlignment.start,
//                        children: [
//                          Row(
//                            children: [
//                              Icon(
//                                Icons.text_fields,
//                                color: Color(0xFFFF8000),
//                              ),
//                              SizedBox(width: 8),
//                              Text(
//                                'Detected Text',
//                                style: TextStyle(
//                                  fontSize: 18,
//                                  fontWeight: FontWeight.bold,
//                                  color: Colors.white,
//                                ),
//                              ),
//                            ],
//                          ),
//                          SizedBox(height: 16),
//                          Expanded(
//                            child: SingleChildScrollView(
//                              child: Text(
//                                detectedText ?? 'Point your camera at text to scan it',
//                                style: TextStyle(
//                                  fontSize: 16,
//                                  color: Colors.white.withOpacity(0.9),
//                                ),
//                              ),
//                            ),
//                          ),
//                        ],
//                      ),
//                    ),
//                  ),
 
//                  // Bottom controls
//                  Container(
//                    padding: EdgeInsets.all(16),
//                    child: Row(
//                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                      children: [
//                        _buildControlButton(
//                          icon: Icons.camera,
//                          label: 'Capture',
//                          color: Color(0xFFFF8000),
//                          onTap: () {
//                            HapticFeedback.mediumImpact();
//                            setState(() {
//                              isProcessing = true;
//                              detectedText = null;
 
//                              // Reset scanning animation
//                              _animationController.reset();
//                              _animationController.forward();
 
//                              // Simulate text detection
//                              Future.delayed(Duration(seconds: 2), () {
//                                setState(() {
//                                  detectedText = "New captured text sample. In a real app, this would be text recognized from the camera.";
//                                  isProcessing = false;
//                                });
//                              });
//                            });
//                          },
//                        ),
//                        _buildControlButton(
//                          icon: Icons.volume_up,
//                          label: 'Speak',
//                          color: Theme.of(context).primaryColor,
//                          onTap: () {
//                            HapticFeedback.mediumImpact();
//                            ScaffoldMessenger.of(context).showSnackBar(
//                              SnackBar(
//                                content: Text('Reading text aloud...'),
//                                backgroundColor: Theme.of(context).primaryColor,
//                              ),
//                            );
//                          },
//                        ),
//                        _buildControlButton(
//                          icon: Icons.copy,
//                          label: 'Copy',
//                          color: Colors.purple,
//                          onTap: () {
//                            if (detectedText != null) {
//                              HapticFeedback.mediumImpact();
//                              Clipboard.setData(ClipboardData(text: detectedText!));
//                              ScaffoldMessenger.of(context).showSnackBar(
//                                SnackBar(
//                                  content: Text('Text copied to clipboard'),
//                                  backgroundColor: Colors.purple,
//                                ),
//                              );
//                            }
//                          },
//                        ),
//                      ],
//                    ),
//                  ),
//                ],
//              ),
//            ),
//          ),
//        ),
//      );
//    }
 
//    Widget _buildControlButton({
//      required IconData icon,
//      required String label,
//      required Color color,
//      required VoidCallback onTap,
//    }) {
//      return GestureDetector(
//        onTap: onTap,
//        child: Column(
//          mainAxisSize: MainAxisSize.min,
//          children: [
//            Container(
//              width: 60,
//              height: 60,
//              decoration: BoxDecoration(
//                color: color.withOpacity(0.2),
//                shape: BoxShape.circle,
//                border: Border.all(color: color, width: 2),
//              ),
//              child: Icon(
//                icon,
//                color: color,
//                size: 30,
//              ),
//            ),
//            SizedBox(height: 8),
//            Text(
//              label,
//              style: TextStyle(
//                color: Colors.white,
//                fontSize: 14,
//              ),
//            ),
//          ],
//        ),
//      );
//    }
//  }