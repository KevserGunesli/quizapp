import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('ListofQuestions');

  Future<void> _addCategory() async {
    final titleController = TextEditingController();
    final imageUrlController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kategori Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Resim URL (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        await _categoriesCollection.doc(titleController.text).set({
          'title': titleController.text,
          'imageUrl': imageUrlController.text,
          'questions': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          showSnackBar(context, 'Kategori başarıyla eklendi');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Kategori eklenirken hata: $e');
        }
      }
    }
  }

  Future<void> _editCategory(String docId, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: data['title'] ?? docId);
    final imageUrlController = TextEditingController(
      text: data['imageUrl'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Resim URL (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _categoriesCollection.doc(docId).update({
          'title': titleController.text,
          'imageUrl': imageUrlController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          showSnackBar(context, 'Kategori başarıyla güncellendi');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Kategori güncellenirken hata: $e');
        }
      }
    }
  }

  Future<void> _deleteCategory(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '$docId kategorisini ve tüm sorularını silmek istediğinize emin misiniz?',
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
        await _categoriesCollection.doc(docId).delete();
        if (mounted) {
          showSnackBar(context, 'Kategori başarıyla silindi');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Kategori silinirken hata: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _categoriesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Kategori bulunamadı'));
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final doc = categories[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? doc.id;
              final questionCount = (data['questions'] as List?)?.length ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$questionCount soru'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editCategory(doc.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
