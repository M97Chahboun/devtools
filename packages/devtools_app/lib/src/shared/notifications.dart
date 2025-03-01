// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'config_specific/launch_url/launch_url.dart';
import 'globals.dart';
import 'primitives/utils.dart';

class NotificationMessage {
  NotificationMessage(
    this.text, {
    this.actions = const [],
    this.duration = defaultDuration,
    this.isError = false,
    this.isDismissible = false,
  });

  /// The default duration for notifications to show.
  static const Duration defaultDuration = Duration(seconds: 7);

  final String text;
  final List<Widget> actions;
  final Duration duration;
  final bool isError;
  final bool isDismissible;
}

/// Collects tasks to show or dismiss notifications in UI.
class NotificationService {
  final toPush = Queue<NotificationMessage>();

  final toDismiss = Queue<NotificationMessage>();

  /// Notifies about added messages or dismissals.
  final ValueNotifier<int> newTasks = ValueNotifier(0);

  /// Messages that are planned to be shown or are currently shown in UI.
  @visibleForTesting
  final activeMessages = <NotificationMessage>[];

  /// Pushes a notification [message].
  ///
  /// Includes a button to close the notification if [isDismissible] is true.
  bool push(
    String message, {
    isDismissible = false,
  }) =>
      pushNotification(
        NotificationMessage(
          message,
          isDismissible: isDismissible,
        ),
      );

  /// Pushes an error notification with [errorMessage] as the text.
  ///
  /// Includes an action to report the error by opening the link to our issue
  /// tracker if [isReportable] is true. Includes a button to close the error if
  /// [isDismissible] is true.
  bool pushError(
    String errorMessage, {
    isDismissible = true,
    isReportable = true,
  }) {
    final reportErrorAction = NotificationAction(
      'Report error',
      () {
        unawaited(
          launchUrl(
            devToolsExtensionPoints
                .issueTrackerLink(
                  issueTitle: 'Reporting error: $errorMessage',
                )
                .url,
          ),
        );
      },
    );
    return pushNotification(
      NotificationMessage(
        errorMessage,
        isError: true,
        isDismissible: isDismissible,
        actions: [if (isReportable) reportErrorAction],
        // Double the duration so that the user has time to report the error:
        duration: isReportable
            ? NotificationMessage.defaultDuration * 2
            : NotificationMessage.defaultDuration,
      ),
      allowDuplicates: false,
    );
  }

  /// Pushes a notification [message].
  ///
  /// Ignores the message if [allowDuplicates] is false and a message with the
  /// same text is currently displayed to the user.
  bool pushNotification(
    NotificationMessage message, {
    bool allowDuplicates = true,
  }) {
    if (!allowDuplicates &&
        activeMessages.containsWhere((m) => m.text == message.text)) {
      return false;
    }
    activeMessages.add(message);
    toPush.add(message);
    newTasks.value++;
    return true;
  }

  /// Dismisses all notifications with a matching message.
  void dismiss(String message) {
    // Remove those that were not picked up yet by UI.
    final toRemove = toPush.where((e) => e.text == message).toList();
    for (var messageToRemove in toRemove) {
      toPush.remove(messageToRemove);
      activeMessages.remove(messageToRemove);
    }

    // Add task to dismiss for those that were picked up by UI.
    if (activeMessages.containsWhere((element) => element.text == message)) {
      toDismiss.addLast(NotificationMessage(message));
      newTasks.value++;
    }
  }

  /// Marks the message as complete, so that the messages not
  /// allowing duplicates,
  /// with the same text, do not get rejected.
  void markComplete(NotificationMessage message) {
    activeMessages.removeWhere((element) => element == message);
  }

  void dispose() {
    newTasks.dispose();
  }
}

class NotificationAction extends StatelessWidget {
  const NotificationAction(
    this.label,
    this.onAction, {
    super.key,
    this.isPrimary = false,
  });

  final String label;

  final VoidCallback onAction;

  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(label);
    return isPrimary
        ? ElevatedButton(
            onPressed: onAction,
            child: labelText,
          )
        : OutlinedButton(
            onPressed: onAction,
            child: labelText,
          );
  }
}
