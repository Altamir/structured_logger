class LogModel {
  String t;
  String mt;
  String level;
  Map<String, dynamic>? data;

  LogModel({
    required this.mt,
    this.level = "debug",
    this.data,
    this.t = "",
  }) {
    if (t.isEmpty) t = DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '@t': t,
      '@mt': mt,
      '@l': level,
      'data': data,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      t: map['@t'],
      mt: map['@mt'],
      level: map['@l'],
      data: map['data'],
    );
  }
}
