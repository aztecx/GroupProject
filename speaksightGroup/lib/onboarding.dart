import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 
 class OnboardingPage extends StatefulWidget {
   @override
   _OnboardingPageState createState() => _OnboardingPageState();
 }
 
 class _OnboardingPageState extends State<OnboardingPage>
     with SingleTickerProviderStateMixin {
   bool showTutorial = true;
   late AnimationController _animationController;
   late Animation<double> _fadeAnimation;
 
   @override
   void initState() {
     super.initState();
     _animationController = AnimationController(
       vsync: this,
       duration: Duration(milliseconds: 800),
     );
     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
         CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
     _animationController.forward();
   }
 
   @override
   void dispose() {
     _animationController.dispose();
     super.dispose();
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: Stack(
         children: [
           // Background camera view simulation
           Image.asset(
             'assets/fonts/corner_app_logo.png', // Certifique-se de que este arquivo existe
             fit: BoxFit.cover,
             width: double.infinity,
             height: double.infinity,
           ),
           // Tutorial overlay
           if (showTutorial)
             FadeTransition(
               opacity: _fadeAnimation,
               child: Container(
                 color: Colors.black.withOpacity(0.8),
                 width: double.infinity,
                 height: double.infinity,
                 child: SafeArea(
                   child: SingleChildScrollView(
                     // Adicionado para evitar overflow
                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                     child: Column(
                       mainAxisSize:
                       MainAxisSize.min, // Ajuste para evitar overflow
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
                                 text: 'Welcome to "',
                                 style: TextStyle(
                                   fontSize: 24,
                                   color: Colors.white,
                                 ),
                               ),
                               TextSpan(
                                 text: 'Speak Sight',
                                 style: TextStyle(
                                   fontSize: 17,
                                   fontFamily: 'Montserrat',
                                   color: Theme.of(context).primaryColor,
                                 ),
                               ),
                               TextSpan(
                                 text: '"!',
                                 style: TextStyle(
                                   fontSize: 24,
                                   color: Colors.white,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         SizedBox(height: 24),
                         // Instructions
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 24.0),
                           child: Text(
                             "This application uses your phone's camera to help you better understand your surroundings through audio feedback.",
                             textAlign: TextAlign.center,
                             style: TextStyle(fontSize: 18, color: Colors.white),
                           ),
                         ),
                         SizedBox(height: 20),
                         _buildInstructionItem(
                             context,
                             'For the best experience with minimal on-screen distractions, simply',
                             'swipe down',
                             'anywhere on the screen to close this tutorial and enter the camera view — your default start screen.'),
                         SizedBox(height: 16),
                         _buildInstructionItem(
                             context,
                             'There are three modes available: Object Detection, Object Search, and Text Recognition.',
                             '',
                             ''),
                         SizedBox(height: 16),
                         _buildInstructionItem(
                             context,
                             'To switch between modes, just',
                             'Swipe Left or Right',
                             'anywhere on the screen; the active mode will be highlighted.'),
                         SizedBox(height: 16),
                         _buildInstructionItem(
                             context,
                             'If you'
                                 'd wish to review these instructions again, simply',
                             'swipe up',
                             'anywhere on the screen while in the camera view to re-open the tutorial panel.'),
                         SizedBox(height: 16),
                         Text(
                           'Enjoy discovering and exploring the world with',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 16, color: Colors.white70),
                         ),
                         SizedBox(height: 8),
                         Text(
                           '"Speak Sight"!',
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontSize: 22,
                             fontWeight: FontWeight.bold,
                             color: Theme.of(context).primaryColor,
                           ),
                         ),
                         SizedBox(height: 40),
                         // Continue button
                         GestureDetector(
                           onTap: () {
                             HapticFeedback.mediumImpact();
                             Navigator.pushReplacementNamed(context, '/');
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
         ],
       ),
     );
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