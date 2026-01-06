class ProfileResponseModel {
  final String status;
  final String message;
  final ProfileData data;

  const ProfileResponseModel({required this.status, required this.message, required this.data});

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? ProfileData.fromJson(json['data']) : ProfileData.empty,
    );
  }

  Map<String, dynamic> toJson() => {'status': status, 'message': message, 'data': data.toJson()};

  factory ProfileResponseModel.empty() =>
      const ProfileResponseModel(status: '', message: '', data: ProfileData.empty);
}

class ProfileData {
  final String id;
  final String userId;
  final String role;
  final List<String> extraRoles;
  final String email;
  final String phone;
  final String status;
  final String isFirstLogin;
  final String createdAt;
  final String updatedAt;
  final List<String> permissions;
  final String photo;
  final String name;
  final String staffDetails;
  final TeacherDetails teacherDetails;
  final String parentDetails;

  const ProfileData({
    required this.id,
    required this.userId,
    required this.role,
    required this.extraRoles,
    required this.email,
    required this.phone,
    required this.status,
    required this.isFirstLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.permissions,
    required this.photo,
    required this.name,
    required this.staffDetails,
    required this.teacherDetails,
    required this.parentDetails,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      extraRoles: (json['extra_roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isFirstLogin: json['is_first_login']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      photo: json['photo']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      staffDetails: json['staff_details']?.toString() ?? '',
      teacherDetails: json['teacher_details'] != null
          ? TeacherDetails.fromJson(json['teacher_details'])
          : TeacherDetails.empty,
      parentDetails: json['parent_details']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'role': role,
    'extra_roles': extraRoles,
    'email': email,
    'phone': phone,
    'status': status,
    'is_first_login': isFirstLogin,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'permissions': permissions,
    'photo': photo,
    'name': name,
    'staff_details': staffDetails,
    'teacher_details': teacherDetails.toJson(),
    'parent_details': parentDetails,
  };

  static const ProfileData empty = ProfileData(
    id: '',
    userId: '',
    role: '',
    extraRoles: [],
    email: '',
    phone: '',
    status: '',
    isFirstLogin: '',
    createdAt: '',
    updatedAt: '',
    permissions: [],
    photo: '',
    name: '',
    staffDetails: '',
    teacherDetails: TeacherDetails.empty,
    parentDetails: '',
  );
}

class TeacherDetails {
  final String teacherId;
  final String firstName;
  final String surname;
  final String lastName;
  final String dob;
  final String email;
  final String mobile;
  final String photo;
  final String gender;
  final String createdAt;
  final String updatedAt;

  const TeacherDetails({
    required this.teacherId,
    required this.firstName,
    required this.surname,
    required this.lastName,
    required this.dob,
    required this.email,
    required this.mobile,
    required this.photo,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherDetails.fromJson(Map<String, dynamic> json) {
    return TeacherDetails(
      teacherId: json['teacher_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'first_name': firstName,
    'surname': surname,
    'last_name': lastName,
    'dob': dob,
    'email': email,
    'mobile': mobile,
    'photo': photo,
    'gender': gender,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  static const TeacherDetails empty = TeacherDetails(
    teacherId: '',
    firstName: '',
    surname: '',
    lastName: '',
    dob: '',
    email: '',
    mobile: '',
    photo: '',
    gender: '',
    createdAt: '',
    updatedAt: '',
  );
}
