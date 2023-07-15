import 'package:cloud_firestore/cloud_firestore.dart';


class Story {
  final String id;
  final String userId;
  final String url;
  final String mediaType;

  const Story({
    required this.id,
    required this.userId,
    required this.url,
    required this.mediaType,
  });

  factory Story.fromDocument(DocumentSnapshot doc) {
    return Story(
      id: doc['id'],
      userId: doc['userID'],
      url: doc['url'],
      mediaType: doc['mediatype'],
    );
  }

}

class StoryData {
  final _storiesCollection = FirebaseFirestore.instance.collection('stories');

  Future<List<Story>> getStoriesForUser(String userId) async {
    final storiesSnapshot = await _storiesCollection.where('userID', isEqualTo: userId).get();

    return storiesSnapshot.docs
        .map((doc) => Story.fromDocument(doc))
        .toList();
  }
}
