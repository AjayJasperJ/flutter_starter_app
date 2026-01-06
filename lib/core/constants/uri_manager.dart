class UriManager {
  static const String login = "/auth/login";
  static const String resetFirstLogin = "/auth/reset-first-login";
  static const String profile = "/auth/profile";
  static const String changePassword = "/auth/change-password";
  static const String schoolConfig = '/auth/school-settings-basic';
  static const String schooldataConfiglist = '/auth/school-data-config/list';
  static const String logout = "/auth/logout";
  static const String refreshToken = "/auth/refresh-token";

  //teacher
  static const String teacherSchedules = '/teacher-schedules';
  static const String teacherTimesheet = '/teacher-timesheet';
  static const String teacherLeaveCalendar = '/teacher-leave-calendar';
  static const String teacherAssignments = '/teacher-class-subjects/teacher';
  static const String studentAttendance = '/student-attendance';
  static const String student = '/students';
  static const String recentAttendance = '/teacher-recent-attendance';
  static const String timesheetReports = '/teacher-attendance-report';
  static const String workManagement = '/work-management';
}
