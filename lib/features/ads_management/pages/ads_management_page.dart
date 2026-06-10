// ads_management_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ads_controller.dart';
import '../widgets/ad_card.dart';
import '../widgets/ad_form_page.dart';
import '../../../core/constants/app_colors.dart';
import '../models/ad_model.dart';

class AdsManagementPage extends StatelessWidget {
  const AdsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdsController(),
      child: const _AdsPageContent(),
    );
  }
}

class _AdsPageContent extends StatefulWidget {
  const _AdsPageContent();

  @override
  State<_AdsPageContent> createState() => _AdsPageContentState();
}

class _AdsPageContentState extends State<_AdsPageContent> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _isOpeningForm = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdsController>();
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 4;
    if (screenWidth < 1200) crossAxisCount = 3;
    if (screenWidth < 900) crossAxisCount = 2;
    if (screenWidth < 600) crossAxisCount = 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إدارة الإعلانات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isActionInProgress
                          ? null
                          : () => _showAdForm(controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة إعلان'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'بحث عن إعلان...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('نشط', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('غير نشط', 'inactive'),
                      const SizedBox(width: 8),
                      _buildFilterChip('منتهي', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ads Grid
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredAds(controller.ads.cast<AdModel>()).isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount:
                            _getFilteredAds(controller.ads.cast<AdModel>())
                                .length,
                        itemBuilder: (context, index) {
                          final ad = _getFilteredAds(
                              controller.ads.cast<AdModel>())[index];
                          return AdCard(
                            ad: ad,
                            onEdit: () => _showAdForm(controller, ad: ad),
                            onDelete: () => _deleteAd(context, controller, ad),
                            onToggle: () => _toggleAd(context, controller, ad),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _filterStatus == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = filter),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent.withOpacity(0.1),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  List<AdModel> _getFilteredAds(List<AdModel> ads) {
    return ads.where((ad) {
      final matchesSearch = _searchQuery.isEmpty ||
          ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.content.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      final status = ad.status;

      switch (_filterStatus) {
        case 'active':
          matchesFilter = status == AdStatus.active;
          break;
        case 'inactive':
          matchesFilter = status == AdStatus.inactive;
          break;
        case 'expired':
          matchesFilter = status == AdStatus.expired;
          break;
        default:
          matchesFilter = true;
      }
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ads_click,
            size: 80,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'لا توجد نتائج مطابقة للبحث'
                : 'لا توجد إعلانات',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          if (_searchQuery.isNotEmpty || _filterStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterStatus = 'all';
                });
              },
              child: const Text('مسح الفلتر'),
            ),
        ],
      ),
    );
  }

  Future<void> _showAdForm(AdsController controller, {AdModel? ad}) async {
    if (_isOpeningForm) return;
    _isOpeningForm = true;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdFormPage(
          ad: ad?.toJson(), // تحويل AdModel إلى Map
          onSave: (adData, image) async {
            bool success;

            if (ad == null) {
              success = await controller.createAd(adData, image!);
            } else {
              success = await controller.updateAd(ad.id.toString(), adData);
            }

            if (success && context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ad == null
                        ? 'تم إضافة الإعلان بنجاح'
                        : 'تم تحديث الإعلان بنجاح',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );

    _isOpeningForm = false;
    await controller.loadAds();
  }

  Future<void> _toggleAd(
      BuildContext context, AdsController controller, AdModel ad) async {
    final success = await controller.toggleAd(ad.id.toString(), ad.isActive);
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ad.isActive ? 'تم تعطيل الإعلان' : 'تم تفعيل الإعلان',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteAd(
      BuildContext context, AdsController controller, AdModel ad) async {
    final success = await controller.deleteAd(ad.id.toString());
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الإعلان بنجاح'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
