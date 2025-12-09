import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings/app_theme.dart';
import 'settings/app_strings.dart';
import 'home_page.dart';

/// This page is used ONLY for NEW users right after registration / first login.
/// After saving, it sends the user directly to the HomePage.
class ProfileSetupPage extends StatefulWidget {
  final User user; // passed from Splash/AuthGate

  const ProfileSetupPage({super.key, required this.user});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationDescriptionController = TextEditingController();

  String gender = 'male';
  bool loading = true;
  bool saving = false;
  String? errorText;

  User get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadProfileIfExists();
  }

  Future<void> _loadProfileIfExists() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (!doc.exists) {
        // New user → keep fields empty, just stop loading
        setState(() {
          loading = false;
        });
        return;
      }

      final data = doc.data() ?? {};

      setState(() {
        _nameController.text = (data['name'] ?? '') as String;
        _phoneController.text = (data['phone'] ?? '') as String;
        _locationController.text = (data['location'] ?? '') as String;
        _locationDescriptionController.text =
        (data['locationDescription'] ?? '') as String;
        gender = (data['gender'] ?? 'male') as String;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorText = 'Error loading profile: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    final s = S.of(context);

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      setState(() {
        errorText = s.profileRequiredFieldsError;
      });
      return;
    }

    setState(() {
      saving = true;
      errorText = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .set(
        {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'locationDescription': _locationDescriptionController.text.trim(),
          'gender': gender,
          'email': _user.email,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.profileUpdated)),
      );

      // 🔥 IMPORTANT:
      // This is SETUP, not edit → go straight to HomePage
      // and clear the stack so back button doesn't come back here.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = 'Error saving profile: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _locationDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // you can add a separate S string like s.setupProfileTitle
        title: Text(s.editProfileTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                // small header card with avatar + email
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                          AppColors.orange.withOpacity(0.15),
                          child: Text(
                            (_nameController.text.isNotEmpty
                                ? _nameController.text[0]
                                : (_user.email ?? '?')[0])
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : (_user.email ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_user.email != null)
                                Text(
                                  _user.email!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: s.fullNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: s.phoneNumberLabel,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: s.locationLabel,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationDescriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: s.locationDescriptionLabel,
                    hintText: s.locationDescriptionHint,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: s.genderLabel,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text(s.genderMale),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text(s.genderFemale),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      gender = value ?? 'male';
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (errorText != null) ...[
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _saveProfile,
                    child: Text(
                      saving
                          ? s.savingProfileText
                          : s.saveProfileButton,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
