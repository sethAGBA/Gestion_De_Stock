
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityItem {
  final String type;
  final String description;
  final DateTime date;

  ActivityItem({
    required this.type,
    required this.description,
    required this.date,
  });
}

class RecentActivityWidget extends StatelessWidget {
  final String title;
  final List<ActivityItem> activities;

  const RecentActivityWidget({
    super.key,
    required this.title,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: activities.isEmpty
                ? const Center(child: Text('Aucune activité récente'))
                : ListView.builder(
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        leading: Icon(
                          activity.type == 'Vente'
                              ? Icons.attach_money
                              : activity.type == 'Entrée'
                                  ? Icons.input
                                  : Icons.output,
                          color: activity.type == 'Vente'
                              ? Colors.green
                              : activity.type == 'Entrée'
                                  ? Colors.blue
                                  : Colors.red,
                        ),
                        title: Text(activity.description),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(activity.date),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
