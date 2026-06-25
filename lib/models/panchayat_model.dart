class PanchayatModel {
  final String id;
  final String name;
  final String district;
  final String createdBy;

  PanchayatModel({
    required this.id,
    required this.name,
    required this.district,
    required this.createdBy,
  });

  factory PanchayatModel.fromMap(String id, Map<String, dynamic> data) {
    return PanchayatModel(
      id: id,
      name: data['name'] ?? '',
      district: data['district'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'district': district, 'createdBy': createdBy};
  }
}
