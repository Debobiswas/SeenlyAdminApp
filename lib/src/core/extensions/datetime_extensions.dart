import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String toReadableDateTime() {
    return DateFormat.yMMMd().add_jm().format(toLocal());
  }
}

