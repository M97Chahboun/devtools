// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../shared/analytics/constants.dart' as gac;
import '../../shared/common_widgets.dart';
import '../../shared/http/http_request_data.dart';
import '../../shared/ui/tab.dart';
import 'network_controller.dart';
import 'network_model.dart';
import 'network_request_inspector_views.dart';

/// A [Widget] which displays information about a network request.
class NetworkRequestInspector extends StatelessWidget {
  const NetworkRequestInspector(this.controller, {super.key});

  static const _overviewTabTitle = 'Overview';
  static const _headersTabTitle = 'Headers';
  static const _requestTabTitle = 'Request';
  static const _responseTabTitle = 'Response';
  static const _cookiesTabTitle = 'Cookies';

  // TODO(kenz): remove these keys and use a text finder to lookup widgets in test.

  @visibleForTesting
  static const overviewTabKey = Key(_overviewTabTitle);
  @visibleForTesting
  static const headersTabKey = Key(_headersTabTitle);
  @visibleForTesting
  static const responseTabKey = Key(_responseTabTitle);
  @visibleForTesting
  static const cookiesTabKey = Key(_cookiesTabTitle);
  @visibleForTesting
  static const noRequestSelectedKey = Key('No Request Selected');

  final NetworkController controller;

  DevToolsTab _buildTab({required String tabName, Widget? trailing}) {
    return DevToolsTab.create(
      tabName: tabName,
      gaPrefix: 'requestInspectorTab',
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NetworkRequest?>(
      valueListenable: controller.selectedRequest,
      builder: (context, data, _) {
        return RoundedOutlinedBorder(
          child: (data == null)
              ? Center(
                  child: Text(
                    'No request selected',
                    key: NetworkRequestInspector.noRequestSelectedKey,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              : AnalyticsTabbedView(
                  tabs: _generateTabs(data),
                  gaScreen: gac.network,
                ),
        );
      },
    );
  }

  List<({DevToolsTab tab, Widget tabView})> _generateTabs(
    NetworkRequest data,
  ) =>
      [
        (
          tab: _buildTab(tabName: NetworkRequestInspector._overviewTabTitle),
          tabView: NetworkRequestOverviewView(data),
        ),
        if (data is DartIOHttpRequestData) ...[
          (
            tab: _buildTab(tabName: NetworkRequestInspector._headersTabTitle),
            tabView: HttpRequestHeadersView(data),
          ),
          if (data.requestBody != null)
            (
              tab: _buildTab(
                tabName: NetworkRequestInspector._requestTabTitle,
                trailing: HttpViewTrailingCopyButton(
                  data,
                  (data) => data.requestBody,
                ),
              ),
              tabView: HttpRequestView(data),
            ),
          if (data.responseBody != null)
            (
              tab: _buildTab(
                tabName: NetworkRequestInspector._responseTabTitle,
                trailing: HttpViewTrailingCopyButton(
                  data,
                  (data) => data.responseBody,
                ),
              ),
              tabView: HttpResponseView(data),
            ),
          if (data.hasCookies)
            (
              tab: _buildTab(
                tabName: NetworkRequestInspector._cookiesTabTitle,
              ),
              tabView: HttpRequestCookiesView(data),
            ),
        ],
      ]
          .map(
            (t) => (
              tab: t.tab,
              tabView: OutlineDecoration.onlyTop(child: t.tabView),
            ),
          )
          .toList();
}
