extension EnumNameHelper<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String? name) {
    if (name == null) return null;
    try {
      return byName(name);
    } on ArgumentError {
      return null;
    }
  }
}
