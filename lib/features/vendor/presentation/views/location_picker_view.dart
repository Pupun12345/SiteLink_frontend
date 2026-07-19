import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/places_api_service.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOCATION PICKER — search (Places API) + drag-map-under-fixed-pin
// ═══════════════════════════════════════════════════════════════════
// Job posting ke "Site Location" section se khula jaata hai. Current
// location (permission mil jaaye to) se camera start hota hai, warna
// ek fixed default center pe. Vendor ya to upar search karke jagah
// dhund sakta hai (Google Places autocomplete), ya map ghuma ke khud
// position kar sakta hai; center ka pin fixed rehta hai (industry-
// standard "confirm delivery location" pattern).
class LocationPickerView extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerView({super.key, this.initial});

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  // Jaipur — sample/default city jab tak GPS na mile ya vendor kahin
  // aur na le jaaye.
  static const _fallbackCenter = LatLng(26.9124, 75.7873);

  final _placesApi = PlacesApiService();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _sessionToken = _newSessionToken();

  GoogleMapController? _mapController;
  LatLng _center = _fallbackCenter;
  bool _loadingLocation = true;
  bool _searching = false;
  List<PlaceSuggestion> _suggestions = [];
  String? _pickedAddress; // search se select kiya to uska label

  static String _newSessionToken() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _center = widget.initial!;
      _loadingLocation = false;
    } else {
      _loadCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (result.hasPosition) {
      final pos = LatLng(
          result.position!.latitude, result.position!.longitude);
      setState(() {
        _center = pos;
        _loadingLocation = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    } else {
      setState(() => _loadingLocation = false);
    }
  }

  void _onSearchChanged(String value) {
    _pickedAddress = null;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results =
          await _placesApi.autocomplete(value, sessionToken: _sessionToken);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    setState(() {
      _searching = true;
      _suggestions = [];
    });
    _searchFocus.unfocus();
    final details =
        await _placesApi.details(s.placeId, sessionToken: _sessionToken);
    _sessionToken = _newSessionToken(); // ek search-session complete
    if (!mounted) return;
    setState(() => _searching = false);
    if (details == null) {
      Get.snackbar('', 'Location details nahi mil paayi',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final pos = LatLng(details.lat, details.lng);
    setState(() {
      _center = pos;
      _pickedAddress = details.formattedAddress ?? s.description;
      _searchCtrl.text = _pickedAddress ?? s.description;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'Pick Site Location'),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (pos) => _center = pos.target,
            onCameraMoveStarted: () => _pickedAddress = null,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_loadingLocation)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
              ),
            ),
          // Fixed center pin — map moves under it.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on_rounded,
                    size: 44, color: AppColors.primary),
              ),
            ),
          ),

          // ── Search bar + suggestions ─────────────────────────
          Positioned(
            left: AppDimens.lg,
            right: AppDimens.lg,
            top: AppDimens.md,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    style: KTextStyle.poppins(fs: 13),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for area, street, city...',
                      hintStyle:
                          KTextStyle.poppins(fs: 13, c: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textHint),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : (_searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _pickedAddress = null;
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: AppColors.textHint),
                                )
                              : null),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined,
                              size: 18, color: AppColors.primary),
                          title: Text(s.description,
                              style: KTextStyle.poppins(fs: 12.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            left: AppDimens.lg,
            right: AppDimens.lg,
            bottom: AppDimens.lg,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pickedAddress ??
                          '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                      style: KTextStyle.poppins(
                          fs: 12, c: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Confirm Location',
                      onTap: () => Get.back(result: _center),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
