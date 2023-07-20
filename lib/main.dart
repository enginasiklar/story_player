import 'dart:async';
import 'package:cube_transition_plus/cube_transition_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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
        users.assignAll(fetchedUsers);
        print('Users fetched successfully: ${users.length}');
        update();  // force update
      } else {
        print('No users found.');
      }
    } catch (e) {
      print('Failed to fetch users: $e');
    }
  }

  void refreshUsers() {
    users.clear();
    fetchUsers();  // Assuming userData.getUsers() fetches the latest users
  }
}

class StoryController extends GetxController {
  final UserController userController = Get.find<UserController>();
  final stories = <Story>[].obs;
  final _currentIndex = 0.obs;
  List<RxDouble> _progressList = [];
  Timer? _timer;
  int _currentUserIndex = 0;
  final videoStatusNotifier = ValueNotifier<bool>(true); // Added ValueNotifier for video status
  final _lastSeenStoryIndex = {}.obs;


  Story get currentStory => stories[_currentIndex.value];

  @override
  void onInit() {
    ever(_currentIndex, (_) {
      if (_progressList.isNotEmpty) {
        startTimer();
      }
    });

    userController.users.isNotEmpty
        ? fetchStories(userController.users[_currentUserIndex].id, Get.context!)
        : null;

    super.onInit();
  }


  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startTimer({bool resetProgress = true}) {
    const oneSec = Duration(seconds: 1);
    int duration = currentStory.duration ?? 5;  // Default duration is 5 seconds for images
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

    // Only initialize and play the video if the media type is video
    if (currentStory.mediaType == '2') {
      initializeVideoPlayer(currentStory.url);
    }
  }

