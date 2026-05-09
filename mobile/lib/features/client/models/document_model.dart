import 'package:json_annotation/json_annotation.dart';

part 'document_model.g.dart';

@JsonSerializable()
class DocumentModel {
  final String id;
  final String type; // 'transcript', 'enrollment_proof', 'declaration', 'certificate'
  final String status; // 'requested', 'processing', 'ready', 'delivered'
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  final String? notes;
  @JsonKey(name: 'requested_at')
  final DateTime requestedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  const DocumentModel({
    required this.id,
    required this.type,
    required this.status,
    this.fileUrl,
    this.notes,
    required this.requestedAt,
    this.completedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentModelFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);

  bool get isDownloadable => status == 'ready' || status == 'delivered';
  bool get isPending => status == 'requested' || status == 'processing';
}
