import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:uuid/uuid.dart';
import '../models/contact_item.dart';
import '../services/contacts_service.dart';

class ContactsProvider extends ChangeNotifier {
  final ContactsService _service = ContactsService();

  List<ContactItem> _appContacts = [];
  List<ContactItem> _deviceContacts = [];
  List<ContactItem> _favorites = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingDeviceContacts = false;
  bool _hasDevicePermission = false;
  int _selectedSegment = 0; // 0: App, 1: Device Phonebook, 2: Favorites

  List<ContactItem> get appContacts => _appContacts;
  List<ContactItem> get deviceContacts => _deviceContacts;
  List<ContactItem> get favorites => _favorites;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading || _isLoadingDeviceContacts;
  bool get hasDevicePermission => _hasDevicePermission;
  int get selectedSegment => _selectedSegment;

  List<ContactItem> get displayedContacts {
    List<ContactItem> list;
    if (_selectedSegment == 0) {
      list = _appContacts;
    } else if (_selectedSegment == 1) {
      list = _deviceContacts;
    } else {
      list = _favorites;
    }

    if (_searchQuery.trim().isEmpty) return list;
    final query = _searchQuery.toLowerCase().trim();
    return list.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.extension.toLowerCase().contains(query) ||
          (c.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  ContactsProvider() {
    loadContacts();
  }

  void setSegment(int index) {
    _selectedSegment = index;
    if (index == 1 && _deviceContacts.isEmpty && !_isLoadingDeviceContacts) {
      loadDeviceContacts();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _appContacts = await _service.getAllContacts();
      _favorites = await _service.getFavorites();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDeviceContacts({bool requestPermission = true}) async {
    _isLoadingDeviceContacts = true;
    notifyListeners();

    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      final permission = status == PermissionStatus.granted || status == PermissionStatus.limited;
      _hasDevicePermission = permission;

      if (permission) {
        final rawContacts = await FlutterContacts.getAll(
          properties: {ContactProperty.phone, ContactProperty.email},
        );

        final List<ContactItem> converted = [];
        for (final c in rawContacts) {
          if (c.phones.isNotEmpty) {
            for (final phone in c.phones) {
              final cleanNumber = phone.number.replaceAll(RegExp(r'[^0-9+]'), '');
              if (cleanNumber.isNotEmpty) {
                final dispName = (c.displayName != null && c.displayName!.trim().isNotEmpty)
                    ? c.displayName!.trim()
                    : cleanNumber;
                converted.add(
                  ContactItem(
                    id: 'dev_${c.id ?? cleanNumber}_$cleanNumber',
                    name: dispName,
                    extension: cleanNumber,
                    email: c.emails.isNotEmpty ? c.emails.first.address : null,
                    isDeviceContact: true,
                  ),
                );
              }
            }
          }
        }
        _deviceContacts = converted;
      }
    } catch (_) {}

    _isLoadingDeviceContacts = false;
    notifyListeners();
  }

  Future<void> addContact({
    required String name,
    required String extension,
    String? email,
  }) async {
    final newContact = ContactItem(
      id: const Uuid().v4(),
      name: name.trim(),
      extension: extension.trim(),
      email: email?.trim(),
      isFavorite: false,
      isDeviceContact: false,
    );
    await _service.addContact(newContact);
    await loadContacts();
  }

  Future<void> toggleFavorite(ContactItem contact) async {
    if (contact.isDeviceContact) {
      // Save device contact as favorite in app database
      final exists = _favorites.any((f) => f.extension == contact.extension);
      if (exists) {
        final existing = _favorites.firstWhere((f) => f.extension == contact.extension);
        await _service.deleteContact(existing.id);
      } else {
        await _service.addContact(contact.copyWith(
          id: const Uuid().v4(),
          isFavorite: true,
          isDeviceContact: false,
        ));
      }
    } else {
      await _service.toggleFavorite(contact.id, contact.isFavorite);
    }
    await loadContacts();
  }

  Future<void> deleteContact(String id) async {
    await _service.deleteContact(id);
    await loadContacts();
  }
}
