import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
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

  void _callContact(ContactItem contact) {
    final sipProvider = context.read<SipProvider>();
    sipProvider.makeCall(contact.extension);
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const ActiveCallScreen()),
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
        title: const Text('Directory'),
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
            // Apple-style Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search name or extension...',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: (val) => contactsProv.setSearchQuery(val),
              ),
            ),

            // Segmented Filter: All vs. Favorites
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
                        'All (${contactsProv.allContacts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.star_fill, size: 14, color: AppColors.warningOrange),
                          const SizedBox(width: 4),
                          Text(
                            'Favorites (${contactsProv.favorites.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

            // Contact List with Right Alphabet Fast Index
            Expanded(
              child: contactsProv.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                contactsProv.selectedSegment == 1
                                    ? CupertinoIcons.star
                                    : CupertinoIcons.person_2,
                                size: 54,
                                color: Colors.grey.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                contactsProv.selectedSegment == 1
                                    ? 'No favorites yet'
                                    : 'No contacts found',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
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
      direction: DismissDirection.endToStart,
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
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentBlue.withValues(alpha: 0.8),
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
              fontSize: 16,
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
                'Ext ${contact.extension}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            if (contact.email != null && contact.email!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contact.email!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                contact.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: contact.isFavorite ? AppColors.warningOrange : Colors.grey.withValues(alpha: 0.5),
                size: 22,
              ),
              onPressed: () {
                context.read<ContactsProvider>().toggleFavorite(contact);
              },
            ),
            IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.callGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 18),
              ),
              onPressed: () => _callContact(contact),
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
