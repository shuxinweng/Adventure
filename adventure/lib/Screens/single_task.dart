import 'package:flutter/material.dart';
import '../Components/task_item.dart';
import '../Hooks/status.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingleTaskPage extends StatefulWidget {
  final TaskItem taskItem;

  SingleTaskPage({required this.taskItem});

  @override
  _SingleTaskPageState createState() => _SingleTaskPageState();
}

class _SingleTaskPageState extends State<SingleTaskPage> {
  late TaskStatus currentStatus;
  String? assignedUser;
  int? taskid;
  bool isTaskCompleted = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.taskItem.status;
    assignedUser = widget.taskItem.assignedUser;
    taskid = widget.taskItem.taskId;
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    IconData statusIcon = getIconForStatus(currentStatus);
    Color statusColor = getColorForStatus(currentStatus);

    if (isTaskCompleted) {
      statusIcon = Icons.check;
      statusColor = Colors.green;
    }

    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.taskItem.timestamp);

    User? currentUser = getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskItem.task),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 48,
            ),
            Text(widget.taskItem.task),
            SizedBox(height: 10),
            Text(
              isTaskCompleted ? 'Completed' : getStatusText(currentStatus),
              style: TextStyle(
                color: isTaskCompleted
                    ? Colors.green
                    : getColorForStatus(currentStatus),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Updated Time: $formattedDate',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              'Due Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.taskItem.dueDate ?? DateTime.now())}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            (currentStatus == TaskStatus.Request
                ? ElevatedButton(
                    onPressed: () => assignTask(context),
                    child: Text('Accept Task'),
                  )
                : Container()),
            if (currentUser?.email == assignedUser && !isTaskCompleted)
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isTaskCompleted = true;
                  });

                  print(taskid);
                  await submitNewTaskData(
                      taskid ?? 0, "Completed", assignedUser.toString());
                },
                child: Text("Complete Task"),
              ),
            if (isTaskCompleted)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Task Completed',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void assignTask(BuildContext context) async {
    final currentUser = getCurrentUser();
    if (currentUser != null) {
      setState(() {
        assignedUser = currentUser.email ?? 'N/A';
        submitNewTaskData(taskid ?? 0, "In Progress", assignedUser.toString());
        updateUserRoomAndTasks(currentUser.email ?? 'N/A', null, taskid);
      });
      
      Navigator.pop(context);
    } else {
      print('No account!');
    }
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

Future<void> submitNewTaskData(
    int taskId, String status, String taskholder) async {
  try {
    final response = await updateTaskStatus(taskId, status, taskholder);
    if (response.statusCode == 200) {
      print('Room data added: ${response.body}');
    } else {
      throw Exception(
          'Failed to add room data. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error adding room data: $error');
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
