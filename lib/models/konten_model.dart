class KontenModel {
  final String kontenId;
  final String judul;
  final String deskripsi;
  final String body;
  final String thumbnail;
  final bool isUploaded;
  final String bankId;
  final String adminId;
  final String namaAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String nama_instansi;

  KontenModel({
    required this.kontenId,
    required this.judul,
    required this.deskripsi,
    required this.body,
    required this.thumbnail,
    required this.isUploaded,
    required this.bankId,
    required this.adminId,
    required this.namaAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.nama_instansi,
  });

  factory KontenModel.fromJson(Map<String, dynamic> json) {
    return KontenModel(
      kontenId:     json['KontenID']    ?? json['konten_id']    ?? '',
      judul:        json['Judul']       ?? json['judul']        ?? '',
      deskripsi:    json['Deskripsi']   ?? json['deskripsi']    ?? '',
      body:         json['Body']        ?? json['body']         ?? '',
      thumbnail:    json['Thumbnail']   ?? json['thumbnail']    ?? '',
      isUploaded:   json['IsUploaded']  ?? json['is_uploaded']  ?? false,
      bankId:       json['BankID']      ?? json['bank_id']      ?? '',
      adminId:      json['AdminID']     ?? json['admin_id']     ?? '',
      namaAdmin:    json['nama_admin']  ?? '',
      nama_instansi: json['nama_instansi'] ?? '',
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
    );
  }
}
