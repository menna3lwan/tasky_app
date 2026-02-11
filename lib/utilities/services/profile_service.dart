import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// User profile model
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }
}

/// Service for managing user profiles
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get user profile document reference
  DocumentReference<Map<String, dynamic>> get _profileDoc {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId);
  }

  /// Get current user profile
  Future<UserProfile?> getProfile() async {
    if (_userId == null) return null;

    try {
      final doc = await _profileDoc.get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }

      // Create profile from Firebase Auth if doesn't exist
      final user = _auth.currentUser;
      if (user != null) {
        final profile = UserProfile.fromFirebaseUser(user);
        await _profileDoc.set(profile.toFirestore());
        return profile;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get profile stream for real-time updates
  Stream<UserProfile?> getProfileStream() {
    if (_userId == null) return Stream.value(null);

    return _profileDoc.snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update profile display name
  Future<ProfileResult> updateDisplayName(String displayName) async {
    if (_userId == null) {
      return ProfileResult.failure('User not logged in');
    }

    try {
      await _profileDoc.update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(displayName);

      return ProfileResult.success();
    } catch (e) {
      return ProfileResult.failure('Failed to update name: ${e.toString()}');
    }
  }

  /// Upload profile image and update profile
  Future<ProfileResult> uploadProfileImage(File imageFile) async {
    if (_userId == null) {
      return ProfileResult.failure('User not logged in');
    }

    try {
      // Create storage reference
      final ref = _storage.ref().child('profile_images/$_userId.jpg');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore profile
      await _profileDoc.update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth photo URL
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      return ProfileResult.success(photoUrl: downloadUrl);
    } catch (e) {
      return ProfileResult.failure('Failed to upload image: ${e.toString()}');
    }
  }

  /// Delete profile image
  Future<ProfileResult> deleteProfileImage() async {
    if (_userId == null) {
      return ProfileResult.failure('User not logged in');
    }

    try {
      // Delete from storage
      final ref = _storage.ref().child('profile_images/$_userId.jpg');
      try {
        await ref.delete();
      } catch (_) {
        // Image might not exist, continue anyway
      }

      // Update Firestore profile
      await _profileDoc.update({
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth
      await _auth.currentUser?.updatePhotoURL(null);

      return ProfileResult.success();
    } catch (e) {
      return ProfileResult.failure('Failed to delete image: ${e.toString()}');
    }
  }

  /// Update full profile
  Future<ProfileResult> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_userId == null) {
      return ProfileResult.failure('User not logged in');
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        await _auth.currentUser?.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }

      await _profileDoc.update(updates);

      return ProfileResult.success();
    } catch (e) {
      return ProfileResult.failure('Failed to update profile: ${e.toString()}');
    }
  }
}

/// Result class for profile operations
class ProfileResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? photoUrl;

  ProfileResult._({
    required this.isSuccess,
    this.errorMessage,
    this.photoUrl,
  });

  factory ProfileResult.success({String? photoUrl}) {
    return ProfileResult._(isSuccess: true, photoUrl: photoUrl);
  }

  factory ProfileResult.failure(String message) {
    return ProfileResult._(isSuccess: false, errorMessage: message);
  }
}
