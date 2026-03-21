import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATIONS VIEW — Screen 24
// ═══════════════════════════════════════════════════════════════════
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  final _notifs = const [
    {'type': 'job',    'title': 'New Job Offer / नया काम मिला',         'body': 'Mason job available in Jaipur — ₹650/day, 1 month', 'time': '2 hours ago',  'read': false},
    {'type': 'status', 'title': 'Workers Assigned / मज़दूर नियुक्त हुए', 'body': 'Your request #REQ-001 has been fulfilled with 5 workers.', 'time': '5 hours ago', 'read': false},
    {'type': 'admin',  'title': 'Admin Message / प्रशासन संदेश',         'body': 'Your profile has been verified. You are now active!', 'time': 'Yesterday',   'read': true},
    {'type': 'alert',  'title': 'Replacement Update / बदलाव अपडेट',     'body': 'Replacement worker Suresh has been assigned to your site.', 'time': '2 days ago', 'read': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: AppStrings.notifications,
        showBack: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(AppStrings.markAllRead,
                style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: 10),
            child: Row(
              children: ['All', 'Jobs', 'Status', 'Admin'].map((f) {
                final isFirst = f == 'All';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isFirst ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                        border: Border.all(
                          color: isFirst ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f,
                        textAlign: TextAlign.center,
                        style: KTextStyle.poppins(
                          fs: 12,
                          fw: FontWeight.w500,
                          c: isFirst ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimens.lg),
              itemCount: _notifs.length + 2, // +2 for section headers
              itemBuilder: (_, i) {
                if (i == 0) return _SectionLabel('Today / आज');
                if (i == 3) return _SectionLabel('Yesterday / कल');
                final ni = i <= 2 ? i - 1 : i - 2;
                if (ni >= _notifs.length) return const SizedBox.shrink();
                return _NotifCard(notif: _notifs[ni]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(label, style: KTextStyle.poppins(fs: 12, fw: FontWeight.bold, c: AppColors.textHint)),
      );
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final typeIcons = {
      'job':    (Icons.work_rounded,           AppColors.primary),
      'status': (Icons.check_circle_rounded,   AppColors.success),
      'admin':  (Icons.admin_panel_settings_rounded, AppColors.info),
      'alert':  (Icons.notifications_rounded,  AppColors.warning),
    };
    final t = typeIcons[notif['type']] ?? (Icons.notifications_outlined, AppColors.textSecondary);
    final unread = !(notif['read'] as bool);

    return Container(
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
                color: t.$2.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(t.$1, color: t.$2, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif['title']!,
                      style: KTextStyle.poppins(
                          fs: 13, fw: unread ? FontWeight.w600 : FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(notif['body']!,
                      style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(notif['time']!,
                      style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
                ],
              ),
            ),
            if (unread)
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
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
        title: AppStrings.profile,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
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
                      _ProfileStat('12', 'Requests'),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _ProfileStat('45', 'Workers\nHired'),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _ProfileStat('3', 'Active'),
                    ],
                  ),
                ],
              ),
            ),

            // Info card
            _InfoCard(title: 'Company Info', items: [
              (Icons.location_on_outlined,     'City',            'Jaipur, Rajasthan'),
              (Icons.phone_outlined,            'Phone',           '+91 98765 43210'),
              (Icons.business_center_outlined,  'GST',             'XXXXX12345'),
              (Icons.calendar_today_rounded,    'Member Since',    'March 2026'),
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
        title: AppStrings.profile,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
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

            _InfoCard(title: 'Personal Info', items: [
              (Icons.location_on_outlined,  'City',        'Jaipur, Rajasthan'),
              (Icons.phone_outlined,         'Phone',       '+91 98765 43210'),
              (Icons.work_history_outlined,  'Experience',  '5 Years'),
              (Icons.calendar_today_rounded, 'Member Since','March 2026'),
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
                      children: const [
                        SkillChip(label: 'Mason', selected: true),
                        SkillChip(label: 'Tile Worker', selected: true),
                        SkillChip(label: 'Helper', selected: true),
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
      (Icons.language_rounded,        AppStrings.language,    false),
      (Icons.notifications_rounded,   'Notifications',        true),
      (Icons.help_outline_rounded,    AppStrings.helpSupport, false),
      (Icons.info_outline_rounded,    AppStrings.aboutApp,    false),
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
                        onTap: item.$3 ? null : () => Get.to(() => const HelpView()),
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
            label: '🚪 ${AppStrings.logout}',
            isOutlined: true,
            onTap: () => Get.dialog(
              AlertDialog(
                title: Text('Logout?', style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
                content: Text('Are you sure you want to logout?',
                    style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {},
                    child: Text('Logout',
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
    ('When will I get workers? / मज़दूर कब मिलेंगे?',
     'We guarantee manpower within 24 hours of your request submission. Admin will contact you to confirm.'),
    ('How does replacement work? / बदलाव कैसे काम करता है?',
     'If a worker leaves or underperforms, tap Request Replacement on the assignment. We guarantee replacement within 48 hours.'),
    ('How do I verify my profile? / प्रोफाइल सत्यापन कैसे होगा?',
     'Upload your Aadhaar/Voter ID and work photos. Our admin reviews within 24–48 hours and approves your profile.'),
    ('What documents do I need? / कौन से दस्तावेज़ चाहिए?',
     'A valid Government ID (Aadhaar, Voter ID, or Driving Licence) and optionally photos of your past work.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.helpTitle),
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
                  Text('Need help? Talk to us!',
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
                          label: Text(AppStrings.callAdmin,
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
                          label: Text(AppStrings.whatsapp,
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

            Text(AppStrings.faqTitle,
                style: KTextStyle.poppins(fs: 14, fw: FontWeight.bold)),
            const SizedBox(height: AppDimens.md),

            // FAQ accordion
            ..._faqs.map((faq) => _FaqItem(q: faq.$1, a: faq.$2)),

            const SizedBox(height: AppDimens.xl),
            Center(
              child: CustomButton(
                label: '✉️ Email Support',
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
