import 'package:meta/meta.dart';
import 'dart:convert';

DataModel dataModelFromJson(String str) => DataModel.fromJson(json.decode(str));

String dataModelToJson(DataModel data) => json.encode(data.toJson());

class DataModel {
  DataModel({
    required this.greeting,
    required this.instructions,
  });

  final String greeting;
  final String instructions;

  factory DataModel.fromJson(Map<String, dynamic> json) => DataModel(
        greeting: json["greeting"],
        instructions: json["instructions"],
      );

  Map<String, dynamic> toJson() => {
        "greeting": greeting,
        "instructions": instructions,
      };
}
