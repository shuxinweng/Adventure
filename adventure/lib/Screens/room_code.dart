import 'package:flutter/material.dart';
import '../Components/navbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'all_tasks.dart';

class RoomCodePage extends StatefulWidget {
  static const routeName = '/room';
  @override
  _RoomCodePageState createState() => _RoomCodePageState();
}

class _RoomCodePageState extends State<RoomCodePage> {
  List<String> roomCodes = []; // This will hold your room codes
  List<RoomItem> rooms = [];

  @override
  void initState() {
    super.initState();
    loadRoomCodes(); // Call a separate async function to load the room codes
  }

  // Separate async function to load the room codes
  Future<void> loadRoomCodes() async {
    try {
      roomCodes = await fetchData();
      List<RoomItem> updatedRooms = [];
      String room_id = roomCodes[0];
      List<dynamic> parsedList = jsonDecode(room_id.trim());
      for (dynamic i in parsedList) {
        updatedRooms.add(RoomItem(i.toString(), Icons.delete));
      }
      setState(() {
        rooms = updatedRooms;
      });
      roomCodeController.clear();
    } catch (e) {
      print('Failed to fetch room codes: $e');
    }
  }

  void joinRoom() {
    handleUpdateRoomUsers(int.parse(roomCodeController.text),
        [getCurrentUserEmail().toString()]).then((_) {
      return updateUserRoomAndTasks(getCurrentUserEmail().toString(),
          int.parse(roomCodeController.text), null);
    }).then((_) {
      return loadRoomCodes();
    }).catchError((error) {
      print('Error joining room: $error');
    });
  }

  Future<void> createNewRoom() async {
    try {
      await submitNewRoomData(
          [getCurrentUserEmail().toString()], [], roomCodes);
      await loadRoomCodes();
    } catch (e) {
      print('Error creating new room: $e');
    }
  }

  Future<void> deleteRoom(int index) async {
    try {
      await handleRemoveUserFromRoom(
          rooms[index].roomName, getCurrentUserEmail().toString());
      await handleRemoveRoomFromUser(
          getCurrentUserEmail().toString(), int.parse(rooms[index].roomName));
      await loadRoomCodes();
    } catch (e) {
      print('Error deleting room: $e');
    }
  }

  TextEditingController roomNameController = TextEditingController();
  TextEditingController roomCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            height: 70,
            child: Center(
              child: Text(
                'Room Code Page',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: rooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No room is added, please create a room or join one',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 200,
                          child: TextField(
                            controller: roomCodeController,
                            decoration: InputDecoration(
                              hintText: 'Room Code',
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            joinRoom();
                          },
                          child: Text('Join Room'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            createNewRoom();
                          },
                          child: Text('Create New Room'),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AllTasksPage(roomid: rooms[index].roomName),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.lightBlue,
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text('Room: ${rooms[index].roomName}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(rooms[index].deleteIcon),
                                  onPressed: () async {
                                    await deleteRoom(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        currentIndex: 1,
        onTap: (index) {},
        routes: [
          '/',
          '/room',
          '/all-tasks',
          '/settings',
        ],
      ),
      floatingActionButton: rooms.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                createRoomForm(context);
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void createRoom(String roomname) async {
    String? userEmail = getCurrentUserEmail(); // Fetch the current user's email
    if (userEmail != null) {
      try {
        // First, submit new room data and await the response
        final response = await insertRoomData([userEmail], []);
        if (response.statusCode == 200) {
          final roomData = jsonDecode(response.body);
          print(roomData['insertId']);
          setState(() {
            rooms.add(RoomItem(roomname, Icons.delete));
          });
          print('Room data added: ${response.body}');
        } else {
          print('Failed to add room data. Status code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error adding room data: $error');
      }
    } else {
      print('Email is null or room name is empty');
    }

    roomCodeController.clear();
  }

  void createRoomForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join a Room'),
          content: TextField(
            controller: roomCodeController,
            decoration: InputDecoration(
              hintText: 'Enter Room Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Join'),
              onPressed: () async {
                joinRoom();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                roomCodeController.clear();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                createNewRoom();
                Navigator.of(context).pop();
              },
              child: Text('Create New Room'),
            )
          ],
        );
      },
    );
  }
}

class RoomItem {
  final String roomName;
  final IconData deleteIcon;

  RoomItem(this.roomName, this.deleteIcon);
}

Future<http.Response> insertRoomData(
  List<String> userEmails,
  List<int> taskList,
) async {
  final response = await http.post(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/roomdata'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'users': userEmails,
      'tasks': taskList,
    }),
  );
  return response;
}

