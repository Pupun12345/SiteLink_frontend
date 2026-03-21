import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../shared/presentation/views/shared_views.dart';
import '../controllers/vendor_home_controller.dart';
import 'new_request_view.dart';
import 'my_requests_view.dart';
import 'request_detail_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR HOME VIEW
// ═══════════════════════════════════════════════════════════════════
class VendorHomeView extends StatelessWidget {
  const VendorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorHomeController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Obx(() => _body(ctrl)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const NewRequestView()),
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          AppStrings.newRequest,
          style: KTextStyle.poppins(
              fs: 14, fw: FontWeight.w600, c: Colors.white),
        ),
      ),
      bottomNavigationBar: Obx(() => _BottomNav(
        current: ctrl.tabIndex.value,
        onTap: ctrl.changeTab,
      )),
    );
  }

  Widget _body(VendorHomeController ctrl) {
    switch (ctrl.tabIndex.value) {
      case 1:
        return const MyRequestsView();
      case 2:
        return const _NotificationsTab();
      case 3:
        return const _ProfileTab();
      default:
        return _HomeTab(ctrl: ctrl);
    }
  }
}

// ── Home Tab ──────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VendorHomeController ctrl;
  const _HomeTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── App Bar ─────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: AppColors.appBarGradient),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.appName,
                style: KTextStyle.poppins(
                    fs: 20, fw: FontWeight.bold, c: Colors.white),
              ),
            ],
          ),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () => ctrl.changeTab(2),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle),
                    child: Text(
                      '3',
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(
                          fs: 9,
                          fw: FontWeight.bold,
                          c: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome strip ─────────────────────────────
              Container(
                margin: const EdgeInsets.all(AppDimens.lg),
                padding: const EdgeInsets.all(AppDimens.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusLg),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Rajesh Construction 👋',
                            style: KTextStyle.poppins(
                                fs: 15, fw: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your manpower partner / आपका मैनपावर पार्टनर',
                            style: KTextStyle.poppins(
                                fs: 12, c: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AvatarCircle(initials: 'RC', size: 44),
                  ],
                ),
              ),

              // ── Stats Row ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg),
                child: Row(
                  children: [
                    _StatCard(
                      label: AppStrings.activeRequests,
                      value: '3',
                      valueColor: AppColors.primary,
                      icon: Icons.assignment_outlined,
                    ),
                    const SizedBox(width: AppDimens.md),
                    _StatCard(
                      label: AppStrings.workersAssigned,
                      value: '12',
                      valueColor: AppColors.success,
                      icon: Icons.people_outline_rounded,
                    ),
                    const SizedBox(width: AppDimens.md),
                    _StatCard(
                      label: AppStrings.replacements,
                      value: '1',
                      valueColor: AppColors.warning,
                      icon: Icons.swap_horiz_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.xl),

              // ── Recent requests ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg),
                child: SectionHeader(
                  title: AppStrings.recentRequests,
                  actionLabel: AppStrings.viewAll,
                  onAction: () => ctrl.changeTab(1),
                ),
              ),
              const SizedBox(height: AppDimens.md),

              Obx(() => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg),
                itemCount: ctrl.recentRequests.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimens.md),
                itemBuilder: (_, i) =>
                    _RequestCard(request: ctrl.recentRequests[i]),
              )),

              const SizedBox(height: 100), // FAB clearance
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
          BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: valueColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: valueColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: KTextStyle.poppins(
                  fs: 24, fw: FontWeight.bold, c: valueColor),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: KTextStyle.poppins(
                  fs: 10, c: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusMap = {
      'active': BadgeType.active,
      'pending': BadgeType.pending,
      'fulfilled': BadgeType.fulfilled,
    };

    return AppCard(
      showLeftBorder: true,
      onTap: () => Get.to(() => RequestDetailView(request: request)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkillChip(
                  label: request['role'] ?? '', selected: true),
              const Spacer(),
              StatusBadge(
                  type: statusMap[request['status']] ??
                      BadgeType.pending),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${request['qty']} Workers',
                style: KTextStyle.poppins(
                    fs: 12, c: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request['location'] ?? '',
                  style: KTextStyle.poppins(
                      fs: 12, c: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                request['date'] ?? '',
                style: KTextStyle.poppins(
                    fs: 11, c: AppColors.textHint),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'View Details',
                    style: KTextStyle.poppins(
                        fs: 12,
                        fw: FontWeight.w500,
                        c: AppColors.primary),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Placeholder Tabs ──────────────────────────────────────────────
class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();
  @override
  Widget build(BuildContext context) => const NotificationsView();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const VendorProfileView();
}

// ── Bottom Nav ────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.assignment_rounded, Icons.assignment_outlined,
      'Requests'),
      (Icons.notifications_rounded, Icons.notifications_outlined,
      'Alerts'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
        Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimens.bottomNavH,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? items[i].$1 : items[i].$2,
                        color: active
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        style: KTextStyle.poppins(
                          fs: 10,
                          c: active
                              ? AppColors.primary
                              : AppColors.textHint,
                          fw: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}