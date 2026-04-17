import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifikasiService {
  static final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> inisialisasi() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    // PERBAIKAN: Menggunakan named parameter 'initializationSettings' (atau 'settings' pada beberapa versi)
    await _notifPlugin.initialize(settings: initSettings);
  }

  static Future<void> tampilkanNotif(String judul, String isi) async {
    const AndroidNotificationDetails androidDetail = AndroidNotificationDetails(
      'sla_warning_channel',
      'Peringatan SLA',
      channelDescription: 'Notifikasi untuk SLA yang hampir telat',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF2979FF),
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails detail = NotificationDetails(
      android: androidDetail,
    );

    // PERBAIKAN: Menggunakan named parameters untuk method show()
    await _notifPlugin.show(
      id: 0,
      title: judul,
      body: isi,
      notificationDetails: detail,
    );
  }
}
