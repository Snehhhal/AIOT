class HazardReportModel {
  final String id;
  final String? reporterId;
  final String? reporterName;
  final String? reporterPhone;
  final String? poleId;
  final double latitude;
  final double longitude;
  final String? address;
  final String hazardType;
  final String description;
  final String? imageUrl;
  final String status;
  final String? assignedTechnicianId;
  final String? inspectionNotes;
  final String? inspectionImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HazardReportModel({
    required this.id,
    this.reporterId,
    this.reporterName,
    this.reporterPhone,
    this.poleId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.hazardType,
    required this.description,
    this.imageUrl,
    required this.status,
    this.assignedTechnicianId,
    this.inspectionNotes,
    this.inspectionImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory HazardReportModel.fromJson(Map<String, dynamic> json) {
    return HazardReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String?,
      reporterName: json['reporter_name'] as String?,
      reporterPhone: json['reporter_phone'] as String?,
      poleId: json['pole_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      hazardType: json['hazard_type'] as String? ?? 'Electrical Hazard',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'REPORTED',
      assignedTechnicianId: json['assigned_technician_id'] as String?,
      inspectionNotes: json['inspection_notes'] as String?,
      inspectionImageUrl: json['inspection_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'reporter_phone': reporterPhone,
      'pole_id': poleId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'hazard_type': hazardType,
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'assigned_technician_id': assignedTechnicianId,
      'inspection_notes': inspectionNotes,
      'inspection_image_url': inspectionImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return 'Reported';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'VERIFIED':
        return 'Verified';
      case 'REJECTED':
        return 'Rejected';
      case 'ASSIGNED':
        return 'Assigned to Lineman';
      case 'ACKNOWLEDGED':
        return 'Acknowledged';
      case 'IN_PROGRESS':
        return 'Repair In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  int get statusStep {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return 0;
      case 'UNDER_REVIEW':
        return 1;
      case 'VERIFIED':
      case 'ASSIGNED':
        return 2;
      case 'ACKNOWLEDGED':
      case 'IN_PROGRESS':
        return 3;
      case 'RESOLVED':
      case 'CLOSED':
        return 4;
      default:
        return 0;
    }
  }
}
