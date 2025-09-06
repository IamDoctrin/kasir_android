import 'package:floor/floor.dart';

@entity
class Kategori {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String nama;

  Kategori({this.id, required this.nama});
}
