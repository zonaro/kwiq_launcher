import 'package:flutter/material.dart';
import 'package:light_sensor/light_sensor.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isDark(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading indicator or placeholder
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle error
          return Text('Error: ${snapshot.error}');
        } else {
          final isDarkMode = snapshot.data ?? false;
          return ElevatedButton(
            onPressed: () {
              // Button action
            },
            child: Text(isDarkMode ? 'Show in Dark' : 'Show in Light'),
          );
        }
      },
    );
  }
}

Future<bool> isDark() async {
  final hasSensor = await LightSensor.hasSensor();
  if (!hasSensor) {
    // Light sensor is not available on this device
    return false;
  }

  const lightValue = 50;
  // You can adjust this threshold based on your preference
  const darkThreshold = 10; // Example threshold value

  return lightValue < darkThreshold;
}
