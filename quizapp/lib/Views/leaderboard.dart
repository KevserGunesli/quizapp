import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});
  Stream<List<Map<String, dynamic>>> getLeaderboardStream() {
    return FirebaseFirestore.instance
        .collection('userData')
        .orderBy('score', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: getLeaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return Center(child: Text("No users found"));
          }
          final topThree = users.take(3).toList();
          final remainingUser = users.skip(3).toList();
          return Column(
            children: [
              SizedBox(
                height: 420,
                child: Stack(
                  children: [
                    Image.asset(
                      "assets/leaderboard.jpg",
                      width: double.maxFinite,
                      height: 420,
                      fit: BoxFit.contain,
                    ),
                    const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          "Leaderboard",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (topThree.isNotEmpty)
                      Positioned(
                        top: 45,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _buildTopUser(topThree[0], 1, context),
                        ),
                      ),
                    if (topThree.length >= 2)
                      Positioned(
                        top: 80,
                        left: 15,
                        child: _buildTopUser(topThree[1], 2, context),
                      ),
                    if (topThree.length >= 3)
                      Positioned(
                        top: 95,
                        right: 15,
                        child: _buildTopUser(topThree[2], 3, context),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: remainingUser.length,
                  itemBuilder: (context, index) {
                    final user = remainingUser[index];
                    final rank = index + 4;
                    return _buildRemainingUser(user, rank);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopUser(
    Map<String, dynamic> user,
    int rank,
    BuildContext context,
  ) {
    return SizedBox(
      width: rank == 1 ? 120 : 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 35 : 28,
            backgroundImage: user['photoBase64'] != null
                ? MemoryImage(base64Decode(user['photoBase64']))
                : null,
            child: user['photoBase64'] == null
                ? Icon(Icons.person, size: rank == 1 ? 30 : 24)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            user['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rank == 1 ? 18 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("👍", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  "${user['score'] * 102}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingUser(Map<String, dynamic> user, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 25,
            backgroundImage: user['photoBase64'] != null
                ? MemoryImage(base64Decode(user['photoBase64']))
                : null,
            child: user['photoBase64'] == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user['name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text("👍", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  "${user['score'] * 102}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
