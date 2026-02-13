class Attendance {
  final int id;
  final String studentId;
  final String name;
  final String program;
  final String major;
  final String date;
  final String time;
  final String status;

  Attendance({
    required this.id,
    required this.studentId,
    required this.name,
    required this.program,
    required this.major,
    required this.date,
    required this.time,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      name: json['name'],
      program: json['program'],
      major: json['major'],
      date: json['date'],
      time: json['time'],
      status: json['status'],
    );
  }
}
