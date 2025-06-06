import '../models/sensor_data.dart';
import '../models/coefficients.dart';
import 'dart:convert';

class DataParserService {
  SensorData parseSensorTrame(String jsonString) {
    // TODO : convertir JSON en SensorData
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return SensorData.fromJson(jsonMap);
  }

  Coefficients parseCoefficientsTrame(String jsonString) {
    // TODO : convertir JSON en Coefficients
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return Coefficients.fromJson(jsonMap);
  }

  // Optionnel : appliquer le calibrage avant de retourner les valeurs
}
