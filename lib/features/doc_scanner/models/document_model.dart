class DocumentModel {

  final String id;

  final String filePath;

  final String text;

  final double lat;

  final double lng;

  final String address;

  final int pageCount;

  final DateTime createdAt;

  DocumentModel({

    required this.id,
    required this.filePath,
    required this.text,
    required this.lat,
    required this.lng,
    required this.address,
    required this.pageCount,
    required this.createdAt,
  });

}