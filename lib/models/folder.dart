// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

// class to model folder object in database to store receipts and other folders
 @JsonSerializable()
class Folder {
  final String id;
  final String name;
  final int lastModified;
  final String parentId;

  Folder({required this.id, required this.name, required this.lastModified, required this.parentId});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'lastModified': lastModified,
      'parentId': parentId,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      lastModified: map['lastModified'] as int,
      parentId: map['parentId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Folder.fromJson(String source) => Folder.fromMap(json.decode(source) as Map<String, dynamic>);
}
