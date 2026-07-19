import 'package:get/get.dart';
import '../../../../core/services/notification_service.dart';

class VendorHomeController extends GetxController {
  final tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    HomeTabSwitcher.register(changeTab);
  }

  @override
  void onClose() {
    HomeTabSwitcher.unregister(changeTab);
    super.onClose();
  }

  // ── Recent Requests (from API in real app) ───────────────────────
  final recentRequests = <Map<String, dynamic>>[
    {
      'id': '#REQ-001',
      'role': 'Mason',
      'qty': 5,
      'location': 'Vaishali Nagar, Jaipur',
      'date': 'Starting 20 Mar 2026',
      'status': 'active',
    },
    {
      'id': '#REQ-002',
      'role': 'Carpenter',
      'qty': 3,
      'location': 'Mansarovar, Jaipur',
      'date': 'Starting 22 Mar 2026',
      'status': 'pending',
    },
    {
      'id': '#REQ-003',
      'role': 'Plumber',
      'qty': 2,
      'location': 'C-Scheme, Jaipur',
      'date': 'Starting 25 Mar 2026',
      'status': 'fulfilled',
    },
  ].obs;

  // ── Community Feed Posts (from API in real app) ──────────────────
  final feedPosts = <Map<String, dynamic>>[
    {
      'workerId': 'WRK-001',
      'workerName': 'Ramesh Kumar',
      'initials': 'RK',
      'skill': 'Mason',
      'location': 'Jaipur',
      'description':
      'Completed a wall plastering project in Vaishali Nagar. 3 days, smooth finish. Available for new projects.',
      'imageUrl': null,
      'likesCount': 14,
      'isLiked': false,
      'experience': '5 yrs',
      'rating': 4.6,
      'timeAgo': '2d ago',
    },
    {
      'workerId': 'WRK-002',
      'workerName': 'Suresh Yadav',
      'initials': 'SY',
      'skill': 'Carpenter',
      'location': 'Jaipur',
      'description':
      'Installed wooden flooring and door frames for a 3BHK flat. Quality work guaranteed. Looking for projects in Mansarovar area.',
      'imageUrl': null,
      'likesCount': 9,
      'isLiked': false,
      'experience': '8 yrs',
      'rating': 4.8,
      'timeAgo': '1d ago',
    },
    {
      'workerId': 'WRK-003',
      'workerName': 'Dinesh Meena',
      'initials': 'DM',
      'skill': 'Electrician',
      'location': 'Jaipur',
      'description':
      'Completed full electrical wiring for a commercial building in C-Scheme. Licensed electrician, 10+ years experience.',
      'imageUrl': null,
      'likesCount': 21,
      'isLiked': true,
      'experience': '10 yrs',
      'rating': 4.9,
      'timeAgo': '3h ago',
    },
  ].obs;

  void changeTab(int index) => tabIndex.value = index;

  void toggleLike(int index) {
    final post = Map<String, dynamic>.from(feedPosts[index]);
    final isLiked = post['isLiked'] as bool;
    post['isLiked'] = !isLiked;
    post['likesCount'] =
        (post['likesCount'] as int) + (isLiked ? -1 : 1);
    feedPosts[index] = post;
  }
}