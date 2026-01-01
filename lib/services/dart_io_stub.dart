// Stub для dart:io на веб-платформе
// Этот файл используется только для условного импорта и никогда не выполняется
// так как код с File/Directory защищен проверкой kIsWeb

class File {
  final String _path;
  File(this._path);
  Future<bool> exists() => throw UnsupportedError('File API недоступен на веб-платформе');
  Future<List<int>> readAsBytes() => throw UnsupportedError('File API недоступен на веб-платформе');
  Future<File> writeAsBytes(List<int> bytes) => throw UnsupportedError('File API недоступен на веб-платформе');
  String get path => _path;
}

class Directory {
  final String _path;
  Directory(this._path);
  String get path => _path;
  Future<bool> exists() => throw UnsupportedError('Directory API недоступен на веб-платформе');
  Future<Directory> create({bool recursive = false}) => throw UnsupportedError('Directory API недоступен на веб-платформе');
}
