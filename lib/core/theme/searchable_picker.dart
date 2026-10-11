import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  SEARCHABLE PICKER — dropdown-style field + searchable bottom sheet
// ═══════════════════════════════════════════════════════════════════
// Lambi lists (skills, states, cities) me plain DropdownButton se scroll
// karna practical nahi hai. Field dikhne me dropdown jaisa hi rehta hai,
// par tap karne par bottom sheet khulta hai jisme search box + हमेशा
// alphabetically sorted list hoti hai. Single aur multi-select dono.

/// Ek option — `value` code ke liye, `label` user ko dikhta hai.
class PickerOption<T> {
  final T value;
  final String label;
  const PickerOption({required this.value, required this.label});
}

// ── Trigger field (dropdown jaisa dikhta hai) ──────────────────────
class SearchablePickerField extends StatelessWidget {
  final String hint;
  final String? label; // selected text; null/empty = kuch select nahi
  final VoidCallback? onTap;
  final IconData? icon;
  final int? badgeCount; // multi-select me kitne chune hain

  const SearchablePickerField({
    super.key,
    required this.hint,
    this.label,
    this.onTap,
    this.icon,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = (label ?? '').isNotEmpty;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.textHint),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                hasValue ? label! : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KTextStyle.poppins(
                  fs: 13,
                  c: hasValue ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            if ((badgeCount ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${badgeCount!}',
                    style: KTextStyle.poppins(
                        fs: 11, fw: FontWeight.w600, c: AppColors.primary)),
              ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Public API ─────────────────────────────────────────────────────

/// Single-select searchable sheet. Chuni hui value return karti hai;
/// dismiss/cancel par null.
Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  T? selected,
  String? searchHint,
}) async {
  final result = await showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchableSheet<T>(
      title: title,
      options: options,
      searchHint: searchHint,
      initial: selected == null ? const [] : [selected],
      multiSelect: false,
    ),
  );
  if (result == null || result.isEmpty) return null;
  return result.first;
}

/// Multi-select searchable sheet. "Done" par chuni hui values return
/// hoti hain; dismiss par null (matlab koi change nahi).
Future<List<T>?> showSearchableMultiPicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  List<T> selected = const [],
  String? searchHint,
}) {
  return showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchableSheet<T>(
      title: title,
      options: options,
      searchHint: searchHint,
      initial: selected,
      multiSelect: true,
    ),
  );
}

// ── Sheet ──────────────────────────────────────────────────────────
class _SearchableSheet<T> extends StatefulWidget {
  final String title;
  final List<PickerOption<T>> options;
  final List<T> initial;
  final bool multiSelect;
  final String? searchHint;

  const _SearchableSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.multiSelect,
    this.searchHint,
  });

  @override
  State<_SearchableSheet<T>> createState() => _SearchableSheetState<T>();
}

class _SearchableSheetState<T> extends State<_SearchableSheet<T>> {
  final _searchCtrl = TextEditingController();
  late final List<T> _selected = List<T>.from(widget.initial);
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Hamesha alphabetical. Search hone par jo options query se *shuru*
  /// hote hain wo upar aate hain, baaki (jinme query beech me hai) neeche
  /// — dono groups apne andar alphabetical hi rehte hain.
  List<PickerOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = widget.options
        .where((o) => q.isEmpty || o.label.toLowerCase().contains(q))
        .toList();
    list.sort((a, b) {
      final al = a.label.toLowerCase();
      final bl = b.label.toLowerCase();
      if (q.isNotEmpty) {
        final aStarts = al.startsWith(q);
        final bStarts = bl.startsWith(q);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
      }
      return al.compareTo(bl);
    });
    return list;
  }

  void _onTapOption(PickerOption<T> o) {
    if (!widget.multiSelect) {
      Navigator.pop(context, <T>[o.value]);
      return;
    }
    setState(() {
      _selected.contains(o.value)
          ? _selected.remove(o.value)
          : _selected.add(o.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Grab handle ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // ── Title + (multi) clear all ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.lg, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: KTextStyle.poppins(
                            fs: 15, fw: FontWeight.w700)),
                  ),
                  if (widget.multiSelect && _selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text('clear_all_label'.tr,
                          style: KTextStyle.poppins(
                              fs: 12,
                              fw: FontWeight.w600,
                              c: AppColors.error)),
                    ),
                ],
              ),
            ),

            // ── Search ─────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: KTextStyle.poppins(fs: 13),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'search_label'.tr,
                  hintStyle:
                      KTextStyle.poppins(fs: 13, c: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textHint),
                  suffixIcon: _query.isEmpty
                      ? null
                      : GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textHint),
                        ),
                  filled: true,
                  fillColor: AppColors.scaffoldBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),

            // ── Options ────────────────────────────────────────────
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text('no_results_found'.tr,
                          style: KTextStyle.poppins(
                              fs: 13, c: AppColors.textHint)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final o = filtered[i];
                        final isSelected = _selected.contains(o.value);
                        return InkWell(
                          onTap: () => _onTapOption(o),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.lg, vertical: 13),
                            child: Row(
                              children: [
                                if (widget.multiSelect)
                                  _Checkbox(selected: isSelected)
                                else
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 19,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    o.label,
                                    style: KTextStyle.poppins(
                                      fs: 13,
                                      fw: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      c: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Done (sirf multi-select me) ────────────────────────
            if (widget.multiSelect) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, List<T>.from(_selected)),
                      child: Text('done_label'.tr),
                    ),
                  ),
                ),
              ),
            ] else
              SafeArea(top: false, child: const SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool selected;
  const _Checkbox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
