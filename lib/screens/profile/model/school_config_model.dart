class SchoolConfigResponse {
  final bool status;
  final String message;
  final SchoolConfigData data;

  SchoolConfigResponse({required this.status, required this.message, required this.data});

  factory SchoolConfigResponse.fromJson(Map<String, dynamic> json) {
    return SchoolConfigResponse(
      status: json['status'] == 'true' || json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: SchoolConfigData.fromJson(json['data'] ?? {}),
    );
  }
}

class SchoolConfigData {
  final String schoolName;
  final String schoolBoard;
  final String schoolTheme;
  final String schoolLogo;
  final String schoolTagline;
  final String schoolWebsite;
  final String schoolPhone;
  final String schoolLandline;
  final String schoolAdmissionPageUrl;
  final String schoolParentPlaystoreLink;
  final String schoolParentAppstoreLink;
  final String schoolTeacherPlaystoreLink;
  final String schoolTeacherAppstoreLink;
  final String schoolAffiliateId;
  final String schoolAddress;
  final String schoolCity;
  final String schoolState;
  final String schoolPostalcode;

  SchoolConfigData({
    required this.schoolName,
    required this.schoolBoard,
    required this.schoolTheme,
    required this.schoolLogo,
    required this.schoolTagline,
    required this.schoolWebsite,
    required this.schoolPhone,
    required this.schoolLandline,
    required this.schoolAdmissionPageUrl,
    required this.schoolParentPlaystoreLink,
    required this.schoolParentAppstoreLink,
    required this.schoolTeacherPlaystoreLink,
    required this.schoolTeacherAppstoreLink,
    required this.schoolAffiliateId,
    required this.schoolAddress,
    required this.schoolCity,
    required this.schoolState,
    required this.schoolPostalcode,
  });

  factory SchoolConfigData.fromJson(Map<String, dynamic> json) {
    return SchoolConfigData(
      schoolName: (json['school_name'] ?? '').toString(),
      schoolBoard: (json['school_board'] ?? '').toString(),
      schoolTheme: (json['school_theme'] ?? '').toString(),
      schoolLogo: (json['school_logo'] ?? '').toString(),
      schoolTagline: (json['school_tagline'] ?? '').toString(),
      schoolWebsite: (json['school_website'] ?? '').toString(),
      schoolPhone: (json['school_phone'] ?? '').toString(),
      schoolLandline: (json['school_landline'] ?? '').toString(),
      schoolAdmissionPageUrl: (json['school_admission_page_url'] ?? '').toString(),
      schoolParentPlaystoreLink: (json['school_parent_playstore_link'] ?? '').toString(),
      schoolParentAppstoreLink: (json['school_parent_appstore_link'] ?? '').toString(),
      schoolTeacherPlaystoreLink: (json['school_teacher_playstore_link'] ?? '').toString(),
      schoolTeacherAppstoreLink: (json['school_teacher_appstore_link'] ?? '').toString(),
      schoolAffiliateId: (json['school_affiliate_id'] ?? '').toString(),
      schoolAddress: (json['school_address'] ?? '').toString(),
      schoolCity: (json['school_city'] ?? '').toString(),
      schoolState: (json['school_state'] ?? '').toString(),
      schoolPostalcode: (json['school_postalcode'] ?? '').toString(),
    );
  }
}
