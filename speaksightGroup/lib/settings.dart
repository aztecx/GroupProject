import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) updateThemeMode;

  const SettingsPage({Key? key, required this.updateThemeMode}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  bool isDarkMode = true;
  bool useHighContrast = false;
  bool useLargeText = false;
  bool enableVoiceFeedback = true;
  double speechRate = 1.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? true;
      useHighContrast = prefs.getBool('highContrast') ?? false;
      useLargeText = prefs.getBool('largeText') ?? false;
      enableVoiceFeedback = prefs.getBool('voiceFeedback') ?? true;
      speechRate = prefs.getDouble('speechRate') ?? 1.0;
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setBool('highContrast', useHighContrast);
    await prefs.setBool('largeText', useLargeText);
    await prefs.setBool('voiceFeedback', enableVoiceFeedback);
    await prefs.setDouble('speechRate', speechRate);

    widget.updateThemeMode(isDarkMode);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
    });
    _saveSettings();
  }

  void _toggleHighContrast(bool value) {
    setState(() {
      useHighContrast = value;
    });
    _saveSettings();
  }

  void _toggleLargeText(bool value) {
    setState(() {
      useLargeText = value;
    });
    _saveSettings();
  }

  void _toggleVoiceFeedback(bool value) {
    setState(() {
      enableVoiceFeedback = value;
    });
    _saveSettings();
  }

  void _updateSpeechRate(double value) {
    setState(() {
      speechRate = value;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                isDark
                    ? Color(0xFF1E1E1E)
                    : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // App icon and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.settings,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Speak Sight Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Customize your experience',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Display settings section
                _buildSectionHeader(context, 'Display Settings'),
                _buildSettingCard(
                  context,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme for better visibility in low light',
                  icon: Icons.dark_mode,
                  color: Colors.indigo,
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: _toggleDarkMode,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                _buildSettingCard(
                  context,
                  title: 'High Contrast',
                  subtitle: 'Increase contrast for better readability',
                  icon: Icons.contrast,
                  color: Colors.amber,
                  trailing: Switch(
                    value: useHighContrast,
                    onChanged: _toggleHighContrast,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                _buildSettingCard(
                  context,
                  title: 'Large Text',
                  subtitle: 'Increase text size throughout the app',
                  icon: Icons.text_fields,
                  color: Colors.green,
                  trailing: Switch(
                    value: useLargeText,
                    onChanged: _toggleLargeText,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 24),

                // Accessibility settings section
                _buildSectionHeader(context, 'Accessibility'),
                _buildSettingCard(
                  context,
                  title: 'Voice Feedback',
                  subtitle: 'Enable spoken feedback for actions',
                  icon: Icons.record_voice_over,
                  color: Color(0xFFFF8000),
                  trailing: Switch(
                    value: enableVoiceFeedback,
                    onChanged: _toggleVoiceFeedback,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                _buildSettingCard(
                  context,
                  title: 'Speech Rate',
                  subtitle: 'Adjust the speed of spoken feedback',
                  icon: Icons.speed,
                  color: Colors.purple,
                  trailing: null,
                  showDivider: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slow',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: speechRate,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: speechRate.toStringAsFixed(1) + 'x',
                          onChanged: enableVoiceFeedback ? _updateSpeechRate : null,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        'Fast',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // About section
                _buildSectionHeader(context, 'About'),
                _buildSettingCard(
                  context,
                  title: 'Version',
                  subtitle: 'Speak Sight v1.0.0',
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Show app info dialog or navigate to about page
                  },
                ),
                _buildSettingCard(
                  context,
                  title: 'Help & Support',
                  subtitle: 'Get assistance with using the app',
                  icon: Icons.help_outline,
                  color: Colors.teal,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // Show help dialog or navigate to help page
                  },
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        Widget? trailing,
        VoidCallback? onTap,
        bool showDivider = true,
      }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              if (showDivider && onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}