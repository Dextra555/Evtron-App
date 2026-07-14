bool shouldShowBatteryProgressSection(String? chargerType) {
  final normalized = (chargerType ?? '').trim().toUpperCase();
  return normalized == 'DC';
}

String formatDisplayValue(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? 'N/A' : normalized;
}
