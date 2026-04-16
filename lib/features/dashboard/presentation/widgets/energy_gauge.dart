import "package:flutter/material.dart";

class EnergyGauge extends StatelessWidget {
  final String label;
  final double value;

  const EnergyGauge({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        LinearProgressIndicator(value: value / 100),
      ],
    );
  }
}
