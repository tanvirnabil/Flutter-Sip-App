import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../models/contact_item.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/sip_provider.dart';
import '../call/active_call_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#'.split('');

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _callContact(ContactItem contact, {bool isVideo = false}) {
    Haptics.medium();
    final sipProvider = context.read<SipProvider>();
    sipProvider.makeCall(contact.extension, isVideo: isVideo);
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
    );
  }

  void _showContactOptions(ContactItem contact, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(contact.name),
        message: Text('Number / Ext: ${contact.extension}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _callContact(contact, isVideo: false);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.phone_fill, color: AppColors.callGreen, size: 20),
                SizedBox(width: 8),
                Text('Voice Call (SIP)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _callContact(contact, isVideo: true);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.video_camera_solid, color: AppColors.accentBlue, size: 22),
                SizedBox(width: 8),
                Text('Video Call (WebRTC)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContactsProvider>().toggleFavorite(contact);
            },
            child: Text(contact.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
          ),
          if (!contact.isDeviceContact)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeleteContact(contact);
              },
              child: const Text('Delete Contact'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _confirmDeleteContact(ContactItem contact) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete "${contact.name}"?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContactsProvider>().deleteContact(contact.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddContactSheet() {
    final nameCtrl = TextEditingController();
    final extCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add New Contact',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(CupertinoIcons.person),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: extCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Extension or Phone Number',
                    prefixIcon: Icon(CupertinoIcons.phone),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    prefixIcon: Icon(CupertinoIcons.mail),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF75B928),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty && extCtrl.text.trim().isNotEmpty) {
                      context.read<ContactsProvider>().addContact(
                            name: nameCtrl.text,
                            extension: extCtrl.text,
                            email: emailCtrl.text,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Contact'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactsProv = context.watch<ContactsProvider>();
    final contacts = contactsProv.displayedContacts;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.plus,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            tooltip: 'Add Contact',
            onPressed: _showAddContactSheet,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Rounded Pill Search Bar (Matching Screenshot 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(21),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 18,
                      color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => contactsProv.setSearchQuery(val),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          contactsProv.setSearchQuery('');
                        },
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Segment Filter: App | Phone | Favorites
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: contactsProv.selectedSegment,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFF4),
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'App (${contactsProv.appContacts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Phone (${contactsProv.deviceContacts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '★ (${contactsProv.favorites.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) contactsProv.setSegment(val);
                  },
                ),
              ),
            ),

            // Contacts List with A-Z Index Bar (Zero Overflow Guaranteed)
            Expanded(
              child: contactsProv.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : (contactsProv.selectedSegment == 1 &&
                          !contactsProv.hasDevicePermission &&
                          contactsProv.deviceContacts.isEmpty)
                      ? _buildPermissionPrompt(isDark, contactsProv)
                      : contacts.isEmpty
                          ? _buildEmptyState(contactsProv)
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(bottom: 12),
                                  itemCount: contacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = contacts[index];
                                    final isFirstOfLetter = index == 0 ||
                                        _getLetterHeader(contacts[index - 1].name) !=
                                            _getLetterHeader(contact.name);

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isFirstOfLetter)
                                          _buildSectionHeader(
                                            _getLetterHeader(contact.name),
                                            isDark,
                                          ),
                                        _buildContactRow(contact, isDark),
                                      ],
                                    );
                                  },
                                ),

                                // Right-side A-Z Jump Bar (thin 18px width)
                                Positioned(
                                  top: 0,
                                  bottom: 12,
                                  right: 2,
                                  child: Center(
                                    child: Container(
                                      width: 18,
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _alphabet.map((letter) {
                                          return GestureDetector(
                                            onTap: () => _jumpToLetter(letter, contacts),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 1),
                                              child: Text(
                                                letter,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.brandPrimary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLetterHeader(String name) {
    if (name.trim().isEmpty) return '#';
    final firstChar = name.trim()[0].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
      return firstChar;
    }
    return '#';
  }

  Widget _buildSectionHeader(String letter, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF3C3C43),
        ),
      ),
    );
  }

  Widget _buildContactRow(ContactItem contact, bool isDark) {
    final initials = contact.name.trim().isNotEmpty
        ? contact.name
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showContactOptions(contact, isDark),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 24, top: 8, bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEFF4),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar placeholder matching Screenshot 2
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(6), // Soft rounded shape from screenshot
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Contact Name & Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700, // Bold as in screenshot
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.extension,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white54 : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),

              // Clean Single Call Trigger Icon
              GestureDetector(
                onTap: () => _callContact(contact, isVideo: false),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF75B928).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.phone_fill,
                    size: 16,
                    color: Color(0xFF75B928),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToLetter(String letter, List<ContactItem> contacts) {
    Haptics.selection();
    final index = contacts.indexWhere((c) {
      if (letter == '#') {
        final firstChar = c.name.trim().isNotEmpty ? c.name.trim()[0].toUpperCase() : '';
        return !RegExp(r'[A-Z]').hasMatch(firstChar);
      }
      return c.name.trim().toUpperCase().startsWith(letter);
    });

    if (index != -1 && _scrollController.hasClients) {
      final target = (index * 60.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildEmptyState(ContactsProvider prov) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text('No Contacts Found', style: TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPermissionPrompt(bool isDark, ContactsProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 52, color: AppColors.accentBlue),
            const SizedBox(height: 16),
            const Text(
              'Sync Phone Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow Aura VoIP to access your phonebook to place SIP calls to your device contacts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75B928),
                foregroundColor: Colors.white,
              ),
              onPressed: () => prov.loadDeviceContacts(requestPermission: true),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
