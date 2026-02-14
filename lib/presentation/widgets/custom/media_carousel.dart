import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/widgets/common/fallback_image_widget.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/gestures.dart';

class MediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final double height;
  final bool showIndicators;
  final bool enableZoom;

  const MediaCarousel({
    super.key,
    required this.mediaUrls,
    this.height = 300,
    this.showIndicators = true,
    this.enableZoom = true,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  int _currentIndex = 0;
  late CarouselSliderController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        child: Stack(
          children: [
            // Carousel
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: widget.mediaUrls.length,
              options: CarouselOptions(
                height: widget.height,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                enableInfiniteScroll: widget.mediaUrls.length > 1,
                autoPlay: widget.mediaUrls.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return GestureDetector(
                  onTap: widget.enableZoom
                      ? () => _openFullscreen(context, index)
                      : null,
                  child: Hero(
                    tag: 'media_${widget.mediaUrls[index]}_$index',
                    child: _buildMediaItem(widget.mediaUrls[index]),
                  ),
                );
              },
            ),

            // Navigation Arrows (for desktop/large screens)
            if (widget.mediaUrls.length > 1)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous
                    _buildNavButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => _carouselController.previousPage(),
                    ),
                    // Next
                    _buildNavButton(
                      icon: Icons.arrow_forward_ios,
                      onPressed: () => _carouselController.nextPage(),
                    ),
                  ],
                ),
              ),

            // Indicators
            if (widget.showIndicators && widget.mediaUrls.length > 1)
              Positioned(
                bottom: Dimensions.spaceL,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.mediaUrls.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _carouselController.animateToPage(entry.key),
                      child: Container(
                        width: _currentIndex == entry.key ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentIndex == entry.key
                              ? AppColors.white
                              : AppColors.white.withOpacity(0.4),
                          boxShadow: _currentIndex == entry.key
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Counter Badge
            Positioned(
              top: Dimensions.spaceL,
              right: Dimensions.spaceL,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceM,
                  vertical: Dimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Zoom indicator
            if (widget.enableZoom)
              Positioned(
                top: Dimensions.spaceL,
                left: Dimensions.spaceL,
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.spaceS),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(String url) {
    // Check if video (simple check - you can improve this)
    final isVideo =
        url.contains('.mp4') || url.contains('.mov') || url.contains('video');

    if (isVideo) {
      return Container(
        color: AppColors.gray900,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: url.replaceAll('.mp4', '_thumbnail.jpg'),
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) =>
                  Container(color: AppColors.gray200),
              errorWidget: (context, url, error) => const Icon(
                Icons.videocam,
                size: 60,
                color: AppColors.gray400,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: AppColors.white,
                size: 40,
              ),
            ),
          ],
        ),
      );
    }

    // Check if URL is valid
    if (url.isEmpty || !url.startsWith('http')) {
      return const FallbackImageWidget(
        icon: Icons.image_not_supported,
        text: 'صورة غير متوفرة',
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.gray200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const FallbackImageWidget(
        icon: Icons.error,
        text: 'فشل في تحميل الصورة',
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      child: Material(
        color: AppColors.white.withOpacity(0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 60,
              color: AppColors.gray400,
            ),
            const SizedBox(height: Dimensions.spaceM),
            Text(
              'لا توجد صور',
              style: TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenGallery(
          mediaUrls: widget.mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const _FullscreenGallery({
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simple PageView instead of PhotoViewGallery
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final url = widget.mediaUrls[index];
              if (url.isEmpty || !url.startsWith('http')) {
                return const Center(
                  child: FallbackImageWidget(
                    width: 200,
                    height: 200,
                    icon: Icons.image_not_supported,
                    text: 'صورة غير متوفرة',
                  ),
                );
              }

              return InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: FallbackImageWidget(
                      width: 200,
                      height: 200,
                      icon: Icons.error,
                      text: 'فشل في التحميل',
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          SafeArea(
            child: Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Counter
          SafeArea(
            child: Positioned(
              bottom: Dimensions.spaceXXL,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.spaceL,
                    vertical: Dimensions.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
