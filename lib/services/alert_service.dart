// lib/services/alert_service.dart
// Servicio para obtener y actualizar alertas de riesgo académico.

import 'package:get/get.dart';
import '../models/alert_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AlertService extends GetxService {
  static AlertService get to => Get.find();

  final ApiClient _api = ApiClient();
  final RxList<AlertModel> _alerts = <AlertModel>[].obs;
  final RxBool _loading = false.obs;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _loading.value;
  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  Future<void> fetchAlerts() async {
    final user = AuthService.to.currentUser;
    // Las alertas de riesgo son de alumno; un docente recibe 403 en /alerts/me.
    if (user == null || user.isTeacher) return;

    _loading.value = true;
    try {
      final response = await _api.getJson('/alerts/me');
      final List<dynamic> listRaw = response['alerts'] ?? [];
      final List<AlertModel> loadedAlerts = listRaw.map((item) {
        return AlertModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
      _alerts.assignAll(loadedAlerts);
    } catch (e) {
      print('Error fetching alerts: $e');
    } finally {
      _loading.value = false;
    }
  }

  Future<void> markAsRead(int alertId) async {
    final user = AuthService.to.currentUser;
    if (user == null) return;

    try {
      await _api.putJson('/alerts/me/$alertId/read', body: {});
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index].isRead = true;
        _alerts.refresh();
      }
    } catch (e) {
      print('Error marking alert as read: $e');
    }
  }
}
