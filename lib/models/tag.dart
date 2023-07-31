// ignore_for_file: public_member_api_docs, sort_constructors_first
// class to model receipt tags extracted from OCR and create object to store in database
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Tag {
  final String id;
  final String receiptId;
  final String tag;

  const Tag({
    required this.id, 
    required this.receiptId, 
    required this.tag});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'receiptId': receiptId,
      'tag': tag,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      receiptId: map['receiptId'] as String,
      tag: map['tag'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Tag.fromJson(String source) => Tag.fromMap(json.decode(source) as Map<String, dynamic>);
}
