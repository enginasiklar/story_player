import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cube_transition_plus/cube_transition_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import 'firebase_options.dart';
import 'story_model.dart';
import 'user_model.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);

  Get.put(UserController());
  Get.put(StoryController());
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
            title: const Text('User Stories'),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: (String result) {
                  switch(result) {
                    case 'Create User':
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Create User'),
                            content: SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: ListBody(
                                  children: <Widget>[
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(labelText: 'Name'),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a name';
                                        }
                                        return null;
                                      },
                                    ),
                                    TextFormField(
                                      controller: _urlController,
                                      decoration: const InputDecoration(labelText: 'Profile Image Url'),
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
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Create'),
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
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Create Story'),
                            content: SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: ListBody(
                                  children: <Widget>[
                                    DropdownButtonFormField<String>(
                                      value: _selectedUserId,
                                      hint: const Text("Select User"),
                                      items: userController.allUsers.map((User user) {
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
                                      decoration: const InputDecoration(labelText: 'Story Url'),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a story url';
                                        }
                                        return null;
                                      },
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _mediaTypeController.text.isNotEmpty ? _mediaTypeController.text : null,
                                      hint: const Text("Select Media Type"),
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
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Create'),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    addStoryToFirestore(
                                        _selectedUserId!, _urlController.text, _mediaTypeController.text);
                                    _urlController.clear();
                                    _mediaTypeController.clear();
                                    Navigator.of(context).pop();
                                  }},),],);},);
                      break;}},
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Create User',
                    child: Text('Create User'),                  ),
                  const PopupMenuItem<String>(
                    value: 'Create Story',
                    child: Text('Create Story'),
                  ),                ],              ),            ],          ),
          body: RefreshIndicator(
            onRefresh: () async {
              userController.refreshUsers();
            },
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: userController.users.length,
              itemBuilder: (context, index) => UserWidget(user: userController.users[index]),
            ),),);},);}}

class AuthController extends GetxController {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  bool get isAuthenticated => _user != null;

  auth.User? _user;

  auth.User? get user => _user;

  @override
  void onInit() {
    super.onInit();
    _user = _auth.currentUser;
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = firebaseUser;
      await signInWithGoogle();
    }
    update();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    update();
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final credential = auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;

    // Check if user id already exists in Firestore
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

    if (!userDoc.exists) {
      // If user id not exists, create new user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': user.displayName ?? user.email,
        'profileUrl': user.photoURL ??
            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
      });
    }
  }
}

class UserController extends GetxController {

  final UserData _userData = UserData();
  RxList<User> users = RxList<User>();
  RxList<User> allUsers = RxList<User>();  // List to hold all users


  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchAllUsers();
  }

  void fetchUsers() async {
    try {
      List<User> fetchedUsers = await _userData.getAllUsers();
      StoryData storyData = StoryData();
      List<User> usersWithStories = [];

      for (var user in fetchedUsers) {
        var stories = await storyData.getStoriesForUser(user.id);
        if (stories.isNotEmpty) {
          usersWithStories.add(user);
        }
      }

      if (usersWithStories.isNotEmpty) {
        users.assignAll(usersWithStories);
        print('Users with stories fetched successfully: ${users.length}');
        update();  // force update
      } else {
        print('No users with stories found.');
      }
    } catch (e) {
      print('Failed to fetch users: $e');
    }
  }

  void fetchAllUsers() async {
    try {
      List<User> fetchedUsers = await _userData.getAllUsers();
      if (fetchedUsers.isNotEmpty) {
        allUsers.assignAll(fetchedUsers);
        print('All users fetched successfully: ${allUsers.length}');
        update();  // force update
      } else {
        print('No users found.');
      }
    } catch (e) {
      print('Failed to fetch all users: $e');
    }
  }

  void refreshUsers() {
    users.clear();
    fetchUsers();
  }
}

class UserWidget extends StatelessWidget {
  final User user;
  const UserWidget({Key? key, required this.user}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.put(StoryController()).fetchStories(user.id, context);
        Get.to(() => const StoryScreen(), transition: Transition.noTransition); },
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

class StoryController extends GetxController {
  final UserController userController = Get.find<UserController>();
  final stories = <Story>[].obs;
  final _currentIndex = 0.obs;
  List<RxDouble> _progressList = [];
  Timer? _timer;
  int _currentUserIndex = 0;
  final videoStatusNotifier = ValueNotifier<bool>(true);
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
    int duration = currentStory.duration ?? 5;
    _timer?.cancel();
    if (resetProgress) {
      _progressList[_currentIndex.value].value = 0.0;
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

  void pauseStory() {
    _timer?.cancel();
    videoStatusNotifier.value = false; // Pause video
  }

  void resumeStory() {
    startTimer(resetProgress: false);
    videoStatusNotifier.value = true; // Play video
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

    Navigator.of(context).pushReplacement(
      CubePageRoute(
        enterPage: const StoryScreen(),
        exitPage: const StoryScreen(),
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
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoryController>(
      builder: (storyController) {
        User currentUser = storyController.userController.users[storyController._currentUserIndex];
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(currentUser.profileImageUrl),
                    radius: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(currentUser.name),
                ],
              ),
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
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: PageView.builder(
              controller: PageController(
                initialPage: storyController._currentUserIndex,
              ),
              itemCount: storyController.userController.users.length,
              onPageChanged: (index) {
                storyController.fetchStories(storyController.userController.users[index].id, context);
              },
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: storyController.stories.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : storyController.currentStory.mediaType == '1'
                          ? Image.network(storyController.currentStory.url)
                          : VideoPlayerWidget(url: storyController.currentStory.url),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  VideoPlayerWidget({super.key, required this.url});

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

