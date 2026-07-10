class ConsultationSlotModel {
  final String id;

  final DateTime startAt;

  final DateTime endAt;

  final String consultationType;

  ConsultationSlotModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.consultationType,
  });

  factory ConsultationSlotModel.fromMap(
      Map<String, dynamic> map) {
    return ConsultationSlotModel(
      id: map['id'],

      startAt:
          DateTime.parse(map['start_at']),

      endAt:
          DateTime.parse(map['end_at']),

      consultationType:
          map['consultation_type'],
    );
  }
}