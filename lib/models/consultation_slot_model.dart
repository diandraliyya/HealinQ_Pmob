class ConsultationSlotModel {
  final String id;
  final DateTime startAt;
  final DateTime endAt;
  final String consultationType;

  const ConsultationSlotModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.consultationType,
  });

  factory ConsultationSlotModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ConsultationSlotModel(
      id: map['id']?.toString() ?? '',
      startAt: DateTime.parse(
        map['start_at'].toString(),
      ).toLocal(),
      endAt: DateTime.parse(
        map['end_at'].toString(),
      ).toLocal(),
      consultationType:
          map['consultation_type']?.toString() ??
              'online',
    );
  }

  int get durationMinutes {
    return endAt.difference(startAt).inMinutes;
  }
}
