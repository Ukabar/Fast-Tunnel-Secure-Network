bool isValidAdMobAdUnitId(String value) {
  return value.trim().startsWith('ca-app-pub-') && value.contains('/');
}

bool isValidProvider(String value) {
  return value == 'admob' || value == 'applovin';
}
