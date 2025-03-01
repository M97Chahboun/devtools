// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Stack;
import 'package:vm_service/vm_service.dart';

import '../../shared/common_widgets.dart';
import '../../shared/theme.dart';
import '../../shared/utils.dart';
import 'debugger_controller.dart';
import 'debugger_model.dart';

class CallStack extends StatefulWidget {
  const CallStack({Key? key}) : super(key: key);

  @override
  State<CallStack> createState() => _CallStackState();
}

class _CallStackState extends State<CallStack>
    with ProvidedControllerMixin<DebuggerController, CallStack> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initController();
  }

  @override
  Widget build(BuildContext context) {
    return DualValueListenableBuilder<List<StackFrameAndSourcePosition>,
        StackFrameAndSourcePosition?>(
      firstListenable: controller.stackFramesWithLocation,
      secondListenable: controller.selectedStackFrame,
      builder: (context, stackFrames, selectedFrame, _) {
        return ListView.builder(
          itemCount: stackFrames.length,
          itemExtent: defaultListItemHeight,
          itemBuilder: (_, index) {
            final frame = stackFrames[index];
            return _buildStackFrame(frame, frame == selectedFrame);
          },
        );
      },
    );
  }

  Widget _buildStackFrame(
    StackFrameAndSourcePosition frame,
    bool selected,
  ) {
    final theme = Theme.of(context);

    Widget child;

    final frameKind = frame.frame.kind;

    final asyncMarker = frameKind == FrameKind.kAsyncSuspensionMarker;
    final frameDescription = frame.description;
    final locationDescription = frame.location;

    if (asyncMarker) {
      child = Row(
        children: [
          const SizedBox(width: defaultSpacing, child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: densePadding),
            child: Text(
              frameDescription,
              style: theme.regularTextStyle,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );
    } else {
      child = RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: frameDescription,
          style: theme.regularTextStyle,
          children: [
            if (locationDescription != null)
              TextSpan(
                text: ' $locationDescription',
                style: selected
                    ? theme.selectedSubtleTextStyle
                    : theme.subtleTextStyle,
              ),
          ],
        ),
      );
    }

    final isAsyncBreak = frame.frame.kind == FrameKind.kAsyncSuspensionMarker;

    final result = Material(
      color: selected ? theme.colorScheme.selectedRowBackgroundColor : null,
      child: InkWell(
        onTap: () async => await _onStackFrameSelected(frame),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: densePadding),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );

    return isAsyncBreak
        ? result
        : DevToolsTooltip(
            message: locationDescription == null
                ? frameDescription
                : '$frameDescription $locationDescription',
            waitDuration: tooltipWaitLong,
            child: result,
          );
  }

  Future<void> _onStackFrameSelected(StackFrameAndSourcePosition frame) async {
    await controller.selectStackFrame(frame);
  }
}
