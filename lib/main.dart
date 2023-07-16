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
  int _currentUserIndex = 0;

  Story get currentStory => stories[_currentIndex.value];

  void fetchStories(String userId) async {
    _currentUserIndex = userController.users.indexWhere((user) => user.id == userId);
    StoryData storyData = StoryData();
    stories.value = await storyData.getStoriesForUser(userId);
    _currentIndex.value = 0;  // reset to first story when fetching new stories
    update();
  }

  void nextStory() {
    if (_currentIndex.value < stories.length - 1) {
      _currentIndex.value += 1;
      update();
    } else {
      // If there are more users
      if (_currentUserIndex < userController.users.length - 1) {
        _currentUserIndex++;
        fetchStories(userController.users[_currentUserIndex].id);
      } else {
        // If there are no more users, navigate back to user screen
        Get.back();
      }
    }
  }

  void prevStory() {
    if (_currentIndex.value > 0) {
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
              title: Text('Story Screen'),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: List.generate(
                      storyController.stories.length,
                          (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Container(
              child: Center(
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
          ),
        );
      },
    );
  }
}

