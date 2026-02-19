import 'dart:async';
import 'package:neon_framework/src/platform/platform_channel.dart';

enum NeonStorageLocation { appDocuments, appCache, appSupport, temp }

class NeonFileSystem {
  final NeonPlatformChannel channel;
  final Map<String, String> _mockFiles = {};
  bool _useMock = false;

  NeonFileSystem({required this.channel});

  void enableMock() {
    _useMock = true;
  }

  void disableMock() {
    _useMock = false;
    _mockFiles.clear();
  }

  Future<String?> readFile(String path, {NeonStorageLocation location = NeonStorageLocation.appDocuments}) async {
    if (_useMock) {
      final key = '${location.name}:$path';
      return _mockFiles[key];
    }

    return channel.invokeMethod<String>('file.read', {
      'path': path,
      'location': location.name,
    });
  }

  Future<bool> writeFile(String path, String content, {NeonStorageLocation location = NeonStorageLocation.appDocuments}) async {
    if (_useMock) {
      final key = '${location.name}:$path';
      _mockFiles[key] = content;
      return true;
    }

    final result = await channel.invokeMethod<bool>('file.write', {
      'path': path,
      'content': content,
      'location': location.name,
    });
    return result ?? false;
  }

  Future<bool> deleteFile(String path, {NeonStorageLocation location = NeonStorageLocation.appDocuments}) async {
    if (_useMock) {
      final key = '${location.name}:$path';
      return _mockFiles.remove(key) != null;
    }

    final result = await channel.invokeMethod<bool>('file.delete', {
      'path': path,
      'location': location.name,
    });
    return result ?? false;
  }

  Future<bool> fileExists(String path, {NeonStorageLocation location = NeonStorageLocation.appDocuments}) async {
    if (_useMock) {
      final key = '${location.name}:$path';
      return _mockFiles.containsKey(key);
    }

    final result = await channel.invokeMethod<bool>('file.exists', {
      'path': path,
      'location': location.name,
    });
    return result ?? false;
  }

  Future<List<String>> listFiles(String directory, {NeonStorageLocation location = NeonStorageLocation.appDocuments}) async {
    if (_useMock) {
      final prefix = '${location.name}:$directory';
      return _mockFiles.keys
          .where((k) => k.startsWith(prefix))
          .map((k) => k.substring('${location.name}:'.length))
          .toList();
    }

    final result = await channel.invokeMethod<List>('file.list', {
      'directory': directory,
      'location': location.name,
    });
    return result?.cast<String>() ?? [];
  }

  Future<String?> getStoragePath(NeonStorageLocation location) async {
    if (_useMock) {
      return '/mock/${location.name}';
    }

    return channel.invokeMethod<String>('file.getPath', {
      'location': location.name,
    });
  }
}
