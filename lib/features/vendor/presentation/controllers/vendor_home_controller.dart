import 'package:get/get.dart';

class VendorHomeController extends GetxController {
  final tabIndex = 0.obs;

  final recentRequests = <Map<String, dynamic>>[
    {'role': 'Mason / राजमिस्त्री', 'qty': 5, 'location': 'Vaishali Nagar, Jaipur', 'date': 'Starting 20 Mar 2026', 'status': 'active'},
    {'role': 'Carpenter / बढ़ई',    'qty': 3, 'location': 'Mansarovar, Jaipur',      'date': 'Starting 22 Mar 2026', 'status': 'pending'},
    {'role': 'Plumber / प्लंबर',   'qty': 2, 'location': 'C-Scheme, Jaipur',         'date': 'Starting 25 Mar 2026', 'status': 'fulfilled'},
  ].obs;

  void changeTab(int index) => tabIndex.value = index;
}
