import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../models/sip_account.dart';
import '../../providers/sip_provider.dart';
import '../main_navigation_screen.dart';
import '../widgets/app_logo.dart';

class SipLoginScreen extends StatefulWidget {
  const SipLoginScreen({super.key});

  @override
  State<SipLoginScreen> createState() => _SipLoginScreenState();
}

class _SipLoginScreenState extends State<SipLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _extensionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _domainController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _portController = TextEditingController(text: '5060');
  final _stunController = TextEditingController(text: 'stun:stun.l.google.com:19302');

  bool _obscurePassword = true;
  bool _showAdvanced = false;
  bool _isWebRtc = false;
  String _transport = 'udp';
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sip = context.read<SipProvider>();
      if (sip.account != null) {
        _populateFields(sip.account!);
      }
    });
  }

  void _populateFields(SipAccount account) {
    _extensionController.text = account.extension;
    _passwordController.text = account.password;
    _domainController.text = account.domain;
    _displayNameController.text = account.displayName;
    _portController.text = account.port.toString();
    _isWebRtc = account.isWebRtc;
    _transport = account.transport;
    _stunController.text = account.stunServer;
    setState(() {});
  }

  @override
  void dispose() {
    _extensionController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _displayNameController.dispose();
    _portController.dispose();
    _stunController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    Haptics.medium();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final port = int.tryParse(_portController.text.trim()) ?? (_isWebRtc ? 8089 : 5060);

    final account = SipAccount(
      extension: _extensionController.text.trim(),
      password: _passwordController.text.trim(),
      domain: _domainController.text.trim(),
      displayName: _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : 'SOHUB ${_extensionController.text.trim()}',
      port: port,
      isWebRtc: _isWebRtc,
      transport: _transport,
      stunServer: _stunController.text.trim(),
    );

    final sip = context.read<SipProvider>();
    await sip.register(account);

    setState(() => _isConnecting = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Clean Softphone Branding
                  const Center(child: AppLogo(size: 84)),
                  const SizedBox(height: 20),
                  Text(
                    'Clario',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next-Gen VoIP & SIP Softphone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Extension / Username
                  _buildSectionLabel('EXTENSION / USERNAME', isDark),
                  _buildTextField(
                    controller: _extensionController,
                    hint: 'e.g. 101 or 1001',
                    icon: CupertinoIcons.person_crop_circle,
                    isDark: isDark,
                    keyboardType: TextInputType.text,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your SIP extension' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildSectionLabel('PASSWORD / SECRET', isDark),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'SIP Secret Password',
                    icon: CupertinoIcons.lock,
                    isDark: isDark,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        size: 20,
                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 16),

                  // Domain / PBX Host
                  _buildSectionLabel('DOMAIN / PBX SERVER', isDark),
                  _buildTextField(
                    controller: _domainController,
                    hint: 'e.g. sip.ranksitt.net or 192.168.1.100',
                    icon: CupertinoIcons.globe,
                    isDark: isDark,
                    keyboardType: TextInputType.url,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter PBX domain or IP' : null,
                  ),
                  const SizedBox(height: 16),

                  // Caller Display Name
                  _buildSectionLabel('CALLER DISPLAY NAME (OPTIONAL)', isDark),
                  _buildTextField(
                    controller: _displayNameController,
                    hint: 'e.g. SOHUB 105 or Tanvir',
                    icon: CupertinoIcons.tag,
                    isDark: isDark,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),

                  // Connection Protocol Selector (UDP / TCP / WebRTC)
                  _buildSectionLabel('CONNECTION PROTOCOL', isDark),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _isWebRtc ? 'webrtc' : _transport,
                      backgroundColor: Colors.transparent,
                      children: const {
                        'udp': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('UDP (Native)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        'tcp': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('TCP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        'webrtc': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('WebRTC (WS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          if (val == 'webrtc') {
                            _isWebRtc = true;
                            _transport = 'ws';
                            if (_portController.text == '5060') _portController.text = '8089';
                          } else {
                            _isWebRtc = false;
                            _transport = val;
                            if (_portController.text == '8089') _portController.text = '5060';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advanced Settings Toggle
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvanced ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                            size: 16,
                            color: const Color(0xFF75B928),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Advanced Network Settings',
                            style: TextStyle(
                              color: Color(0xFF75B928),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible Advanced Fields
                  if (_showAdvanced) ...[
                    const SizedBox(height: 12),
                    _buildSectionLabel('SIP PORT', isDark),
                    _buildTextField(
                      controller: _portController,
                      hint: '5060',
                      icon: CupertinoIcons.number,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _buildSectionLabel('STUN / ICE SERVER', isDark),
                    _buildTextField(
                      controller: _stunController,
                      hint: 'stun:stun.l.google.com:19302',
                      icon: CupertinoIcons.shield,
                      isDark: isDark,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Connect & Register Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isConnecting ? null : _handleConnect,
                      child: _isConnecting
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'Connect & Register',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
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

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          width: 0.8,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }
}
