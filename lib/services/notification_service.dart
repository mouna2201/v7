import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_calendar/device_calendar.dart';

/// Service centralisé pour les notifications locales (Android + fallback Web).
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);

    if (!kIsWeb) {
      // Initialisation des timezones pour le scheduling Android.
      tz.initializeTimeZones();
    }

    _initialized = true;
  }

  Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'irrigation_channel',
      'Irrigation',
      channelDescription: 'Rappels liés au plan d\'irrigation',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    if (kIsWeb) {
      // Sur le web, flutter_local_notifications ne fonctionne pas nativement.
      // On utilise l'API Notification du navigateur si possible.
      _showWebNotification(title, body);
      return;
    }

    await _plugin.show(0, title, body, details);
  }

  /// Programme une notification pour la prochaine date d'arrosage.
  /// Sur Android on pourrait utiliser zonedSchedule, mais pour rester simple
  /// on se limite ici à une notification immédiate avec le texte du prochain jour.
  Future<void> scheduleIrrigationReminder({
    required String crop,
    required int intervalDays,
    required DateTime startDate,
    int? hour,
    int? minute,
  }) async {
    final nextDate = startDate.add(Duration(days: intervalDays));
    final int h = hour ?? 8; // heure par défaut : 08h00
    final int m = minute ?? 0;
    final scheduledDateTime = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      h,
      m,
    );

    final formattedDate =
        '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}';
    final formattedTime =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    if (kIsWeb) {
      // Sur le Web, on logge simplement avec date + heure.
      _showWebNotification(
        'Rappel d\'arrosage',
        'Prochain jour d\'arrosage pour $crop : $formattedDate à $formattedTime (tous les $intervalDays jours).',
      );
      return;
    }

    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'irrigation_channel',
      'Irrigation',
      channelDescription: 'Rappels liés au plan d\'irrigation',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Utilisation de zonedSchedule pour programmer la notif à la bonne heure locale.
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    await _plugin.zonedSchedule(
      0,
      'Rappel d\'arrosage',
      'Prochain jour d\'arrosage pour $crop : $formattedDate à $formattedTime (tous les $intervalDays jours).',
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: null,
    );
  }

  // --- Web only ---
  void _showWebNotification(String title, String body) {
    if (!kIsWeb) return;
    // Pour le Web, on se limite à un log pour l'instant.
    debugPrint('[WEB NOTIF] $title — $body');
  }

  /// Ajoute des événements d'irrigation récurrents dans le calendrier
  Future<String?> addIrrigationCalendarEvents({
    required String crop,
    required int intervalDays,
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) async {
    if (kIsWeb) {
      // Sur le web, générer un texte à copier-coller dans le calendrier
      final eventsText = _generateCalendarText(
        crop: crop,
        intervalDays: intervalDays,
        startDate: startDate,
        reminderTime: reminderTime,
      );
      return eventsText;
    }

    try {
      // Demander les permissions calendrier
      final permissions = await _calendarPlugin.requestPermissions();
      if (permissions.data == null || !permissions.data!) {
        return 'Permission calendrier refusée. Veuillez autoriser l\'accès au calendrier dans les paramètres.';
      }

      // Récupérer les calendriers disponibles
      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        return 'Aucun calendrier trouvé. Veuillez configurer un calendrier sur votre appareil.';
      }

      // Utiliser le premier calendrier disponible (généralement le calendrier principal)
      final primaryCalendar = calendarsResult.data!.first;

      // Créer les jours d'irrigation basés sur l'intervalle
      final irrigationDays = <DateTime>[];
      var currentDate = startDate;

      // Générer les 10 prochaines dates d'irrigation
      for (int i = 0; i < 10; i++) {
        irrigationDays.add(DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          reminderTime.hour,
          reminderTime.minute,
        ));
        currentDate = currentDate.add(Duration(days: intervalDays));
      }

      // Créer un événement récurrent pour chaque jour
      for (final irrigationDate in irrigationDays) {
        final event = Event(
          primaryCalendar.id,
          title: '🌱 Irrigation - $crop',
          description:
              'Rappel d\'irrigation pour $crop. Fréquence: Tous les $intervalDays jours.',
          start: tz.TZDateTime.from(irrigationDate, tz.local),
          end: tz.TZDateTime.from(irrigationDate.add(Duration(minutes: 15)),
              tz.local), // Durée de 15 minutes
        );

        final createResult = await _calendarPlugin.createOrUpdateEvent(event);
        if (createResult == null || !createResult.isSuccess) {
          return 'Erreur lors de la création des événements: ${createResult?.errors ?? 'Erreur inconnue'}';
        }
      }

      debugPrint(
          'Successfully created ${irrigationDays.length} irrigation calendar events');
      return null; // Succès
    } catch (e) {
      debugPrint('Error creating calendar events: $e');
      return 'Erreur lors de la création des événements calendrier: $e';
    }
  }

  /// Génère un texte formaté pour copier-coller dans le calendrier (version web)
  String _generateCalendarText({
    required String crop,
    required int intervalDays,
    required DateTime startDate,
    required TimeOfDay reminderTime,
  }) {
    final events = <String>[];
    var currentDate = startDate;

    // Générer les 10 prochains événements
    for (int i = 0; i < 10; i++) {
      final formattedDate =
          '${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.year}';
      final formattedTime =
          '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';
      events.add('📅 $formattedDate à $formattedTime - 🌱 Irrigation $crop');
      currentDate = currentDate.add(Duration(days: intervalDays));
    }

    return '''
🌱 PLAN D'IRRIGATION - $crop
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fréquence: Tous les $intervalDays jours
Heure: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}

📅 PROCHAINS RAPPELS:
${events.join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Copiez-collez ces événements dans votre calendrier préféré!
''';
  }

  // Récupère la liste des notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await init();
    if (kIsWeb) {
      // Pour le web, on retourne des données mockées car la fonctionnalité n'est pas dispo
      return [
        const PendingNotificationRequest(
            0, 'Rappel d\'arrosage', 'Exemple: Arrosage pour le blé demain à 8h00', null),
        const PendingNotificationRequest(
            1, 'Rappel d\'arrosage', 'Exemple: Arrosage pour le maïs après-demain à 9h00', null),
      ];
    }
    return await _plugin.pendingNotificationRequests();
  }
}
