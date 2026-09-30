import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../models/sip_account.dart';
import '../../services/sip_service.dart';
import '../../providers/sip_provider.dart';
import '../main_navigation_screen.dart';

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
  final _portController = TextEditingController(text: '8089');
  final _stunController = TextEditingController(text: 'stun:stun.l.google.com:19302');

  bool _obscurePassword = true;
  bool _showAdvanced = false;
  bool _isWebRtc = true;
  String _transport = 'wss';

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

    final port = int.tryParse(_portController.text.trim()) ?? (_isWebRtc ? 8089 : 5060);

    final account = SipAccount(
      extension: _extensionController.text.trim(),
      password: _passwordController.text.trim(),
      domain: _domainController.text.trim(),
      displayName: _displayNameController.text.trim(),
      port: port,
      isWebRtc: _isWebRtc,
      transport: _transport,
      stunServer: _stunController.text.trim(),
    );

    final sip = context.read<SipProvider>();
    await sip.register(account);

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
    final sip = context.watch<SipProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aura VoIP',
                    textAlign: TextAlign.center,
                    style: AppTypography.title1.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simple, secure SIP for Asterisk & FreePBX',
                    textAlign: TextAlign.center,
                    style: AppTypography.subhead.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildInputLabel('EXTENSION / USERNAME', isDark),
                  TextFormField(
                    controller: _extensionController,
                    keyboardType: TextInputType.text,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1001 or tanvir',
                      prefixIcon: Icon(CupertinoIcons.person_crop_circle),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your extension' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('PASSWORD', isDark),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'SIP Secret / Password',
                      prefixIcon: const Icon(CupertinoIcons.lock_shield),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                          color: AppColors.lightTextSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter password' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('DOMAIN / PBX HOST', isDark),
                  TextFormField(
                    controller: _domainController,
                    keyboardType: TextInputType.url,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'e.g. pbx.yourcompany.com or 192.168.1.100',
                      prefixIcon: Icon(CupertinoIcons.globe),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter PBX host' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('CALLER DISPLAY NAME (OPTIONAL)', isDark),
                  TextFormField(
                    controller: _displayNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Tanvir Nabil',
                      prefixIcon: Icon(CupertinoIcons.tag),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Haptics.selection();
                      setState(() => _showAdvanced = !_showAdvanced);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAdvanced ? 'Hide Advanced Settings' : 'Show Advanced Settings',
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          _showAdvanced ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                          color: AppColors.accentBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0x22FFFFFF) : const Color(0x15000000),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WebRTC Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const Text(
                                    'Recommended for Asterisk 16+ & FreePBX',
                                    style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                  ),
                                ],
                              ),
                              CupertinoSwitch(
                                value: _isWebRtc,
                                activeTrackColor: AppColors.accentBlue,
                                onChanged: (val) {
                                  setState(() {
                                    _isWebRtc = val;
                                    _portController.text = val ? '8089' : '5060';
                                    _transport = val ? 'wss' : 'udp';
                                  });
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel('PORT', isDark),
                                    TextFormField(
                                      controller: _portController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel('TRANSPORT', isDark),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _transport,
                                          isExpanded: true,
                                          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                                          items: const [
                                            DropdownMenuItem(value: 'wss', child: Text('WSS (Secure)')),
                                            DropdownMenuItem(value: 'ws', child: Text('WS (Plain)')),
                                            DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                                            DropdownMenuItem(value: 'udp', child: Text('UDP')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setState(() => _transport = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInputLabel('STUN SERVER', isDark),
                          TextFormField(
                            controller: _stunController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.callGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      sip.status == SipConnectionStatus.connecting ? 'Connecting...' : 'Connect SIP Account',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(builder: (_) => const MainNavigationScreen()),
                      );
                    },
                    child: const Text(
                      'Open Softphone Workspace',
                      style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
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

  Widget _buildInputLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

