import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Components/task_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskPage extends StatefulWidget {
  final List<TaskItem> tasks;
  final Function(TaskItem) addTaskCallback;
  final String? roomid;

  AddTaskPage({
    required this.tasks,
    required this.addTaskCallback,
    this.roomid,
  });

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController taskNameController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();
  TaskStatus created = TaskStatus.Request;
  DateTime? selectedDueDate;

  String formattedDueDate() {
    if (selectedDueDate != null) {
      return DateFormat('MMM d, y HH:mm').format(selectedDueDate!);
    }
    return 'Select Due Date';
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDueDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dueDateController.text = formattedDueDate();
        });
      }
    }
  }

  void submitNewTaskData(String post_date, String due_date, String description,
      String post_account_user, String status, int room_number) async {
    try {
      final response = await insertTaskData(post_date, due_date, description,
          post_account_user, status, room_number);

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          if (responseData.containsKey('success') &&
              responseData['success'] == true) {
            print('Room data added: ${responseData['message']}');
          } else {
            print('Unexpected response format: ${response.body}');
          }
        } else {
          print('Non-JSON response: ${response.body}');
          final match = RegExp(r'insertId":(\d+)').firstMatch(response.body);
          final insertId = match != null ? match.group(1) : null;
          print('Insert ID: $insertId');
          int room = int.tryParse(widget.roomid ?? "") ?? 0;
          int tasknumber = int.parse(insertId.toString());
          print(room);
          print(tasknumber);

          await handleUpdateRoomTasks(room, [tasknumber]);
        }
      } else {
        throw Exception(
            'Failed to add room data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error adding room data: $error');
    }
  }

  Future<http.Response> updateRoomTasks(int roomId, List<dynamic> tasks) async {
    final response = await http.put(
      Uri.parse(
          'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/updateRoomTasks/$roomId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tasks': tasks,
      }),
    );
    return response;
  }

  Future<void> handleUpdateRoomTasks(int roomId, List<dynamic> tasks) async {
    try {
      final response = await updateRoomTasks(roomId, tasks);
      if (response.statusCode == 200) {
        print('Room tasks updated successfully.');
      } else {
        print(
            'Failed to update room tasks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating room tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: taskNameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            TextFormField(
              controller: dueDateController,
              decoration: InputDecoration(
                labelText: 'Due Date',
                suffixIcon: IconButton(
                  onPressed: _selectDueDate,
                  icon: Icon(Icons.calendar_today),
                ),
              ),
              readOnly: true,
              onTap: _selectDueDate,
            ),
            ElevatedButton(
              onPressed: () {
                addTask();
                String due_date = dueDateController.text;
                String description = taskNameController.text;

                // Format current date with hours and minutes
                String post_date =
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

                // Use the selectedDueDate if available, otherwise use a default date
                String due_date_formatted = selectedDueDate != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(selectedDueDate!)
                    : '2023-12-10 00:00'; // Replace with your default date or leave it as is

                submitNewTaskData(
                    post_date,
                    due_date_formatted,
                    description,
                    getCurrentUserEmail().toString(),
                    "Created",
                    int.tryParse(widget.roomid ?? "") ?? 0);
              },
              child: Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void addTask() {
    String taskName = taskNameController.text;
    String dueDate = dueDateController.text;

    TaskItem newTask = TaskItem(null, taskName, dueDate, Icons.delete, created,
        dueDate: selectedDueDate);
    widget.addTaskCallback(newTask);

    Navigator.pop(context, true);
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

Future<http.Response> insertTaskData(
    String post_date,
    String due_date,
    String description,
    String post_account_user,
    String status,
    int room_number) async {
  final response = await http.post(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/taskdata'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'post_date': post_date,
      'due_date': due_date,
      'description': description,
      'post_account_user': post_account_user,
      'status': status,
      'room_number': room_number
    }),
  );

  return response;
}
