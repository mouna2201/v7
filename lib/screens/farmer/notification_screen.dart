import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<PendingNotificationRequest>> _pendingNotifications;

  @override
  void initState() {
    super.initState();
    _pendingNotifications =
        NotificationService().getPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Programmées'),
      ),
      body: FutureBuilder<List<PendingNotificationRequest>>(
        future: _pendingNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucune notification programmée.'),
            );
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notif.title ?? 'Sans titre'),
                  subtitle: Text(notif.body ?? 'Sans contenu'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
