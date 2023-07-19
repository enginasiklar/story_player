import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';


class Story {
  final String id;
  final String userId;
  final String url;
  final String mediaType;
  int? duration;

  Story({
    required this.id,
    required this.userId,
    required this.url,
    required this.mediaType,
    this.duration,
  });

  factory Story.fromDocument(DocumentSnapshot doc) {
    return Story(
      id: doc['id'],
      userId: doc['userID'],
      url: doc['url'],
      mediaType: doc['mediatype'],
    );
  }

  Future<void> setDuration() async {
    if (mediaType != '2') {
      return;
    }

    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

    await videoPlayerController.initialize();

    // Updating story duration
    duration = videoPlayerController.value.duration.inSeconds;

    await videoPlayerController.dispose();
  }
}

class StoryData {
  final _storiesCollection = FirebaseFirestore.instance.collection('stories');

  Future<List<Story>> getStoriesForUser(String userId) async {
    final storiesSnapshot = await _storiesCollection.where('userID', isEqualTo: userId).get();

    var stories = storiesSnapshot.docs
        .map((doc) => Story.fromDocument(doc))
        .toList();

    for (var story in stories) {
      await story.setDuration();
    }

    return stories;
  }
}

Future<void> addStoryToFirestore(String userId, String url, String mediaType) async {
  var docRef = FirebaseFirestore.instance.collection('stories').doc(); // Automatically generate id
  await docRef.set({
    'id': docRef.id,
    'userID': userId,
    'url': url,
    'mediatype': mediaType,
  });
}