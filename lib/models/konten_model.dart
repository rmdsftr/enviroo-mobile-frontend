class KontenModel {
  final String kontenId;
  final String judul;
  final String deskripsi;
  final String body;
  final String thumbnail;
  final bool isUploaded;
  final String bankId;
  final String adminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  KontenModel({
    required this.kontenId,
    required this.judul,
    required this.deskripsi,
    required this.body,
    required this.thumbnail,
    required this.isUploaded,
    required this.bankId,
    required this.adminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KontenModel.fromJson(Map<String, dynamic> json) {
    return KontenModel(
      kontenId: json['KontenID'] ?? '',
      judul: json['Judul'] ?? '',
      deskripsi: json['Deskripsi'] ?? '',
      body: json['Body'] ?? '',
      thumbnail: json['Thumbnail'] ?? '',
      isUploaded: json['IsUploaded'] ?? false,
      bankId: json['BankID'] ?? '',
      adminId: json['AdminID'] ?? '',
      createdAt: json['CreatedAt'] != null 
          ? DateTime.parse(json['CreatedAt']) 
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.parse(json['UpdatedAt']) 
          : DateTime.now(),
    );
  }
}
