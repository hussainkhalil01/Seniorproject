

String cooldownText(int seconds) {
  return "Please wait ${seconds}s";
}

String uploadImageCloudinaryUserId(String userId) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  return "amanbuild_${userId}_profile_${ts}";
}
