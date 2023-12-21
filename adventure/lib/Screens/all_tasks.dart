import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Components/navbar.dart';
import '../Components/task_item.dart';
import './single_task.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Hooks/status.dart';
import './add_task.dart';
import "./room_code.dart";

class AllTasksPage extends StatefulWidget {
  final String? roomid;

  AllTasksPage({
    this.roomid,
  });

  static const routeName = '/all-tasks';

  @override
  _AllTasksPageState createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> {
  List<int> taskslist = [];
  List<TaskItem> tasks = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchTasksByRoomId(int.parse(widget.roomid.toString()));
    });
  }

  Future<void> fetchTasksByRoomId(int roomId, {Function? callback}) async {
    try {
      final response = await http.get(Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/roomdata/$roomId',
      ));

      print("function used");

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        List<dynamic> parsedList = json.decode(dataMap['tasks']);
        taskslist.clear();

        for (List<dynamic> innerList in parsedList) {
          if (innerList.isNotEmpty && innerList.first is int) {
            taskslist.add(innerList.first);
          }
        }

        tasks.clear();
        for (int i in taskslist) {
          try {
            Map<String, dynamic> taskData = await handleFetchTaskDataById(i);
            DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ")
                .parse(taskData['due_date']);
            TaskStatus cur = TaskStatus.Request;
            String Status = taskData['status'];

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

        if (callback != null) {
          await callback();
        }
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.roomid ?? "No Name",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleTaskPage(
                          taskItem: tasks[index],
                        ),
                      ),
                    );

                    await fetchTasksByRoomId(
                      int.parse(widget.roomid.toString()),
                      callback: () async {
                        await fetchTasksByRoomId(
                            int.parse(widget.roomid.toString()));
                      },
                    );
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
                              handleDeleteTask(tasks[index].taskId.toString());
                              handleDeleteTaskFromRoom(widget.roomid.toString(),
                                  tasks[index].taskId.toString());
                              deleteTask(index);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddTaskPage and wait for the result
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddTaskPage(
                  tasks: tasks,
                  addTaskCallback: (TaskItem newTask) {
                    setState(() {
                      tasks.add(newTask);
                    });
                  },
                  roomid: widget.roomid),
            ),
          );

          // Check if the result is not null and refresh tasks
          if (result != null && result == true) {
            await fetchTasksByRoomId(
              int.parse(widget.roomid.toString()),
              callback: () async {
                await fetchTasksByRoomId(int.parse(widget.roomid.toString()));
              },
            );
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
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

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
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
    return taskData;
  } catch (e) {
    print('Error fetching task data: $e');
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
    } else {
      print(
          'Failed to delete task $taskId from room $roomId. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error deleting task $taskId from room $roomId: $e');
  }
}
