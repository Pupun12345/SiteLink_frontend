import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import 'request_detail_view.dart';
import 'new_request_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  MY REQUESTS VIEW
// ═══════════════════════════════════════════════════════════════════
class MyRequestsView extends StatefulWidget {
  const MyRequestsView({super.key});

  @override
  State<MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<MyRequestsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Pending', 'Active', 'Fulfilled', 'Replaced'];

  final _allRequests = [
    {
      'role': 'Mason',
      'qty': 5,
      'location': 'Vaishali Nagar, Jaipur',
      'date': '20 Mar 2026',
      'duration': '1 Month',
      'status': 'active',
      'id': '#REQ-001',
    },
    {
      'role': 'Carpenter',
      'qty': 3,
      'location': 'Mansarovar, Jaipur',
      'date': '22 Mar 2026',
      'duration': '2 Weeks',
      'status': 'pending',
      'id': '#REQ-002',
    },
    {
      'role': 'Plumber',
      'qty': 2,
      'location': 'C-Scheme, Jaipur',
      'date': '15 Feb 2026',
      'duration': '1 Month',
      'status': 'fulfilled',
      'id': '#REQ-003',
    },
    {
      'role': 'Electrician',
      'qty': 4,
      'location': 'Jagatpura, Jaipur',
      'date': '10 Jan 2026',
      'duration': '3 Months',
      'status': 'replaced',
      'id': '#REQ-004',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final tab = _tabs[_tabCtrl.index];
    if (tab == 'All') return _allRequests;
    return _allRequests
        .where((r) => r['status'] == tab.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: 'My Requests',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white),
            onPressed: () => Get.to(() => const NewRequestView()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Filter Tabs ──────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.lg, vertical: 10),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.only(right: 8),
                dividerHeight: 0,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorPadding: EdgeInsets.zero,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                KTextStyle.poppins(fs: 12, fw: FontWeight.w600),
                unselectedLabelStyle: KTextStyle.poppins(fs: 12),
                tabs: _tabs.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(t),
                  );
                }).toList(),
                onTap: (_) => setState(() {}),
              ),
            ),

            // ── List ─────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _tabCtrl,
                builder: (_, __) {
                  final items = _filtered;
                  if (items.isEmpty) return const _EmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimens.md),
                    itemBuilder: (_, i) =>
                        _RequestListCard(request: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request List Card ─────────────────────────────────────────────
class _RequestListCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestListCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final statusMap = {
      'active': (BadgeType.active, AppColors.primary),
      'pending': (BadgeType.pending, AppColors.warning),
      'fulfilled': (BadgeType.fulfilled, AppColors.success),
      'replaced': (BadgeType.replaced, AppColors.error),
    };
    final statusData =
        statusMap[request['status']] ?? (BadgeType.pending, AppColors.warning);

    return AppCard(
      showLeftBorder: true,
      leftBorderColor: statusData.$2,
      onTap: () => Get.to(() => RequestDetailView(request: request)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role + Status
          Row(
            children: [
              SkillChip(label: request['role'] ?? '', selected: true),
              const Spacer(),
              StatusBadge(type: statusData.$1),
            ],
          ),
          const SizedBox(height: 6),

          // ID
          Text(
            request['id'] ?? '',
            style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
          ),
          const SizedBox(height: 8),

          // Workers + Location
          // FIX: _MiniInfoInline never wraps itself in Expanded.
          // The outer Expanded here is the ONLY Expanded in this Row.
          Row(
            children: [
              _MiniInfoInline(
                icon: Icons.people_outline_rounded,
                text: '${request['qty']} Workers',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniInfoInline(
                  icon: Icons.location_on_outlined,
                  text: request['location'] ?? '',
                  ellipsis: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Date + Duration
          Row(
            children: [
              _MiniInfoInline(
                icon: Icons.calendar_today_rounded,
                text: request['date'] ?? '',
                small: true,
              ),
              const SizedBox(width: 10),
              _MiniInfoInline(
                icon: Icons.timelapse_rounded,
                text: request['duration'] ?? '',
                small: true,
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'View Details',
                style: KTextStyle.poppins(
                    fs: 12, fw: FontWeight.w500, c: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _MiniInfoInline ───────────────────────────────────────────────
// IMPORTANT: This widget NEVER wraps itself in Expanded.
// When the caller needs it to fill remaining space, the caller
// wraps it in Expanded. This prevents the "competing Expanded" error
// that occurs when an Expanded is nested inside another Expanded.
class _MiniInfoInline extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool ellipsis;
  final bool small;

  const _MiniInfoInline({
    required this.icon,
    required this.text,
    this.ellipsis = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: small ? 12 : 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        if (ellipsis)
        // Flexible shrinks/grows within the parent Row's remaining space.
        // The parent Row must already be constrained (e.g. inside Expanded).
          Flexible(
            child: Text(
              text,
              style: KTextStyle.poppins(
                fs: small ? 11 : 12,
                c: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(
            text,
            style: KTextStyle.poppins(
              fs: small ? 11 : 12,
              c: small ? AppColors.textHint : AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined,
                  size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'No requests yet',
              style: KTextStyle.poppins(
                  fs: 15,
                  fw: FontWeight.w600,
                  c: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Post New Request',
              onTap: () => Get.to(() => const NewRequestView()),
              width: 240,
            ),
          ],
        ),
      ),
    );
  }
}