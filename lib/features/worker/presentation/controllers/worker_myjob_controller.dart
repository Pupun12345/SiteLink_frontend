import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY JOBS CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class MyJobsController extends GetxController {
  final isLoading = false.obs;

  // ── Vendor-posted requirements (available to apply) ────────────
  final availableJobs = <Map<String, dynamic>>[
    {
      'id': 'req_001',
      'role': 'Mason',
      'company': 'Rajesh Construction',
      'location': 'Vaishali Nagar, Jaipur',
      'rate': '₹650/day',
      'workers': 3,
      'duration': '30 days',
      'startDate': '25 Mar 2026',
      'urgent': true,
    },
    {
      'id': 'req_002',
      'role': 'Tile Worker',
      'company': 'Sharma Builders',
      'location': 'Malviya Nagar, Jaipur',
      'rate': '₹600/day',
      'workers': 5,
      'duration': '45 days',
      'startDate': '1 Apr 2026',
      'urgent': false,
    },
    {
      'id': 'req_003',
      'role': 'Helper',
      'company': 'Gupta Constructions',
      'location': 'Mansarovar, Jaipur',
      'rate': '₹450/day',
      'workers': 8,
      'duration': '60 days',
      'startDate': '28 Mar 2026',
      'urgent': true,
    },
    {
      'id': 'req_004',
      'role': 'Electrician',
      'company': 'Metro Infra Pvt Ltd',
      'location': 'Sitapura, Jaipur',
      'rate': '₹800/day',
      'workers': 2,
      'duration': '20 days',
      'startDate': '2 Apr 2026',
      'urgent': false,
    },
  ].obs;

  // ── Admin-assigned jobs ────────────────────────────────────────
  final jobs = <Map<String, dynamic>>[
    {
      'id': 'job_001',
      'role': 'Mason',
      'company': 'Rajesh Construction',
      'location': 'Jaipur',
      'rate': '₹650/day',
      'dates': '20 Mar – 20 Apr 2026',
      'status': 'active',
    },
    {
      'id': 'job_002',
      'role': 'Tile Worker',
      'company': 'Sharma Builders',
      'location': 'Jaipur',
      'rate': '₹600/day',
      'dates': '10 Jan – 10 Feb 2026',
      'status': 'completed',
    },
    {
      'id': 'job_003',
      'role': 'Helper',
      'company': 'Gupta Constructions',
      'location': 'Jaipur',
      'rate': '₹450/day',
      'dates': '01 Nov – 30 Nov 2025',
      'status': 'completed',
    },
  ].obs;

  List<Map<String, dynamic>> get activeJobs =>
      jobs.where((j) => j['status'] == 'active').toList();

  List<Map<String, dynamic>> get completedJobs =>
      jobs.where((j) => j['status'] == 'completed').toList();
}