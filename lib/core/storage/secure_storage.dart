abstract class ISecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class SecureStorage implements ISecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final Map<String, String> _secureCache = {};

  @override
  Future<void> write(String key, String value) async {
    _secureCache[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _secureCache[key];
  }

  @override
  Future<void> delete(String key) async {
    _secureCache.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _secureCache.clear();
  }
}
