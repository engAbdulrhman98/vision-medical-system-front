import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const String backendUrl = 'http://127.0.0.1:8080/api';

  group('Backend Connection and API Integration Tests', () {
    
    test('1. Verify backend server is running and settings endpoint is accessible', () async {
      try {
        final response = await http.get(
          Uri.parse('$backendUrl/settings'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        expect(response.statusCode, 200);
        final data = jsonDecode(response.body);
        
        // Assert settings structure has some expected key or is at least a map/list
        expect(data, isNotNull);
        print('Backend is reachable. Settings response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      } catch (e) {
        fail('Failed to connect to backend at $backendUrl: $e\nMake sure the backend server (php artisan serve) is running!');
      }
    });

    test('2. Verify login API works with valid admin credentials', () async {
      final response = await http.post(
        Uri.parse('$backendUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'admin@vision-medical.com',
          'password': 'admin123',
        }),
      ).timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200, reason: 'Login failed with status: ${response.statusCode}. Response: ${response.body}');
      
      final data = jsonDecode(response.body);
      expect(data['access_token'], isNotEmpty, reason: 'Access token should be returned');
      expect(data['user'], isNotNull, reason: 'User details should be returned');
      expect(data['user']['email'], 'admin@vision-medical.com');
      
      final roles = data['user']['roles'] as List?;
      expect(roles, isNotNull);
      expect(roles!.isNotEmpty, true);
      print('Login test passed! User: ${data['user']['name']} has role: ${roles[0]['name']}');
    });

    test('3. Verify login API returns 422/error for incorrect credentials', () async {
      final response = await http.post(
        Uri.parse('$backendUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'admin@vision-medical.com',
          'password': 'wrong_password_here',
        }),
      ).timeout(const Duration(seconds: 5));

      expect(response.statusCode, 422, reason: 'Wrong password should fail with validation error');
      
      final data = jsonDecode(response.body);
      expect(data['errors'] ?? data['message'], isNotNull, reason: 'Should return validation errors or error message');
      print('Invalid login rejected correctly with message: ${data['message']}');
    });

    test('4. Verify public categories endpoint works', () async {
      final response = await http.get(
        Uri.parse('$backendUrl/categories'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      final categoriesResponse = jsonDecode(response.body);
      if (categoriesResponse is List) {
        print('Categories count: ${categoriesResponse.length}');
      } else if (categoriesResponse is Map && categoriesResponse['data'] != null) {
        expect(categoriesResponse['data'], isList);
        print('Categories count (wrapped): ${categoriesResponse['data'].length}');
      } else {
        fail('Unexpected categories response structure');
      }
    });

    test('5. Verify public products endpoint works', () async {
      final response = await http.get(
        Uri.parse('$backendUrl/products'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      final productsResponse = jsonDecode(response.body);
      // Depending on pagination structure, it might be a list or a map with data
      if (productsResponse is List) {
        print('Products count: ${productsResponse.length}');
      } else if (productsResponse is Map && productsResponse['data'] != null) {
        expect(productsResponse['data'], isList);
        print('Products count (paginated): ${productsResponse['data'].length}');
      } else {
        fail('Unexpected products response structure');
      }
    });

  });
}
