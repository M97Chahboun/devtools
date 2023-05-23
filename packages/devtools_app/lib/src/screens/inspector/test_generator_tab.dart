import 'package:flutter/material.dart';
import 'inspector_controller.dart';

class TestGenerator extends StatelessWidget {
  const TestGenerator({super.key, required this.controller});
  final InspectorController controller;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.selectedNode,
      builder: (context, value, child) {
        if (controller.selectedDiagnostic == null) {
          return const Text('Try to select a widget first');
        }
        return Column(
          children: [
            ListTile(
              title: Text(controller.selectedDiagnostic!.description!),
              leading: controller.selectedDiagnostic!.icon,
            ),
            controller.selectedDiagnostic != null
                ? TextButton(
                    onPressed: () {},
                    child: const Text('Generate Test'),
                  )
                : Container(),
          ],
        );
      },
    );
  }
}
