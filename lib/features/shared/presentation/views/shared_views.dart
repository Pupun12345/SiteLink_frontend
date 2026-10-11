import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/models/notification_models.dart';
import '../controllers/notifications_controller.dart';
import '../../../../core/services/logout_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATIONS VIEW — Screen 24
// ═══════════════════════════════════════════════════════════════════
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared singleton (Home badge isi instance ka unreadCount dikhata hai)
    // — tab khulte hi latest list refresh ho jaaye.
    final ctrl = NotificationsController.to;
    ctrl.fetchNotifications();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: AppStrings.Notifications,
        showBack: false,
        actions: [
          TextButton(
            onPressed: ctrl.markAllRead,
            child: Text(AppStrings.MarkAllRead,
                style: KTextStyle.poppins(
                    fs: 12, fw: FontWeight.w500, c: AppColors.primary)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (ctrl.notifications.isEmpty) {
            return const _EmptyNotifications();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.fetchNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimens.lg),
              itemCount: ctrl.notifications.length,
              itemBuilder: (_, i) {
                final n = ctrl.notifications[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => ctrl.deleteNotification(n.id),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppDimens.md),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  child: _NotifCard(
                    notif: n,
                    onTap: () => ctrl.onTapNotification(n),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.notifications_off_outlined,
                  size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            Text('no_notifications_label'.tr,
                style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary)),
          ],
        ),
      );
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const typeIcons = {
      'job_approved':      (Icons.check_circle_rounded, AppColors.success),
      'job_rejected':      (Icons.cancel_rounded, AppColors.error),
      'new_application':   (Icons.work_rounded, AppColors.primary),
      'application_status':(Icons.assignment_turned_in_rounded, AppColors.info),
      'new_comment':       (Icons.chat_bubble_rounded, AppColors.secondary),
      'vendor_verified':   (Icons.verified_rounded, AppColors.success),
      'vendor_rejected':   (Icons.report_rounded, AppColors.error),
    };
    final t = typeIcons[notif.type] ??
        (Icons.notifications_outlined, AppColors.textSecondary);
    final unread = !notif.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.md),
        decoration: BoxDecoration(
          color: unread ? AppColors.selectionBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: unread
              ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
              : null,
          boxShadow: AppColors.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: t.$2.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(t.$1, color: t.$2, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: KTextStyle.poppins(
                            fs: 13, fw: unread ? FontWeight.w600 : FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(notif.body,
                        style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_timeAgo(notif.createdAt),
                        style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
                  ],
                ),
              ),
              if (unread)
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  VENDOR PROFILE VIEW — Screen 25
// ═══════════════════════════════════════════════════════════════════
class VendorProfileView extends StatelessWidget {
  const VendorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: AppStrings.Profile,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Container(
              margin: const EdgeInsets.all(AppDimens.lg),
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  AvatarCircle(initials: 'RC', size: 80, fontSize: 24),
                  const SizedBox(height: 12),
                  Text('Rajesh Construction',
                      style: KTextStyle.poppins(fs: 18, fw: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.selectionBg,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                    ),
                    child: Text('🏢 Vendor / ठेकेदार',
                        style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600, c: AppColors.primary)),
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileStat('12', 'nav_requests'.tr),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _ProfileStat('45', 'workers_hired_label'.tr),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _ProfileStat('3', 'active_status_label'.tr),
                    ],
                  ),
                ],
              ),
            ),

            // Info card
            _InfoCard(title: 'company_info_section'.tr, items: [
              (Icons.location_on_outlined,     AppStrings.City,        'Jaipur, Rajasthan'),
              (Icons.phone_outlined,            'phone_label'.tr,       '+91 98765 43210'),
              (Icons.business_center_outlined,  'gst_label'.tr,         'XXXXX12345'),
              (Icons.calendar_today_rounded,    'member_since_label'.tr,'March 2026'),
            ]),

            // Settings card
            _SettingsCard(),

            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE VIEW — Screen 26
// ═══════════════════════════════════════════════════════════════════
class WorkerProfileView extends StatelessWidget {
  const WorkerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: AppStrings.Profile,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppDimens.lg),
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      AvatarCircle(initials: 'RK', size: 80, fontSize: 24),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Ramesh Kumar', style: KTextStyle.poppins(fs: 18, fw: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                    ),
                    child: Text('👷 Worker | ✓ Verified',
                        style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600, c: AppColors.success)),
                  ),
                  const SizedBox(height: 12),
                  Text('SL-WRK-2024-004', style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
                ],
              ),
            ),

            _InfoCard(title: 'personal_info_section'.tr, items: [
              (Icons.location_on_outlined,  AppStrings.City,        'Jaipur, Rajasthan'),
              (Icons.phone_outlined,         'phone_label'.tr,       '+91 98765 43210'),
              (Icons.work_history_outlined,  'experience_label'.tr,  '5 Years'),
              (Icons.calendar_today_rounded, 'member_since_label'.tr,'March 2026'),
            ]),
