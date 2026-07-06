class Resume {
  final String id;
  final String userId;
  final String title;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String summary;
  final String category; // 'Tech', 'Design', 'Marketing', 'Finance', 'Other'
  final List<String> skills;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  final List<Certification> certifications;
  final List<Project> projects;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Resume({
    required this.id,
    required this.userId,
    required this.title,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.summary,
    this.category = 'Other',
    required this.skills,
    required this.workExperience,
    required this.education,
    required this.certifications,
    required this.projects,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'summary': summary,
        'category': category,
        'skills': skills,
        'workExperience': workExperience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Resume.fromJson(Map<String, dynamic> json) => Resume(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        fullName: json['fullName'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        summary: json['summary'],
        category: (json['category'] as String?) ?? 'Other',
        skills: List<String>.from(json['skills']),
        workExperience:
            (json['workExperience'] as List)
                .map((e) => WorkExperience.fromJson(e))
                .toList(),
        education:
            (json['education'] as List)
                .map((e) => Education.fromJson(e))
                .toList(),
        certifications:
            (json['certifications'] as List)
                .map((e) => Certification.fromJson(e))
                .toList(),
        projects:
            (json['projects'] as List)
                .map((e) => Project.fromJson(e))
                .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        isDeleted: json['isDeleted'] ?? false,
      );
}

class WorkExperience {
  final String company;
  final String position;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final List<String> responsibilities;

  WorkExperience({
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    required this.responsibilities,
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'position': position,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'responsibilities': responsibilities,
      };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
        company: json['company'],
        position: json['position'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        isCurrent: json['isCurrent'],
        responsibilities: List<String>.from(json['responsibilities']),
      );
}

class Education {
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String? endDate;
  final bool isCurrent;

  Education({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
  });

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
      };

  factory Education.fromJson(Map<String, dynamic> json) => Education(
        institution: json['institution'],
        degree: json['degree'],
        fieldOfStudy: json['fieldOfStudy'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        isCurrent: json['isCurrent'],
      );
}

class Certification {
  final String name;
  final String issuingOrganization;
  final String issueDate;
  final String? expiryDate;

  Certification({
    required this.name,
    required this.issuingOrganization,
    required this.issueDate,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'issuingOrganization': issuingOrganization,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        name: json['name'],
        issuingOrganization: json['issuingOrganization'],
        issueDate: json['issueDate'],
        expiryDate: json['expiryDate'],
      );
}

class Project {
  final String name;
  final String description;
  final List<String> technologies;
  final String? link;

  Project({
    required this.name,
    required this.description,
    required this.technologies,
    this.link,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'technologies': technologies,
        'link': link,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'],
        description: json['description'],
        technologies: List<String>.from(json['technologies']),
        link: json['link'],
      );
}