Future<void> submitNewRoomData(
    List<String> userEmails, List<int> taskList, List<String> room) async {
  final response = await insertRoomData(userEmails, taskList);

  if (response.statusCode == 200) {
    // Check the content type of the response
    if (response.headers['content-type']?.contains('application/json') ??
        false) {
      // Parse the response body as JSON
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check for the expected fields in the response
      if (responseData.containsKey('success') &&
          responseData['success'] == true) {
        // Handle the success response
        print('Room data added: ${responseData['message']}');
      } else {
        // Handle unexpected response
        print('Unexpected response format: ${response.body}');
      }
    } else {
      // Handle non-JSON response
      print('Non-JSON response: ${response.body}');
      final match = RegExp(r'insertId":(\d+)').firstMatch(response.body);
      final insertId = match != null ? match.group(1) : null;
      print('Insert ID: $insertId');
      await handleUpdateUserRoomAndTasks(
        getCurrentUserEmail().toString(),
        room: int.tryParse(insertId.toString()),
      );
    }
  } else {
    // Handle HTTP error status
    throw Exception(
        'Failed to add room data. Status code: ${response.statusCode}');
  }
}

String? getCurrentUserEmail() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return user.email;
  } else {
    return null;
  }
}

Future<List<String>> fetchData() async {
  String? email = getCurrentUserEmail();
  final response = await http.get(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/userdata'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    List<String> roomCodes = [];
    for (var user in data) {
      if (user['username'] == email) {
        // Here's where you use the snippet
        String? roomCode = user['room_code'];
        if (roomCode != null) {
          roomCodes.add(roomCode);
        } else {}
      }
    }
    return roomCodes;
  } else {
    throw Exception('Failed to load data: ${response.statusCode}');
  }
}

Future<http.Response> updateUserRoomAndTasks(
    String username, int? room, int? tasks) async {
  final Map<String, dynamic> bodyData = {};
  if (room != null) bodyData['room_code'] = room;
  if (tasks != null) bodyData['tasks'] = tasks;

  final response = await http.put(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/updateUser/$username'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(bodyData),
  );
  return response;
}

Future<void> handleUpdateUserRoomAndTasks(
  String username, {
  int? room,
  int? tasks,
}) async {
  try {
    final response = await updateUserRoomAndTasks(username, room, tasks);
    if (response.statusCode == 200) {
      print('User room and tasks updated successfully.');
    } else {
      print(
          'Failed to update user room and tasks. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating user room and tasks: $e');
  }
}

// Update the list of users inside the room
Future<http.Response> updateRoomUsers(int roomId, List<String> users) async {
  final response = await http.put(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/updateRoomUsers/$roomId/users'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({'users': users}),
  );
  return response;
}

Future<void> handleUpdateRoomUsers(int roomId, List<String> users) async {
  try {
    await updateRoomUsers(roomId, users).then((response) {
      if (response.statusCode == 200) {
        print('Room users updated successfully.');
      } else {
        print(
            'Failed to update room users. Status code: ${response.statusCode}');
      }
    });
  } catch (e) {
    print('Error updating room users: $e');
  }
}

// Function to remove the current user from a room by room ID
Future<http.Response> removeUserFromRoom(String roomId, String userId) async {
  final response = await http.patch(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/roomdata/$roomId/users/$userId'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  return response;
}

Future<void> handleRemoveUserFromRoom(String roomId, String userId) async {
  try {
    await removeUserFromRoom(roomId, userId).then((response) {
      if (response.statusCode == 200) {
        print('User $userId removed from room $roomId successfully.');
      } else {
        print(
            'Failed to remove user $userId from room $roomId. Status code: ${response.statusCode}');
      }
    });
  } catch (e) {
    print('Error removing user $userId from room $roomId: $e');
  }
}

//function to remove a room from user data
Future<http.Response> removeRoomFromUser(String username, int roomId) async {
  final url = Uri.parse(
      'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/users/$username/removeRoom');

  final response = await http.patch(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({'roomId': roomId}),
  );

  return response;
}

Future<void> handleRemoveRoomFromUser(String username, int roomId) async {
  try {
    await removeRoomFromUser(username, roomId).then((response) {
      if (response.statusCode == 200) {
        print('Room $roomId removed from user $username successfully.');
      } else {
        print(
            'Failed to remove room $roomId from user $username. Status code: ${response.statusCode}');
      }
    });
  } catch (e) {
    print('Error removing room $roomId from user $username: $e');
  }
}
