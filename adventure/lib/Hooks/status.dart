import 'package:flutter/material.dart';
import '../Components/task_item.dart';

IconData getIconForStatus(TaskStatus status) {
  switch (status) {
    case TaskStatus.Request:
      return Icons.question_answer;
    case TaskStatus.Complete:
      return Icons.check;
    case TaskStatus.Incomplete:
      return Icons.warning;
  }
}

Color getColorForStatus(TaskStatus status) {
  switch (status) {
    case TaskStatus.Request:
      return Colors.blue;
    case TaskStatus.Complete:
      return Colors.green;
    case TaskStatus.Incomplete:
      return Colors.red;
  }
}

String getStatusText(TaskStatus status) {
  switch (status) {
    case TaskStatus.Request:
      return 'Request';
    case TaskStatus.Complete:
      return 'Complete';
    case TaskStatus.Incomplete:
      return 'Incomplete';
  }
}
