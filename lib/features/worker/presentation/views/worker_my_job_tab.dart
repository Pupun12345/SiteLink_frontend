import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/worker_myjob_controller.dart';
import 'worker_job_detail_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  FILTER MODEL
// ═══════════════════════════════════════════════════════════════════
class JobFilterState {
  String sortBy;          // 'newest' | 'oldest' | 'highest_salary' | 'lowest_salary'
  String salaryType;      // '' | 'daily' | 'monthly'
  String jobType;         // '' | 'daily' | 'permanent'
  List<String> categories;

  JobFilterState({
    this.sortBy = 'newest',
    this.salaryType = '',
    this.jobType = '',
    List<String>? categories,
  }) : categories = categories ?? [];

  bool get hasActiveFilters =>
      sortBy != 'newest' ||
          salaryType.isNotEmpty ||
          jobType.isNotEmpty ||
          categories.isNotEmpty;

  JobFilterState copyWith({
    String? sortBy,
    String? salaryType,
    String? jobType,
    List<String>? categories,
  }) =>
      JobFilterState(
        sortBy: sortBy ?? this.sortBy,
        salaryType: salaryType ?? this.salaryType,
        jobType: jobType ?? this.jobType,
        categories: categories ?? List.from(this.categories),
      );

  JobFilterState reset() => JobFilterState();
}

// ═══════════════════════════════════════════════════════════════════
//  WORKER MY JOBS TAB
// ═══════════════════════════════════════════════════════════════════
class WorkerMyJobsTab extends StatefulWidget {
  const WorkerMyJobsTab({super.key});

  @override
  State<WorkerMyJobsTab> createState() => _WorkerMyJobsTabState();
}

