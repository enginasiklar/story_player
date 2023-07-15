import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String profileImageUrl;

  const User({
    required this.id,
    required this.name,
    required this.profileImageUrl,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      name: doc['name'],
      profileImageUrl: doc['profileUrl'],
    );
  }
}

class UserData {
  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<List<User>> getAllUsers() async {
    final usersSnapshot = await _usersCollection.get();

    return usersSnapshot.docs
        .map((doc) => User.fromDocument(doc))
        .toList();
  }

  Future<User> getUser(String userId) async {
    final userDoc = await _usersCollection.doc(userId).get();

    return User.fromDocument(userDoc);
  }
}
