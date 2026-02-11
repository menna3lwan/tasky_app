import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/services/profile_service.dart';
import '../../utilities/services/streak_service.dart';
import '../auth/login_screen.dart';

/// User profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();
  final _streakService = StreakService();
  final _imagePicker = ImagePicker();

  UserProfile? _profile;
  StreakData? _streakData;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final profile = await _profileService.getProfile();
    final streakData = await _streakService.getStreakData();

    if (mounted) {
      setState(() {
        _profile = profile;
        _streakData = streakData;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_profile?.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.pop(context, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null && _profile?.photoUrl != null) {
      // Remove photo
      setState(() => _isUploading = true);
      final result = await _profileService.deleteProfileImage();
      if (mounted) {
        setState(() => _isUploading = false);
        if (result.isSuccess) {
          _loadData();
        } else {
          _showError(result.errorMessage ?? 'Failed to remove photo');
        }
      }
      return;
    }

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final result = await _profileService.uploadProfileImage(
        File(pickedFile.path),
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (result.isSuccess) {
          _loadData();
        } else {
          _showError(result.errorMessage ?? 'Failed to upload image');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Failed to pick image');
      }
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _profile?.displayName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    final result = await _profileService.updateDisplayName(newName);
    if (mounted) {
      if (result.isSuccess) {
        _loadData();
      } else {
        _showError(result.errorMessage ?? 'Failed to update name');
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(mobile: 18, tablet: 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  responsive.spacing(mobile: 20, tablet: 24),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.contentMaxWidth,
                    ),
                    child: Column(
                      children: [
                        // Profile header
                        _buildProfileHeader(responsive),
                        SizedBox(
                          height: responsive.spacing(mobile: 32, tablet: 40),
                        ),

                        // Streak info
                        _buildStreakCard(responsive),
                        SizedBox(
                          height: responsive.spacing(mobile: 24, tablet: 32),
                        ),

                        // Menu items
                        _buildMenuSection(responsive),
                        SizedBox(
                          height: responsive.spacing(mobile: 40, tablet: 60),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ResponsiveHelper responsive) {
    return Column(
      children: [
        // Profile image
        Stack(
          children: [
            Container(
              width: responsive.spacing(mobile: 120, tablet: 150),
              height: responsive.spacing(mobile: 120, tablet: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
                border: Border.all(
                  color: AppColors.primary.withAlpha(76),
                  width: 3,
                ),
              ),
              child: _isUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ClipOval(
                      child: _profile?.photoUrl != null
                          ? Image.network(
                              _profile!.photoUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: responsive.spacing(
                                    mobile: 60,
                                    tablet: 75,
                                  ),
                                  color: AppColors.primary,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              size: responsive.spacing(mobile: 60, tablet: 75),
                              color: AppColors.primary,
                            ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: EdgeInsets.all(
                    responsive.spacing(mobile: 8, tablet: 10),
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: responsive.spacing(mobile: 20, tablet: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),

        // Name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _profile?.displayName ?? 'User',
              style: TextStyle(
                fontSize: responsive.fontSize(mobile: 24, tablet: 28),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: responsive.spacing(mobile: 20, tablet: 24),
                color: AppColors.primary,
              ),
              onPressed: _editDisplayName,
            ),
          ],
        ),

        // Email
        Text(
          _profile?.email ?? '',
          style: TextStyle(
            fontSize: responsive.fontSize(mobile: 14, tablet: 16),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(ResponsiveHelper responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(mobile: 20, tablet: 24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withAlpha(76),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: responsive.spacing(mobile: 48, tablet: 60),
            color: Colors.white,
          ),
          SizedBox(width: responsive.spacing(mobile: 16, tablet: 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: TextStyle(
                    fontSize: responsive.fontSize(mobile: 14, tablet: 16),
                    color: Colors.white.withAlpha(204),
                  ),
                ),
                SizedBox(height: responsive.spacing(mobile: 4)),
                Text(
                  '${_streakData?.currentStreak ?? 0} days',
                  style: TextStyle(
                    fontSize: responsive.fontSize(mobile: 28, tablet: 32),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Best',
                style: TextStyle(
                  fontSize: responsive.fontSize(mobile: 12, tablet: 14),
                  color: Colors.white.withAlpha(204),
                ),
              ),
              Text(
                '${_streakData?.longestStreak ?? 0}',
                style: TextStyle(
                  fontSize: responsive.fontSize(mobile: 20, tablet: 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(ResponsiveHelper responsive) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Statistics',
            subtitle: 'View your productivity stats',
            onTap: () => Navigator.pushNamed(context, '/statistics'),
            responsive: responsive,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {
              // TODO: Implement notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            responsive: responsive,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              // TODO: Implement help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            responsive: responsive,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _logout,
            responsive: responsive,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ResponsiveHelper responsive,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(mobile: 16, tablet: 20)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.spacing(mobile: 10, tablet: 12),
              ),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : AppColors.primary)
                    .withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: responsive.spacing(mobile: 24, tablet: 28),
              ),
            ),
            SizedBox(width: responsive.spacing(mobile: 16, tablet: 20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: responsive.fontSize(mobile: 16, tablet: 18),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(mobile: 2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.fontSize(mobile: 13, tablet: 14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: responsive.spacing(mobile: 24, tablet: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 72, endIndent: 16);
  }
}
