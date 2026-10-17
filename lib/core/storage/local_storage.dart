abstract class ILocalStorage {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class LocalStorage implements ILocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  final Map<String, dynamic> _memoryCache = {};

  @override
  Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _memoryCache[key] as String?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _memoryCache[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _memoryCache[key] as bool?;
  }

  @override
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
  }

  @override
  Future<void> clear() async {
    _memoryCache.clear();
  }
}