  void initializeVideoPlayer(String url) async {
    final videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );
    await videoPlayerController.initialize();
    videoPlayerController.play();
    videoPlayerController.setLooping(false);
    update();
  }

  void fetchStories(String userId, BuildContext context) async {
    _currentUserIndex = userController.users.indexWhere((user) => user.id == userId);
    StoryData storyData = StoryData();
    var fetchedStories = await storyData.getStoriesForUser(userId);

    fetchedStories.sort((a, b) {
      int durationA = a.duration ?? 5;
      int durationB = b.duration ?? 5;
      return durationB.compareTo(durationA);
    });

    stories.value = fetchedStories;

    if (_lastSeenStoryIndex[userId] != null) {
      _currentIndex.value = _lastSeenStoryIndex[userId];
    } else {
      _currentIndex.value = 0;
    }

    _progressList = List.filled(stories.length, 0.0.obs);

    update();
    startTimer();

    // Use CubePageRoute for navigation
    Navigator.of(context).pushReplacement(
      CubePageRoute(
        enterPage: StoryScreen(),
        exitPage: StoryScreen(),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }


  void nextStory([bool fromTimer = false]) {
    if (_currentIndex.value < stories.length - 1) {
      _currentIndex.value += 1;
      _lastSeenStoryIndex[userController.users[_currentUserIndex].id] = _currentIndex.value;
      startTimer(resetProgress: false);
    } else {
      _lastSeenStoryIndex.remove(userController.users[_currentUserIndex].id);
      if (_currentUserIndex < userController.users.length - 1) {
        _currentUserIndex++;
        fetchStories(userController.users[_currentUserIndex].id, Get.context!);
      } else if(fromTimer || (_currentUserIndex == userController.users.length - 1)) {
        Get.back();
      }
    }
  }

  void prevStory() {
    if (_currentIndex.value > 0) {
      _progressList[_currentIndex.value].value = 0.0;
      _currentIndex.value -= 1;
      _lastSeenStoryIndex[userController.users[_currentUserIndex].id] = _currentIndex.value;
      update();
    } else {
      _lastSeenStoryIndex.remove(userController.users[_currentUserIndex].id);
      if (_currentUserIndex > 0) {
        _currentUserIndex--;
        fetchStories(userController.users[_currentUserIndex].id, Get.context!);
      } else {
        Get.back();
      }
    }
  }


  _VideoPlayerWidgetState? _videoPlayerWidgetState;

  void setVideoPlayerWidgetState(_VideoPlayerWidgetState state) {
    _videoPlayerWidgetState = state;
  }

  void pauseStory() {
    _timer?.cancel();
    videoStatusNotifier.value = false; // Pause video
  }

  void resumeStory() {
    startTimer(resetProgress: false);
    videoStatusNotifier.value = true; // Play video
  }

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);

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
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _mediaTypeController = TextEditingController();
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserController>(
        init: UserController(),
        builder: (userController) {
          return Scaffold(
            appBar: AppBar(
              title: Text('User Stories'),
              actions: <Widget>[
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    switch(result) {
                      case 'Create User':
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Create User'),
                              content: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: ListBody(
                                    children: <Widget>[
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(labelText: 'Name'),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a name';
                                          }
                                          return null;
                                        },
                                      ),
                                      TextFormField(
                                        controller: _urlController,
                                        decoration: InputDecoration(labelText: 'Profile Image Url'),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a profile image url';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Create'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      addUserToFirestore(
                                          _nameController.text, _urlController.text);
                                      _nameController.clear();
                                      _urlController.clear();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        break;
                      case 'Create Story':
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Create Story'),
                              content: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: ListBody(
                                    children: <Widget>[
                                      DropdownButtonFormField<String>(
                                        value: _selectedUserId,
                                        hint: Text("Select User"),
                                        items: userController.users.map((User user) {
                                          return DropdownMenuItem<String>(
                                            value: user.id,
                                            child: Text(user.name),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          _selectedUserId = newValue!;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a user';
                                          }
                                          return null;
                                        },
                                      ),
                                      TextFormField(
                                        controller: _urlController,
                                        decoration: InputDecoration(labelText: 'Story Url'),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a story url';
                                          }
                                          return null;
                                        },
                                      ),
                                      DropdownButtonFormField<String>(
                                        value: _mediaTypeController.text.isNotEmpty ? _mediaTypeController.text : null,
                                        hint: Text("Select Media Type"),
                                        items: <String>['1', '2']
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value == '1' ? 'Image' : 'Video'),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          _mediaTypeController.text = newValue!;
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a media type';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Create'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      addStoryToFirestore(
                                          _selectedUserId!, _urlController.text, _mediaTypeController.text);
                                      _urlController.clear();
                                      _mediaTypeController.clear();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Create User',
                      child: Text('Create User'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Create Story',
                      child: Text('Create Story'),
                    ),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                // Here you call a function that fetches the latest data
                // For example:
                userController.refreshUsers();
              },
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: userController.users.length,
                itemBuilder: (context, index) => UserWidget(user: userController.users[index]),
              ),
            ),
          );
        },
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
        Get.put(StoryController()).fetchStories(user.id, context); // Initialize StoryController and fetch stories
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
          onLongPressStart: (details) {
            storyController.pauseStory(); // Pause the story
          },
          onLongPressEnd: (details) {
            storyController.resumeStory(); // Resume the story
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
                          child: Obx(() => LinearProgressIndicator(
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
                  Expanded(
                    child: storyController.stories.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : storyController.currentStory.mediaType == '1'
                        ? Image.network(storyController.currentStory.url)
                        : StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        VideoPlayerWidget videoPlayerWidget = VideoPlayerWidget(url: storyController.currentStory.url);
                        storyController.setVideoPlayerWidgetState(videoPlayerWidget.createState());
                        return videoPlayerWidget;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  VideoPlayerWidget({required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    // Listen to videoStatusNotifier and play or pause video accordingly
    Get.find<StoryController>().videoStatusNotifier.addListener(() {
      if (Get.find<StoryController>().videoStatusNotifier.value) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : Container();
  }
}

