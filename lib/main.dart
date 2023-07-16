import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'story_model.dart';
import 'user_model.dart';
import 'package:get/get.dart';

class UserController extends GetxController {

  final UserData _userData = UserData();
  RxList<User> users = RxList<User>();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      List<User> fetchedUsers = await _userData.getAllUsers();
      if (fetchedUsers.isNotEmpty) {
        users.addAll(fetchedUsers);
        print('Users fetched successfully: ${users.length}');
      } else {
        print('No users found.');
      }
    } catch (e) {
      print('Failed to fetch users: $e');
    }
  }
}

class StoryController extends GetxController {
  final UserController userController = Get.find<UserController>();
  final stories = <Story>[].obs;
  final _currentIndex = 0.obs;
  List<RxDouble> _progressList = [];  // List to track the progress of each story
  Timer? _timer;
  int _currentUserIndex = 0;

  Story get currentStory => stories[_currentIndex.value];

  @override
  void onInit() {
    ever(_currentIndex, (_) {
      if (_progressList != null && _progressList.isNotEmpty) {
        startTimer();
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startTimer({bool resetProgress = true}) {
    const oneSec = const Duration(seconds: 1);
    int duration = currentStory.mediaType == '1' ? 5 : 10;
    _timer?.cancel();
    if (resetProgress) {
      _progressList[_currentIndex.value].value = 0.0;  // Reset the progress of the current story
    }
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_progressList[_currentIndex.value].value < 1.0) {
        _progressList[_currentIndex.value].value += 1.0 / duration;
      } else {
        timer.cancel();
        nextStory(true);
      }
      update();
    });
  }

  void fetchStories(String userId) async {
    _currentUserIndex = userController.users.indexWhere((user) => user.id == userId);
    StoryData storyData = StoryData();
    var fetchedStories = await storyData.getStoriesForUser(userId); // fetch stories first
    stories.value = fetchedStories; // then assign it to the observable list
    _currentIndex.value = 0;
    _progressList = List.filled(stories.length, 0.0.obs); // Initialize the progress list after stories are fetched
    update();
    startTimer(); // Start timer after fetching new stories
  }

// Update nextStory to allow jumping to the next user manually
  void nextStory([bool fromTimer = false]) {
    if (_currentIndex.value < stories.length - 1) {
      _currentIndex.value += 1;
      startTimer(resetProgress: false);  // Start the timer for the next story without resetting the progress
    } else {
      // If there are more users
      if (_currentUserIndex < userController.users.length - 1) {
        _currentUserIndex++;
        fetchStories(userController.users[_currentUserIndex].id);
      } else if(fromTimer || (_currentUserIndex == userController.users.length - 1)) {
        // If there are no more users or it's the last story of the last user, navigate back to user screen
        Get.back();
      }
    }
  }

  void prevStory() {
    if (_currentIndex.value > 0) {
      _progressList[_currentIndex.value].value = 0.0; // Reset progress of the story we're leaving
      _currentIndex.value -= 1;
      update();
    } else {
      // If there are previous users
      if (_currentUserIndex > 0) {
        _currentUserIndex--;
        fetchStories(userController.users[_currentUserIndex].id);
      } else {
        // If there are no previous users, navigate back to user screen
        Get.back();
      }
    }
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
  UserData userData = UserData();

  Get.put(UserController()); // Add this line
  Get.put(StoryController()); // Add this line

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(  // Use GetMaterialApp instead of MaterialApp
      title: 'Flutter Instagram Stories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
        init: UserController(),
        builder: (userController) {
          return Scaffold(
            appBar: AppBar(title: Text('User Stories')),
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Change this value as needed
              ),
              itemCount: userController.users.length,
              itemBuilder: (context, index) => UserWidget(user: userController.users[index]),
            ),
          );
        }
    );
  }
}

class UserWidget extends StatelessWidget {
  final User user;
  const UserWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Get.put(StoryController()).fetchStories(user.id); // Initialize StoryController and fetch stories
          Get.to(() => StoryScreen());
        },
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(user.profileImageUrl),
            radius: 40.0,
          ),
          Text(user.name),
        ],
      ),
    );
  }
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoryController>(
      builder: (storyController) {
        return GestureDetector(
          onTapUp: (details) {
            var screenWidth = MediaQuery.of(context).size.width;
            if (details.localPosition.dx < screenWidth / 2) {
              storyController.prevStory();
            } else {
              storyController.nextStory();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Story Screen'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: List.generate(
                      storyController.stories.length,
                          (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          height: 4.0,
                          child: Obx( () => LinearProgressIndicator(
                            value: index < storyController._currentIndex.value
                                ? 1.0
                                : index == storyController._currentIndex.value
                                ? storyController._progressList[index].value
                                : 0.0,
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User ID: ${storyController.currentStory.userId}'),
                  Text('Story ID: ${storyController.currentStory.id}'),
                  Text('Media Type: ${storyController.currentStory.mediaType}'),
                  storyController.currentStory.mediaType == '1'
                      ? Image.network(storyController.currentStory.url)
                      : Text('Video/GIF placeholder'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