SizedBox(height: 15,),
            // Skills chip card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Skills / मेरे कौशल',
                        style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        SkillChip(label: 'skill_mason'.tr, selected: true),
                        SkillChip(label: 'skill_tile_worker'.tr, selected: true),
                        SkillChip(label: 'skill_helper'.tr, selected: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),

            _SettingsCard(),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: KTextStyle.poppins(fs: 22, fw: FontWeight.bold, c: AppColors.primary)),
          Text(label, style: KTextStyle.poppins(fs: 11, c: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(IconData, String, String)> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
              const SizedBox(height: AppDimens.md),
              ...items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(i.$1, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('${i.$2}:',
                            style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500,
                                c: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(i.$3,
                              style: KTextStyle.poppins(fs: 13)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.language_rounded,        AppStrings.Language,    false),
      (Icons.notifications_rounded,   AppStrings.Notifications, true),
      (Icons.help_outline_rounded,    AppStrings.HelpSupport, false),
      (Icons.info_outline_rounded,    AppStrings.AboutSiteLink,    false),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ...items.map((item) {
                  final isLast = item == items.last;
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(item.$1, color: AppColors.primary, size: 22),
                        title: Text(item.$2, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w500)),
                        trailing: item.$3
                            ? Switch(
                                value: true,
                                activeColor: AppColors.primary,
                                onChanged: (_) {},
                              )
                            : const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textHint),
                        onTap: item.$3 ? null : () => Get.toNamed(AppRoutes.help),
                      ),
                      if (!isLast)
                        const Divider(height: 0, indent: 52, color: AppColors.divider),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),
          CustomButton(
            label: '🚪 ${AppStrings.Logout}',
            isOutlined: true,
            onTap: () => Get.dialog(
              AlertDialog(
                title: Text('logout_confirm_title'.tr, style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
                content: Text('logout_confirm_message'.tr,
                    style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
                actions: [
                  TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
                  TextButton(
                    // Dialog band karna + guard + loader performLogout me.
                    onPressed: performLogout,
                    child: Text(AppStrings.Logout,
                        style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600, c: AppColors.error)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELP & SUPPORT VIEW — Screen 27
// ═══════════════════════════════════════════════════════════════════
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  final _faqs = const [
    ('How do I post a manpower request? / मैनपावर अनुरोध कैसे करें?',
     'Go to Home > tap the orange + button > fill the form with role, quantity, location and timeline > Submit.'),
    ('When will I get employees / workers? / कर्मचारी / वर्कर कब मिलेंगे?',
     'We guarantee manpower within 24 hours of your request submission. Admin will contact you to confirm.'),
    ('How does replacement work? / बदलाव कैसे काम करता है?',
     'If an employee / worker leaves or underperforms, tap Request Replacement on the assignment. We guarantee replacement within 48 hours.'),
    ('How do I verify my profile? / प्रोफाइल सत्यापन कैसे होगा?',
     'Upload your Aadhaar/Voter ID and work photos. Our admin reviews within 24–48 hours and approves your profile.'),
    ('What documents do I need? / कौन से दस्तावेज़ चाहिए?',
     'A valid Government ID (Aadhaar, Voter ID, or Driving Licence) and optionally photos of your past work.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.HelpSupport),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact banner
            Container(
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              ),
              child: Column(
                children: [
                  Text('need_help_talk_to_us'.tr,
                      style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600, c: Colors.white),
                      textAlign: TextAlign.center),
                  Text('मदद चाहिए? हमसे बात करें!',
                      style: KTextStyle.poppins(fs: 12, c: Colors.white.withOpacity(0.8)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(AppStrings.CallAdmin,
                              style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600,
                                  c: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF25D366),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: Text(AppStrings.WhatsApp,
                              style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600,
                                  c: const Color(0xFF25D366))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xl),

            Text(AppStrings.FrequentlyAskedQuestions,
                style: KTextStyle.poppins(fs: 14, fw: FontWeight.bold)),
            const SizedBox(height: AppDimens.md),

            // FAQ accordion
            ..._faqs.map((faq) => _FaqItem(q: faq.$1, a: faq.$2)),

            const SizedBox(height: AppDimens.xl),
            Center(
              child: CustomButton(
                label: '✉️ ${'email_support_label'.tr}',
                isOutlined: true,
                onTap: () {},
                width: 200,
              ),
            ),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String q, a;
  const _FaqItem({required this.q, required this.a});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.q,
                        style: KTextStyle.poppins(
                            fs: 13,
                            fw: _expanded ? FontWeight.w600 : FontWeight.normal,
                            c: _expanded ? AppColors.primary : AppColors.textPrimary)),
                  ),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.md, 0, AppDimens.md, AppDimens.md),
                child: Text(widget.a,
                    style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary, height: 1.5)),
              ),
          ],
        ),
      ),
    );
  }
}
