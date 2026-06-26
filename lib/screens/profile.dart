// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:lumina/services/auth_service.dart';
import 'package:lumina/services/document_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _documentService.addListener(_onDocumentsChanged);
  }

  @override
  void dispose() {
    _documentService.removeListener(_onDocumentsChanged);
    super.dispose();
  }

  void _onDocumentsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryPurple = const Color(0xFF5A4EE3);
    final backgroundColor = Colors.white;
    final textDark = const Color(0xFF1E293B);
    final textMuted = const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Page Title
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Header Card
              _buildProfileHeader(primaryPurple, textDark, textMuted),
              const SizedBox(height: 24),

              // Logout Button
              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color primary, Color textDark, Color textMuted) {
    final user = AuthService().currentUser;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar (Edit action removed)
          CircleAvatar(
            radius: 40,
            backgroundColor: primary.withAlpha(25),
            backgroundImage:
                user?.photoURL != null && user!.photoURL!.isNotEmpty
                ? NetworkImage(user.photoURL!) as ImageProvider
                : null,
            child: user?.photoURL != null && user!.photoURL!.isNotEmpty
                ? null
                : Icon(Icons.person_rounded, color: primary, size: 44),
          ),
          const SizedBox(width: 20),

          // User Info & Premium Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Kullanıcı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'E-posta tanımlanmamış',
                  style: TextStyle(fontSize: 14, color: textMuted),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          await AuthService().signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent.shade700,
          side: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
