bool shouldShowBatteryProgressSection(String? chargerType) {
  final normalized = (chargerType ?? '').trim().toUpperCase();
  return normalized == 'DC';
}

String formatDisplayValue(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? 'N/A' : normalized;
}

Duration calculateElapsedDuration({
  required Duration baseDuration,
  required DateTime? lastUpdateTime,
  required DateTime now,
}) {
  if (lastUpdateTime == null) {
    return baseDuration;
  }

  return baseDuration + now.difference(lastUpdateTime);
}
