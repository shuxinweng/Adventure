import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './Components/navbar.dart';
import './Components/task_item.dart';
import './Screens/single_task.dart';
import './Hooks/status.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../Hooks/status.dart';

class HomeScreen extends StatefulWidget {
  final String? roomid;

  HomeScreen({
    this.roomid,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  List<int> taskslist = [];
  List<TaskItem> tasks = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchTasksByUserId(getCurrentUserEmail().toString());
    });
  }

  Future<void> fetchTasksByUserId(String username) async {
    try {
      final response = await http.get(Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/userdata/$username',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        print(dataMap['tasks']);

        List<dynamic> parsedList = json.decode(dataMap['tasks']);
        print(parsedList);

        // Clear taskslist before populating it
        taskslist.clear();

        // Clear tasks list before adding new tasks
        tasks.clear();

        // Iterate through the inner lists and add the values to taskslist
        for (dynamic i in parsedList) {
          taskslist.add(i as int);
        }

        // Call setState to trigger a rebuild with the updated taskslist

        for (int i in taskslist) {
          try {
            Map<String, dynamic> taskData = await handleFetchTaskDataById(i);
            print(taskData['id']);
            DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ")
                .parse(taskData['due_date']);
            TaskStatus cur = TaskStatus.Request;
            String Status = taskData['status'];
            print(taskData['task_holder']);
            if (Status == "Created" && taskData['task_holder'] == null) {
              cur = TaskStatus.Request;
            } else if (Status == "In Progress") {
              cur = TaskStatus.Incomplete;
            } else if (Status == "Completed") {
              cur = TaskStatus.Complete;
            }
            tasks.add(TaskItem(taskData['id'], taskData['description'],
                widget.roomid.toString(), Icons.delete, cur,
                dueDate: dateTime, assignedUser: taskData['task_holder']));
          } catch (error) {
            print(
                'Error fetching and initializing data for task ID $i: $error');
          }
        }
        setState(() {});
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during fetchTasksByRoomId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    // Use await to wait for the SingleTaskPage to pop
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleTaskPage(
                          taskItem: tasks[index],
                        ),
                      ),
                    );

                    // Fetch updated data when you navigate back
                    fetchTasksByUserId(getCurrentUserEmail().toString());
                  },
                  child: Container(
                    color: Colors.yellow,
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: Icon(
                        getIconForStatus(tasks[index].status),
                        color: getColorForStatus(tasks[index].status),
                      ),
                      title: Text('Task ${index + 1}: ${tasks[index].task}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(tasks[index].deleteIcon),
                            onPressed: () {
                              submitNewTaskData(
                                  tasks[index].taskId ?? 0, 'Created', '');
                              deleteUserTask(getCurrentUserEmail().toString(),
                                  tasks[index].taskId ?? 0);
                              deleteTask(index);
                              print(tasks[index].status);
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
        currentIndex: 2,
        onTap: (index) {},
        routes: [
          '/',
          '/room',
          '/all-tasks',
          '/settings',
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  String? getCurrentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.email;
    } else {
      return null;
    }
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  // Function to fetch task data for a specific user by username
  Future<http.Response> fetchTaskData(String username) async {
    final response = await http.get(
      Uri.parse(
          'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/userdata/$username'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return response;
  }

  void handleFetchUserTaskData(String username) async {
    try {
      final response = await fetchTaskData(username);
      if (response.statusCode == 200) {
        Map<String, dynamic> userData = jsonDecode(response.body);
        List<dynamic> tasks = userData['tasks'] ??
            []; // Use a null-aware operator to handle cases where 'tasks' is null
        print('Tasks for user $username fetched successfully: $tasks');
      } else {
        print(
            'Failed to fetch tasks for user $username. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks for user $username: $e');
    }
  }
}

Future<Map<String, dynamic>> fetchTaskDataById(int taskId) async {
  final response = await http.get(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/taskdata/$taskId'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
        'Failed to fetch task data. Status code: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> handleFetchTaskDataById(int taskId) async {
  try {
    final taskData = await fetchTaskDataById(taskId);
    return taskData; // Here, you can update your UI or state with the fetched task data
  } catch (e) {
    print('Error fetching task data: $e');
    // Handle the error, perhaps by showing a message to the user
  }
  return {};
}

Future<http.Response> deleteTask(String taskId) async {
  final url = Uri.parse(
      'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/taskdata/$taskId');

  final response = await http.delete(url);

  return response;
}

void handleDeleteTask(String taskId) async {
  try {
    final response = await deleteTask(taskId);
    if (response.statusCode == 200) {
      print('Task $taskId deleted successfully.');
    } else {
      print(
          'Failed to delete task $taskId. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error deleting task $taskId: $e');
  }
}

Future<http.Response> deleteTaskFromRoom(String roomId, String taskId) async {
  final url = Uri.parse(
      'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/roomdata/$roomId/taskdata/$taskId');
  final response = await http.delete(url);
  return response;
}

void handleDeleteTaskFromRoom(String roomId, String taskId) async {
  try {
    final response = await deleteTaskFromRoom(roomId, taskId);
    if (response.statusCode == 200) {
      print('Task $taskId from room $roomId deleted successfully.');
      // Here you can also update your UI accordingly
    } else {
      // This would mean deletion didn't succeed, handle it accordingly
      print(
          'Failed to delete task $taskId from room $roomId. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error deleting task $taskId from room $roomId: $e');
  }
}

Future<http.Response> updateTaskStatus(
    int taskId, String status, String taskholder) async {
  final response = await http.put(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/updateTaskStatus/$taskId'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, dynamic>{'status': status, 'task_holder': taskholder}),
  );
  return response;
}

void submitNewTaskData(int taskId, String status, String taskholder) {
  updateTaskStatus(taskId, status, taskholder).then((response) {
    if (response.statusCode == 200) {
      print('Room data added: ${response.body}');
    } else {
      throw Exception(
          'Failed to add room data. Status code: ${response.statusCode}');
    }
  }).catchError((error) {
    print('Error adding room data: $error');
  });
}

Future<http.Response> deleteUserTask(String username, int taskId) async {
  final response = await http.delete(
    Uri.parse(
      'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/removeUserTask/$username/$taskId',
    ),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  return response;
}
