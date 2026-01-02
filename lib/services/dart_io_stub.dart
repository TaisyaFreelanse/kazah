
class File {
  final String _path;
  File(this._path);
  Future<bool> exists() => throw UnsupportedError('File API недоступен на веб-платформе');
  Future<List<int>> readAsBytes() => throw UnsupportedError('File API недоступен на веб-платформе');
  Future<File> writeAsBytes(List<int> bytes) => throw UnsupportedError('File API недоступен на веб-платформе');
  Future<File> delete({bool recursive = false}) => throw UnsupportedError('File API недоступен на веб-платформе');
  String get path => _path;
}

class Directory {
  final String _path;
  Directory(this._path);
  String get path => _path;
  Future<bool> exists() => throw UnsupportedError('Directory API недоступен на веб-платформе');
  Future<Directory> create({bool recursive = false}) => throw UnsupportedError('Directory API недоступен на веб-платформе');
}
