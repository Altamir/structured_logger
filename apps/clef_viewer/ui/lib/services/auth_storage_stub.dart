final Map<String, String> _memory = {};

String? readAuthStorage(String key) => _memory[key];

void writeAuthStorage(String key, String value) {
  _memory[key] = value;
}

void removeAuthStorage(String key) {
  _memory.remove(key);
}