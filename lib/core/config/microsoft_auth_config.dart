import 'package:flutter/material.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:gea_app/config/router/app_router.dart';

class MicrosoftAuthConfig {

  static const String tenantId = String.fromEnvironment(
    'MS_TENANT_ID',
    defaultValue: '',
  );
  static const String clientId = String.fromEnvironment(
    'MS_CLIENT_ID',
    defaultValue: '',
  );

  static const String redirectUri = "";

  static final Config config = Config(
    tenant: tenantId,
    clientId: clientId,
    scope: "openid profile email offline_access",
    redirectUri: redirectUri,
    navigatorKey: navigatorKey,
    loader: const Center(child: CircularProgressIndicator()),
  );

  static final AadOAuth oauth = AadOAuth(config);
}
