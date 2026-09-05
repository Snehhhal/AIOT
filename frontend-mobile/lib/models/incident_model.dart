class IncidentModel {
  final String id;
  final String poleId;
  final String severity;
  final String status;
  final String description;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const IncidentModel({
    required this.id,
    required this.poleId,
    required this.severity,
    required this.status,
    required this.description,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] ?? '',
      poleId: json['pole_id'] ?? '',
      severity: json['severity'] ?? 'WARNING',
      status: json['status'] ?? 'DETECTED',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolvedBy: json['resolved_by'],
    );
  }

  bool get isCriticalOrEmergency => severity == 'CRITICAL' || severity == 'EMERGENCY';
  bool get isResolved => status == 'RESOLVED' || status == 'CLOSED';
}

class WorkOrderModel {
  final String id;
  final String incidentId;
  final String? technicianId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkOrderModel({
    required this.id,
    required this.incidentId,
    this.technicianId,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] ?? '',
      incidentId: json['incident_id'] ?? '',
      technicianId: json['technician_id'],
      status: json['status'] ?? 'ASSIGNED',
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}
