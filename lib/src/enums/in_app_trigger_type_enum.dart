enum InAppTriggerTypeEnum {
  immediate,
  nextForeground,
  appLaunch,
  custom;

  static InAppTriggerTypeEnum fromString(String? value) {
    final normalized = value?.toLowerCase().trim() ?? '';
    switch (normalized) {
      case 'next_foreground':
      case 'nextforeground':
        return InAppTriggerTypeEnum.nextForeground;
      case 'app_launch':
      case 'applaunch':
        return InAppTriggerTypeEnum.appLaunch;
      case 'custom':
        return InAppTriggerTypeEnum.custom;
      case 'immediate':
      default:
        return InAppTriggerTypeEnum.immediate;
    }
  }
}
