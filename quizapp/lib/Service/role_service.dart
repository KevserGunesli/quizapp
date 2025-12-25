import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRoleType {
  user(0),
  admin(1),
  teacher(2);

  final int value;
  const UserRoleType(this.value);

  static UserRoleType fromValue(int value) {
    return UserRoleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRoleType.user,
    );
  }
}

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserRole(
    String userId, {
    UserRoleType role = UserRoleType.user,
  }) async {
    try {
      await _firestore.collection('UserRole').add({
        'userId': userId,
        'role': role.value,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Rol oluşturulurken hata: $e');
    }
  }

  Future<UserRoleType> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRoleType.user;
    return getUserRole(user.uid);
  }

  Future<UserRoleType> getUserRole(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('UserRole')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return UserRoleType.user;
      }

      final roleValue = querySnapshot.docs.first.data()['role'] as int? ?? 0;
      return UserRoleType.fromValue(roleValue);
    } catch (e) {
      return UserRoleType.user;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRoleType.admin;
  }

  Future<bool> isCurrentUserTeacher() async {
    final role = await getCurrentUserRole();
    return role == UserRoleType.teacher;
  }

  Future<void> updateUserRole(String userId, UserRoleType newRole) async {
    try {
      final querySnapshot = await _firestore
          .collection('UserRole')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await createUserRole(userId, role: newRole);
      } else {
        await querySnapshot.docs.first.reference.update({
          'role': newRole.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Rol güncellenirken hata: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsersWithRoles() async {
    try {
      final usersSnapshot = await _firestore.collection('userData').get();

      List<Map<String, dynamic>> usersWithRoles = [];

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        final role = await getUserRole(userId);

        usersWithRoles.add({
          'userId': userId,
          'name': userData['name'] ?? 'İsimsiz',
          'email': userData['email'] ?? '',
          'score': userData['score'] ?? 0,
          'role': role,
        });
      }

      return usersWithRoles;
    } catch (e) {
      throw Exception('Kullanıcılar alınırken hata: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final roleSnapshot = await _firestore
          .collection('UserRole')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in roleSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('userData').doc(userId).delete();
    } catch (e) {
      throw Exception('Kullanıcı silinirken hata: $e');
    }
  }
}
