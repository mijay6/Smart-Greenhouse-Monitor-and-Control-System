class ActuatorState {
  final bool pumpOn;
  final bool pumpSyncing;
  final bool fanIntakeOn;
  final bool fanIntakeSyncing;
  final bool fanExhaustOn;
  final bool fanExhaustSyncing;
  final bool windowOpen;
  final bool windowSyncing;
  final bool ledOn;
  final bool ledSyncing;
  final LedColor ledColor;

  const ActuatorState({
    required this.pumpOn,
    this.pumpSyncing = false,
    required this.fanIntakeOn,
    this.fanIntakeSyncing = false,
    required this.fanExhaustOn,
    this.fanExhaustSyncing = false,
    required this.windowOpen,
    this.windowSyncing = false,
    required this.ledOn,
    this.ledSyncing = false,
    required this.ledColor,
  });

  // Initial state with all actuators off
  factory ActuatorState.initial() {
    return ActuatorState(
      pumpOn: false,
      fanIntakeOn: false,
      fanExhaustOn: false,
      windowOpen: false,
      ledOn: false,
      ledColor: LedColor.white(),
    );
  }

  // copy with modified values (immutable)
  ActuatorState copyWith({
    bool? pumpOn,
    bool? pumpSyncing,
    bool? fanIntakeOn,
    bool? fanIntakeSyncing,
    bool? fanExhaustOn,
    bool? fanExhaustSyncing,
    bool? windowOpen,
    bool? windowSyncing,
    bool? ledOn,
    bool? ledSyncing,
    LedColor? ledColor,
  }) {
    return ActuatorState(
      pumpOn: pumpOn ?? this.pumpOn,
      pumpSyncing: pumpSyncing ?? this.pumpSyncing,
      fanIntakeOn: fanIntakeOn ?? this.fanIntakeOn,
      fanIntakeSyncing: fanIntakeSyncing ?? this.fanIntakeSyncing,
      fanExhaustOn: fanExhaustOn ?? this.fanExhaustOn,
      fanExhaustSyncing: fanExhaustSyncing ?? this.fanExhaustSyncing,
      windowOpen: windowOpen ?? this.windowOpen,
      windowSyncing: windowSyncing ?? this.windowSyncing,
      ledOn: ledOn ?? this.ledOn,
      ledSyncing: ledSyncing ?? this.ledSyncing,
      ledColor: ledColor ?? this.ledColor,
    );
  }

  @override
  String toString() {
    return 'ActuatorState(pumpOn: $pumpOn, fanIn: $fanIntakeOn, fanOut: $fanExhaustOn, window: $windowOpen, led: $ledOn)';
  }
}

class LedColor {
  final int red;
  final int green;
  final int blue;

  const LedColor({required this.red, required this.green, required this.blue});

  factory LedColor.white() => const LedColor(red: 255, green: 255, blue: 255);
  factory LedColor.off() => const LedColor(red: 0, green: 0, blue: 0);

  factory LedColor.fromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return LedColor(
      red: int.parse(hexColor.substring(0, 2), radix: 16),
      green: int.parse(hexColor.substring(2, 4), radix: 16),
      blue: int.parse(hexColor.substring(4, 6), radix: 16),
    );
  }

  String toHex() {
    return '#${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'RGB($red, $green, $blue)';
  }

  // we need to override equal operator to compare values, not memory references
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedColor &&
        other.red == red &&
        other.green == green &&
        other.blue == blue;
  }

  // and hashCode too, because two equal objects must have the same hashCode
  // this hascode is used in collections like sets and maps
  @override
  int get hashCode => Object.hash(red, green, blue);
}
