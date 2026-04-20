
final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

String cooldownText(int seconds) {
  return "Please wait ${seconds}s";
}

String uploadImageCloudinaryUserId(String userId) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  return "amanbuild_${userId}_profile_$ts";
}
