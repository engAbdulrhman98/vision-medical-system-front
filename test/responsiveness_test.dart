import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_medical_system_app/screens/login_screen.dart';
import 'package:vision_medical_system_app/screens/dashboard_screen.dart';
import 'package:vision_medical_system_app/screens/manager_dashboard.dart';
import 'package:vision_medical_system_app/screens/seller_dashboard.dart';
import 'package:vision_medical_system_app/screens/tasks_screen.dart';

void setScreenSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
}

final devices = [
  {'name': 'iPhone SE (Small Apple)', 'width': 375.0, 'height': 667.0},
  {'name': 'iPhone 15 Pro (Standard Apple)', 'width': 393.0, 'height': 852.0},
  {'name': 'iPhone 15 Pro Max (Large Apple)', 'width': 430.0, 'height': 932.0},
  {'name': 'Google Pixel 8 (Standard Android)', 'width': 412.0, 'height': 915.0},
  {'name': 'Samsung Galaxy S20 (Android)', 'width': 360.0, 'height': 800.0},
  {'name': 'iPad / Tablet', 'width': 768.0, 'height': 1024.0},
];

void main() {
  group('Screen responsiveness tests', () {
    for (var device in devices) {
      final name = device['name'] as String;
      final width = device['width'] as double;
      final height = device['height'] as double;

      testWidgets('Renders LoginScreen on $name ($width x $height)', (WidgetTester tester) async {
        setScreenSize(tester, width, height);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: LoginScreen(
            language: 'ar',
            onLanguageChanged: (lang) {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsAtLeast(1));
        expect(find.byType(ElevatedButton), findsAtLeast(1));
      });

      testWidgets('Renders DashboardScreen on $name ($width x $height)', (WidgetTester tester) async {
        setScreenSize(tester, width, height);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: DashboardScreen(
            language: 'ar',
            onLanguageChanged: (lang) {},
            email: 'admin@vision.com',
            user: const {'name': 'Super Admin', 'role': 'Admin'},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('Renders ManagerDashboard on $name ($width x $height)', (WidgetTester tester) async {
        setScreenSize(tester, width, height);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(
          home: ManagerDashboard(
            language: 'ar',
            token: 'mock',
            backendUrl: 'mock',
            user: {'name': 'Manager', 'role': 'Manager'},
          ),
        ));
        await tester.pump();

        expect(find.byType(ManagerDashboard), findsOneWidget);
      });

      testWidgets('Renders SellerDashboard on $name ($width x $height)', (WidgetTester tester) async {
        setScreenSize(tester, width, height);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(
          home: SellerDashboard(
            language: 'ar',
            token: 'mock',
            backendUrl: 'mock',
            user: {'name': 'Seller', 'role': 'Seller'},
          ),
        ));
        await tester.pump();

        expect(find.byType(SellerDashboard), findsOneWidget);
      });

      testWidgets('Renders TasksScreen on $name ($width x $height)', (WidgetTester tester) async {
        setScreenSize(tester, width, height);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(
          home: TasksScreen(language: 'ar'),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TasksScreen), findsOneWidget);
      });
    }
  });
}
