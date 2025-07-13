import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_page.dart';
import 'package:gloria_marketing_flutter/src/features/auth/presentation/pages/login_page.dart';
import 'package:gloria_marketing_flutter/src/features/forwarder/presentation/pages/forwarder_home_page.dart';

class AppRouter {
  static const String loginRoute = '/';
  static const String agentHomeRoute = '/agent-home';
  static const String bossHomeRoute = '/boss-home';
  static const String forwarderHomeRoute = '/forwarder-home';
  // Add other routes here

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case agentHomeRoute:
        return MaterialPageRoute(builder: (_) => const AgentHomePage());
      case bossHomeRoute:
        // Replace with actual Boss Home Page
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Boss Home'))));
      case forwarderHomeRoute:
        return MaterialPageRoute(builder: (_) => const ForwarderHomePage());
      // Add other cases here
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}