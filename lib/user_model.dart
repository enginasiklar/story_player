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

Future<void> addUserToFirestore(String name, String profileImageUrl) async {
  var docRef = FirebaseFirestore.instance.collection('users').doc(); // Automatically generate id
  await docRef.set({
    'id': docRef.id,
    'name': name,
    'profileUrl': profileImageUrl.isNotEmpty
        ? profileImageUrl
        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
  });
}


