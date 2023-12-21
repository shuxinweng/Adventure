import 'package:flutter/material.dart';

enum TaskStatus {
  Request,
  Complete,
  Incomplete,
}

class TaskItem {
  int? taskId;
  String task;
  String room;
  IconData deleteIcon;
  TaskStatus status;
  late DateTime timestamp;
  DateTime? dueDate;
  String? assignedUser;

  TaskItem(this.taskId, this.task, this.room, this.deleteIcon, this.status,
      {this.dueDate, this.assignedUser}) {
    timestamp = DateTime.now();
  }
}
