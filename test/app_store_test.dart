import 'package:bodycare_home_service/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layanan keeps its backend mitra relationship', () {
    final service = Layanan.fromJson({
      'id': '10',
      'mitraId': '3',
      'name': 'Facial',
      'category': 'Facial',
      'duration': '60 menit',
      'price': 120000,
      'description': 'Perawatan wajah',
      'active': true,
    });

    expect(service.mitraId, '3');
    expect(service.price, 120000);
  });
}
