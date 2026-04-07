class CountryModel {
  final String? id;
  final String name;
  final String isoCode;
  final String localization;
  final DateTime date;

  const CountryModel({
    this.id,
    required this.name,
    required this.isoCode,
    required this.localization,
    required this.date,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      isoCode: json['iso_code'] as String,
      localization: json['localization'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iso_code': isoCode,
      'localization': localization,
      'date': date.toIso8601String(),
    };
  }

  CountryModel copyWith({
    String? id,
    String? name,
    String? isoCode,
    String? localization,
    DateTime? date,
  }) {
    return CountryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isoCode: isoCode ?? this.isoCode,
      localization: localization ?? this.localization,
      date: date ?? this.date,
    );
  }
}
