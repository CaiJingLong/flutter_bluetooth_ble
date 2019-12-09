class StringUtils {
  static bool equalsIgnoreCase(String s1, String s2) {
    return s1?.trim()?.toUpperCase() == s2?.trim()?.toUpperCase();
  }
}
