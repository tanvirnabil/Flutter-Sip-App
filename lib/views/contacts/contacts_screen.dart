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

  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

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
        message: Text('Ext / Number: ${contact.extension}'),
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
        content: Text('Are you sure you want to remove "${contact.name}" from your contacts?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ContactsProvider>().deleteContact(contact.id);
            },
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
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, size: 26, color: AppColors.accentBlue),
            tooltip: 'Add Contact',
            onPressed: _showAddContactSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search contacts...',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: (val) => contactsProv.setSearchQuery(val),
              ),
            ),

            // 3-way Segmented Filter: App | Phone Contacts | Favorites
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: contactsProv.selectedSegment,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'App (${contactsProv.appContacts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Phone (${contactsProv.deviceContacts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.star_fill, size: 13, color: AppColors.warningOrange),
                          const SizedBox(width: 4),
                          Text(
                            'Favorites (${contactsProv.favorites.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) contactsProv.setSegment(val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Contacts List
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
                                ListView.separated(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(left: 16, right: 36, bottom: 20),
                                  itemCount: contacts.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    indent: 64,
                                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                  ),
                                  itemBuilder: (context, index) {
                                    final contact = contacts[index];
                                    return _buildContactTile(contact, isDark);
                                  },
                                ),

                                // Right-side A-Z Jump Bar
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 4,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _alphabet.map((letter) {
                                          return GestureDetector(
                                            onTap: () => _jumpToLetter(letter, contacts),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
                                              child: Text(
                                                letter,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.accentBlue,
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

  Widget _buildPermissionPrompt(bool isDark, ContactsProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 54, color: AppColors.accentBlue),
            const SizedBox(height: 16),
            const Text(
              'Sync Phone Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Allow Aura VoIP to access your contacts to call people directly from your phone address book.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => prov.loadDeviceContacts(requestPermission: true),
              child: const Text('Allow Contacts Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ContactsProvider prov) {
    String message = 'No contacts added yet';
    if (prov.selectedSegment == 1) message = 'No contacts found on phone';
    if (prov.selectedSegment == 2) message = 'No favorite contacts yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            prov.selectedSegment == 2
                ? CupertinoIcons.star
                : CupertinoIcons.person_2,
            size: 54,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          if (prov.selectedSegment == 0) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: _showAddContactSheet,
              child: const Text('Add Your First Contact'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactTile(ContactItem contact, bool isDark) {
    final initials = contact.name.trim().isNotEmpty
        ? contact.name
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Dismissible(
      key: Key(contact.id),
      direction: contact.isDeviceContact ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: AppColors.endCallRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(CupertinoIcons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<ContactsProvider>().deleteContact(contact.id);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        onTap: () => _showContactOptions(contact, isDark),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                contact.isDeviceContact
                    ? const Color(0xFF34C759)
                    : AppColors.accentBlue,
                const Color(0xFF5856D6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                contact.isDeviceContact ? contact.extension : 'Ext ${contact.extension}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            if (contact.isDeviceContact) ...[
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.device_phone_portrait, size: 12, color: Colors.grey),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                contact.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: contact.isFavorite ? AppColors.warningOrange : Colors.grey.withValues(alpha: 0.4),
                size: 20,
              ),
              onPressed: () {
                context.read<ContactsProvider>().toggleFavorite(contact);
              },
            ),
            // Video Call Button
            IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.video_camera_solid, color: AppColors.accentBlue, size: 18),
              ),
              onPressed: () => _callContact(contact, isVideo: true),
            ),
            // Voice Call Button
            IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.callGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 16),
              ),
              onPressed: () => _callContact(contact, isVideo: false),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToLetter(String letter, List<ContactItem> contacts) {
    final index = contacts.indexWhere((c) => c.name.toUpperCase().startsWith(letter));
    if (index != -1 && _scrollController.hasClients) {
      final offset = (index * 68.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }
}