class _WorkerMyJobsTabState extends State<WorkerMyJobsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late MyJobsController _ctrl;
  final _filterState = Rx<JobFilterState>(JobFilterState());
  final _searchQuery = ''.obs;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _isSearchFocused = false.obs;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(MyJobsController());
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchFocus.addListener(
            () => _isSearchFocused.value = _searchFocus.hasFocus);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Apply filter & sort ────────────────────────────────────────
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> source) {
    final fs = _filterState.value;
    final q = _searchQuery.value.toLowerCase().trim();

    var list = source.where((job) {
      // Search
      if (q.isNotEmpty) {
        final match = (job['role'] ?? '').toLowerCase().contains(q) ||
            (job['company'] ?? '').toLowerCase().contains(q) ||
            (job['location'] ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      // Salary type filter
      if (fs.salaryType.isNotEmpty && job['type'] != fs.salaryType) {
        return false;
      }
      // Job type filter
      if (fs.jobType.isNotEmpty && job['type'] != fs.jobType) {
        return false;
      }
      // Category / role filter
      if (fs.categories.isNotEmpty &&
          !fs.categories.contains(job['role'])) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    list.sort((a, b) {
      switch (fs.sortBy) {
        case 'oldest':
          return (a['id'] as String).compareTo(b['id'] as String);
        case 'highest_salary':
          return _salaryValue(b['rate']) - _salaryValue(a['rate']);
        case 'lowest_salary':
          return _salaryValue(a['rate']) - _salaryValue(b['rate']);
        case 'newest':
        default:
          return (b['id'] as String).compareTo(a['id'] as String);
      }
    });

    return list;
  }

  int _salaryValue(dynamic rate) {
    if (rate == null) return 0;
    final cleaned =
    rate.toString().replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildTabViews()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Text(
            'Jobs',
            style: KTextStyle.poppins(
                fs: 20, fw: FontWeight.w700, c: AppColors.textPrimary),
          ),
          const Spacer(),
          // Filter button
          Obx(() {
            final active = _filterState.value.hasActiveFilters;
            return GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: active
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      active ? 'Filtered' : 'Filter',
                      style: KTextStyle.poppins(
                        fs: 12,
                        fw: FontWeight.w600,
                        c: active
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _filterState.value =
                            _filterState.value.reset(),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Obx(() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isSearchFocused.value
              ? AppColors.surface
              : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isSearchFocused.value
                ? AppColors.primary
                : AppColors.divider,
            width: _isSearchFocused.value ? 1.5 : 1.0,
          ),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style:
          KTextStyle.poppins(fs: 13, c: AppColors.textPrimary),
          onChanged: (v) => _searchQuery.value = v,
          decoration: InputDecoration(
            hintText: 'Search by role, company, location...',
            hintStyle:
            KTextStyle.poppins(fs: 13, c: AppColors.textHint),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: _isSearchFocused.value
                  ? AppColors.primary
                  : AppColors.textHint,
            ),
            suffixIcon: _searchQuery.value.isNotEmpty
                ? GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _searchQuery.value = '';
                _searchFocus.unfocus();
              },
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textHint),
            )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      )),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle:
            KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
            unselectedLabelStyle: KTextStyle.poppins(fs: 13),
            tabs: [
              Tab(
                child: Obx(() {
                  final count =
                      _applyFilters(_ctrl.availableJobs).length;
                  return _TabLabel(
                      label: 'Available', count: count);
                }),
              ),
              Tab(
                child: Obx(() {
                  final count =
                      _applyFilters(_ctrl.appliedJobs).length;
                  return _TabLabel(
                      label: 'Applied / Assigned', count: count);
                }),
              ),
            ],
          ),
          Container(height: 0.5, color: AppColors.divider),
        ],
      ),
    );
  }

  // ── Tab Views ─────────────────────────────────────────────────
  Widget _buildTabViews() {
    return Obx(() {
      final available = _applyFilters(_ctrl.availableJobs);
      final applied = _applyFilters(_ctrl.appliedJobs);
      return TabBarView(
        controller: _tabCtrl,
        children: [
          _ctrl.isLoading.value && _ctrl.availableJobs.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _AvailableJobsList(jobs: available, onRefresh: _ctrl.fetchJobs),
          _ctrl.isLoadingApplied.value && _ctrl.appliedJobs.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _AppliedJobsList(
                  jobs: applied, onRefresh: _ctrl.fetchAppliedJobs),
        ],
      );
    });
  }

  // ── Filter Bottom Sheet ───────────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: _filterState.value,
        onApply: (newState) {
          _filterState.value = newState;
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB LABEL WITH COUNT BADGE
// ═══════════════════════════════════════════════════════════════════
class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  const _TabLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: KTextStyle.poppins(
                  fs: 10,
                  fw: FontWeight.w600,
                  c: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AVAILABLE JOBS LIST
// ═══════════════════════════════════════════════════════════════════
class _AvailableJobsList extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final Future<void> Function() onRefresh;
  const _AvailableJobsList({required this.jobs, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _EmptyState(
        icon: Icons.work_off_outlined,
        message: 'No available jobs right now',
        sub: 'Check back later for new openings',
        onRefresh: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AvailableJobCard(job: jobs[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APPLIED / ASSIGNED JOBS LIST
// ═══════════════════════════════════════════════════════════════════
class _AppliedJobsList extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final Future<void> Function() onRefresh;
  const _AppliedJobsList({required this.jobs, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        message: 'No applied jobs yet',
        sub: 'Apply to available jobs to see them here',
        onRefresh: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AppliedJobCard(job: jobs[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AVAILABLE JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _AvailableJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _AvailableJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isUrgent = job['urgent'] == true;
    final isDaily = job['type'] == 'daily';

    return GestureDetector(
      onTap: () => Get.to(() => WorkerJobDetailView(job: job)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card body ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — role + urgent
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job['role'] ?? '',
                          style: KTextStyle.poppins(
                              fs: 15,
                              fw: FontWeight.w700,
                              c: AppColors.textPrimary),
                        ),
                      ),
                      if (isUrgent) _UrgentBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    job['company'] ?? '',
                    style: KTextStyle.poppins(
                        fs: 13, c: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  // Info chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                          icon: Icons.location_on_outlined,
                          text: job['location'] ?? ''),
                      _InfoChip(
                          icon: Icons.people_outline_rounded,
                          text: '${job['workers']} needed'),
                      _InfoChip(
                          icon: Icons.timelapse_rounded,
                          text: job['duration'] ?? ''),
                      _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          text: job['startDate'] ?? ''),
                    ],
                  ),
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppDimens.radiusMd)),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Salary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['rate'] ?? '',
                        style: KTextStyle.poppins(
                          fs: 15,
                          fw: FontWeight.w800,
                          c: AppColors.success,
                        ),
                      ),
                      Text(
                        isDaily ? 'Daily rate' : 'Monthly salary',
                        style: KTextStyle.poppins(
                            fs: 10, c: AppColors.textHint),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDaily
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDaily ? 'Daily' : 'Permanent',
                      style: KTextStyle.poppins(
                        fs: 11,
                        fw: FontWeight.w600,
                        c: isDaily
                            ? Colors.orange.shade700
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Text('Apply',
                          style: KTextStyle.poppins(
                              fs: 12,
                              fw: FontWeight.w600,
                              c: AppColors.primary)),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APPLIED / ASSIGNED JOB CARD
// ═══════════════════════════════════════════════════════════════════
class _AppliedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _AppliedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['appStatus'] ?? 'applied';
    final isDaily = job['type'] == 'daily';

    return GestureDetector(
      onTap: () => Get.to(() => WorkerJobDetailView(job: job)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            // ── Left accent bar ────────────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusMd)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['role'] ?? '',
                              style: KTextStyle.poppins(
                                  fs: 15,
                                  fw: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job['company'] ?? '',
                              style: KTextStyle.poppins(
                                  fs: 13,
                                  c: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _AppStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Info row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job['location'] ?? '',
                          style: KTextStyle.poppins(
                              fs: 12, c: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        job['dates'] ?? '',
                        style: KTextStyle.poppins(
                            fs: 11, c: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),


                  Row(
                    children: [
                      Text(
                        job['rate'] ?? '',
                        style: KTextStyle.poppins(
                          fs: 15,
                          fw: FontWeight.w800,
                          c: AppColors.success,
                        ),
                      ),

                      const Spacer(),
                      Row(
                        children: [
                          Text('Details',
                              style: KTextStyle.poppins(
                                  fs: 12,
                                  fw: FontWeight.w500,
                                  c: AppColors.primary)),
                          const SizedBox(width: 2),
                          const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'shortlisted':
        return AppColors.info;
      case 'confirmed':
      case 'hired':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return Colors.orange;
      default:
        return AppColors.textHint;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APPLICATION STATUS BADGE
// ═══════════════════════════════════════════════════════════════════
class _AppStatusBadge extends StatelessWidget {
  final String status;
  const _AppStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg['icon'] as IconData,
              size: 11, color: cfg['fg'] as Color),
          const SizedBox(width: 4),
          Text(
            cfg['label'] as String,
            style: KTextStyle.poppins(
              fs: 10,
              fw: FontWeight.w600,
              c: cfg['fg'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _config(String status) {
    switch (status) {
      case 'pending':
        return {
          'label': 'Under Review',
          'icon': Icons.hourglass_top_rounded,
          'fg': Colors.orange.shade700,
          'bg': Colors.orange.withOpacity(0.1),
        };
      case 'shortlisted':
        return {
          'label': 'Shortlisted',
          'icon': Icons.star_rounded,
          'fg': AppColors.info,
          'bg': AppColors.info.withOpacity(0.1),
        };
      case 'confirmed':
        return {
          'label': 'Confirmed',
          'icon': Icons.check_circle_outline_rounded,
          'fg': AppColors.success,
          'bg': AppColors.success.withOpacity(0.1),
        };
      case 'hired':
        return {
          'label': 'Hired',
          'icon': Icons.verified_rounded,
          'fg': AppColors.success,
          'bg': AppColors.success.withOpacity(0.1),
        };
      case 'rejected':
        return {
          'label': 'Rejected',
          'icon': Icons.cancel_outlined,
          'fg': AppColors.error,
          'bg': AppColors.error.withOpacity(0.1),
        };
      default:
        return {
          'label': 'Applied',
          'icon': Icons.send_rounded,
          'fg': AppColors.textSecondary,
          'bg': AppColors.scaffoldBg,
        };
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
class _FilterSheet extends StatefulWidget {
  final JobFilterState current;
  final void Function(JobFilterState) onApply;

  const _FilterSheet({required this.current, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late JobFilterState _draft;

  final _sortOptions = const [
    {'key': 'newest', 'label': 'Newest First', 'icon': Icons.fiber_new_rounded},
    {'key': 'oldest', 'label': 'Oldest First', 'icon': Icons.history_rounded},
    {'key': 'highest_salary', 'label': 'Highest Salary', 'icon': Icons.trending_up_rounded},
    {'key': 'lowest_salary', 'label': 'Lowest Salary', 'icon': Icons.trending_down_rounded},
  ];

  final _salaryTypeOptions = const [
    {'key': 'daily', 'label': 'Daily Pay'},
    {'key': 'permanent', 'label': 'Monthly Pay'},
  ];

  final _categories = const [
    'Mason', 'Electrician', 'Carpenter', 'Plumber',
    'Painter', 'Welder', 'Helper', 'Tile Worker', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.current.copyWith();
  }

  int get _activeCount {
    int c = 0;
    if (_draft.sortBy != 'newest') c++;
    if (_draft.salaryType.isNotEmpty) c++;
    if (_draft.jobType.isNotEmpty) c++;
    c += _draft.categories.length;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text('Filter & Sort',
                      style: KTextStyle.poppins(
                          fs: 16, fw: FontWeight.w700)),
                  if (_activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_activeCount',
                          style: KTextStyle.poppins(
                              fs: 10,
                              fw: FontWeight.w700,
                              c: Colors.white)),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _draft = _draft.reset()),
                    child: Text('Clear All',
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: Colors.red.shade400)),
                  ),
                ],
              ),
            ),

            Container(
                height: 0.5,
                margin: const EdgeInsets.only(top: 10),
                color: AppColors.divider),

            // Scrollable content
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sort by ─────────────────────────────────
                    _FilterSectionTitle(title: 'Sort by'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sortOptions.map((opt) {
                        final sel = _draft.sortBy == opt['key'];
                        return _FilterChip(
                          label: opt['label'] as String,
                          icon: opt['icon'] as IconData,
                          selected: sel,
                          onTap: () => setState(
                                  () => _draft = _draft.copyWith(
                                  sortBy: opt['key'] as String)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── Salary Type ──────────────────────────────
                    _FilterSectionTitle(title: 'Salary Type'),
                    const SizedBox(height: 10),
                    Row(
                      children: _salaryTypeOptions.map((opt) {
                        final sel = _draft.salaryType == opt['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: opt['label'] as String,
                            selected: sel,
                            onTap: () => setState(() => _draft =
                                _draft.copyWith(
                                    salaryType: sel
                                        ? ''
                                        : opt['key'] as String)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── Category / Role ──────────────────────────
                    _FilterSectionTitle(title: 'Job Category'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = _draft.categories.contains(cat);
                        return _FilterChip(
                          label: cat,
                          selected: sel,
                          onTap: () {
                            setState(() {
                              final cats =
                              List<String>.from(_draft.categories);
                              sel
                                  ? cats.remove(cat)
                                  : cats.add(cat);
                              _draft =
                                  _draft.copyWith(categories: cats);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Apply button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                border:
                Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: CustomButton(
                label: _activeCount > 0
                    ? 'Apply Filters ($_activeCount)'
                    : 'Apply',
                onTap: () {
                  widget.onApply(_draft);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter section title ─────────────────────────────────────────
class _FilterSectionTitle extends StatelessWidget {
  final String title;
  const _FilterSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: KTextStyle.poppins(
          fs: 12, fw: FontWeight.w600, c: AppColors.textSecondary),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: KTextStyle.poppins(
                fs: 12,
                fw: selected ? FontWeight.w600 : FontWeight.normal,
                c: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(text,
            style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
      ],
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(AppDimens.radiusMax),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded,
            size: 11, color: Colors.red.shade600),
        const SizedBox(width: 2),
        Text('Urgent',
            style: KTextStyle.poppins(
                fs: 10,
                fw: FontWeight.w600,
                c: Colors.red.shade600)),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  final Future<void> Function() onRefresh;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    color: AppColors.primary,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle),
              child: Icon(icon,
                  size: 34, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            Text(message,
                style: KTextStyle.poppins(
                    fs: 14,
                    fw: FontWeight.w500,
                    c: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(sub,
                style: KTextStyle.poppins(
                    fs: 12, c: AppColors.textHint)),
          ],
        ),
      ),
    ),
  );
}