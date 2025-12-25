import 'package:flutter/material.dart';
import 'package:quizapp/Service/role_service.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final RoleService _roleService = RoleService();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final loadedUsers = await _roleService.getAllUsersWithRoles();
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        showSnackBar(context, 'Kullanıcılar yüklenirken hata: $e');
      }
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
          '$userName kullanıcısını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _roleService.deleteUser(userId);
        if (mounted) {
          showSnackBar(context, 'Kullanıcı başarıyla silindi');
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Kullanıcı silinirken hata: $e');
        }
      }
    }
  }

  Future<void> _changeUserRole(
    String userId,
    String userName,
    UserRoleType currentRole,
  ) async {
    final selectedRole = await showDialog<UserRoleType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('$userName için rol seçin'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, UserRoleType.user),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Kullanıcı'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, UserRoleType.teacher),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Öğretmen'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, UserRoleType.admin),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Admin'),
            ),
          ),
        ],
      ),
    );

    if (selectedRole != null && selectedRole != currentRole) {
      try {
        await _roleService.updateUserRole(userId, selectedRole);
        if (mounted) {
          showSnackBar(context, 'Rol başarıyla güncellendi');
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Rol güncellenirken hata: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('Kullanıcı bulunamadı'))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final role = user['role'] as UserRoleType;

                  Color roleColor;
                  IconData roleIcon;
                  String roleText;

                  switch (role) {
                    case UserRoleType.admin:
                      roleColor = Colors.purple;
                      roleIcon = Icons.admin_panel_settings;
                      roleText = 'Admin';
                      break;
                    case UserRoleType.teacher:
                      roleColor = Colors.orange;
                      roleIcon = Icons.school;
                      roleText = 'Öğretmen';
                      break;
                    case UserRoleType.user:
                    default:
                      roleColor = Colors.blue;
                      roleIcon = Icons.person;
                      roleText = 'Kullanıcı';
                      break;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor,
                        child: Icon(roleIcon, color: Colors.white),
                      ),
                      title: Text(
                        user['name'] ?? 'İsimsiz',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              roleText,
                              style: TextStyle(
                                fontSize: 12,
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: role == UserRoleType.admin
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteUser(user['userId'], user['name']);
                                } else if (value == 'role') {
                                  _changeUserRole(
                                    user['userId'],
                                    user['name'],
                                    role,
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'role',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Rolü Değiştir'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Sil'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
