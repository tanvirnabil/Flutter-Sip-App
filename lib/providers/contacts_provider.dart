import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/contact_item.dart';
import '../services/contacts_service.dart';

class ContactsProvider extends ChangeNotifier {
  final ContactsService _service = ContactsService();

  List<ContactItem> _allContacts = [];
  List<ContactItem> _favorites = [];
  String _searchQuery = '';
  bool _isLoading = false;
  int _selectedSegment = 0; // 0: All, 1: Favorites

  List<ContactItem> get allContacts => _allContacts;
  List<ContactItem> get favorites => _favorites;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  int get selectedSegment => _selectedSegment;

  List<ContactItem> get displayedContacts {
    final list = _selectedSegment == 0 ? _allContacts : _favorites;
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
      _allContacts = await _service.getAllContacts();
      _favorites = await _service.getFavorites();
    } catch (_) {}
    _isLoading = false;
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
    );
    await _service.addContact(newContact);
    await loadContacts();
  }

  Future<void> toggleFavorite(ContactItem contact) async {
    await _service.toggleFavorite(contact.id, contact.isFavorite);
    await loadContacts();
  }

  Future<void> deleteContact(String id) async {
    await _service.deleteContact(id);
    await loadContacts();
  }
}
