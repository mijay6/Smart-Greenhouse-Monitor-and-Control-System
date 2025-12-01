import '../../domain/entities/actuator_state.dart';

class ActuatorStateModel extends ActuatorState {
  const ActuatorStateModel({
    required super.pumpOn,
    required super.fanIntakeOn,
    required super.fanExhaustOn,
    required super.windowOpen,
    required super.ledOn,
    required super.ledColor,
  });

  // if the ESP sends the actuator state
  factory ActuatorStateModel.fromJson(Map<String, dynamic> json) {
    final ledRgb = json['led_rgb'] as Map<String, dynamic>?;

    return ActuatorStateModel(
      pumpOn: json['pump'] == 1 || json['pump'] == true,
      fanIntakeOn: json['fan_intake'] == 1 || json['fan_intake'] == true,
      fanExhaustOn: json['fan_exhaust'] == 1 || json['fan_exhaust'] == true,
      windowOpen: json['window'] == 1 || json['window'] == true,
      ledOn:
          json['led'] == 1 ||
          json['led'] ==
              true, // see if this line is necessary, because of LedColor.off()
      ledColor: ledRgb != null
          ? LedColor(
              red: (ledRgb['r'] as int?) ?? 0,
              green: (ledRgb['g'] as int?) ?? 0,
              blue: (ledRgb['b'] as int?) ?? 0,
            )
          : LedColor.off(),
    );
  }

  // to send to the ESP or Firebase
  Map<String, dynamic> toJson() {
    return {
      'pump': pumpOn ? 1 : 0,
      'fan_intake': fanIntakeOn ? 1 : 0,
      'fan_exhaust': fanExhaustOn ? 1 : 0,
      'window': windowOpen ? 1 : 0,
      'led': ledOn ? 1 : 0,
      'led_rgb': {'r': ledColor.red, 'g': ledColor.green, 'b': ledColor.blue},
    };
  }

  static Map<String, dynamic> singleActuatorCommand(
    String actuator,
    bool state,
  ) {
    return {'command': 'manual_override', actuator: state ? 1 : 0};
  }

  static Map<String, dynamic> ledColorCommand(LedColor color) {
    return {
      'command': 'manual_override',
      'led_rgb': {'r': color.red, 'g': color.green, 'b': color.blue},
    };
  }

  // convert to domain entity
  ActuatorState toEntity() {
    return ActuatorState(
      pumpOn: pumpOn,
      fanIntakeOn: fanIntakeOn,
      fanExhaustOn: fanExhaustOn,
      windowOpen: windowOpen,
      ledOn: ledOn,
      ledColor: ledColor,
    );
  }
}
