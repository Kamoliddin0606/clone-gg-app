import 'package:flutter/material.dart';

/// Visit status indicator widget showing visit completion state
class VisitStatusIndicator extends StatelessWidget {
  final bool visitToday;
  final bool isVisited;

  const VisitStatusIndicator({
    super.key,
    required this.visitToday,
    required this.isVisited,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String tooltip;

    if (visitToday && isVisited) {
      icon = Icons.check_circle;
      color = Colors.green;
      tooltip = 'Bugun tashrif bajarildi';
    } else if (visitToday && !isVisited) {
      icon = Icons.schedule;
      color = Colors.orange;
      tooltip = 'Bugun tashrif kutilmoqda';
    } else {
      icon = Icons.warning;
      color = Colors.red;
      tooltip = 'Bugun tashrif rejalashtirilmagan';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

/// Visit step indicator widget showing visit order number
class VisitStepIndicator extends StatelessWidget {
  final bool visitToday;
  final int visitStepNumber;

  const VisitStepIndicator({
    super.key,
    required this.visitToday,
    required this.visitStepNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (!visitToday) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Tooltip(
      message: 'Tashrif tartibi: $visitStepNumber',
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            visitStepNumber.toString(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Combined visit indicators widget for easy integration
class VisitIndicators extends StatelessWidget {
  final bool visitToday;
  final bool isVisited;
  final int visitStepNumber;

  const VisitIndicators({
    super.key,
    required this.visitToday,
    required this.isVisited,
    required this.visitStepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VisitStatusIndicator(
          visitToday: visitToday,
          isVisited: isVisited,
        ),
        if (visitToday) const SizedBox(width: 4),
        VisitStepIndicator(
          visitToday: visitToday,
          visitStepNumber: visitStepNumber,
        ),
      ],
    );
  }
}