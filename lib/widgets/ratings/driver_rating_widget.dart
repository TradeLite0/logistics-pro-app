import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/rating_model.dart';

class DriverRatingWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final List<RatingModel>? recentRatings;
  final bool showRecentRatings;

  const DriverRatingWidget({
    Key? key,
    required this.averageRating,
    required this.totalRatings,
    this.recentRatings,
    this.showRecentRatings = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      RatingBarIndicator(
                        rating: averageRating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 16,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التقييم العام',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بناءً على $totalRatings تقييم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Rating Distribution
            if (totalRatings > 0) ...[
              const Divider(height: 32),
              _buildRatingDistribution(),
            ],

            // Recent Reviews
            if (showRecentRatings &&
                recentRatings != null &&
                recentRatings!.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'أحدث التقييمات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...recentRatings!.take(3).map((rating) => _buildRatingItem(rating)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      children: [
        _buildRatingBar(5, 0.8),
        const SizedBox(height: 4),
        _buildRatingBar(4, 0.6),
        const SizedBox(height: 4),
        _buildRatingBar(3, 0.3),
        const SizedBox(height: 4),
        _buildRatingBar(2, 0.1),
        const SizedBox(height: 4),
        _buildRatingBar(1, 0.05),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                stars >= 4 ? Colors.green : stars >= 3 ? Colors.amber : Colors.red,
              ),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(RatingModel rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: rating.client?.avatar != null
                ? NetworkImage(rating.client!.avatar!)
                : null,
            child: rating.client?.avatar == null
                ? Text(rating.client?.name[0] ?? '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rating.client?.name ?? 'مستخدم',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: rating.rating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                  ],
                ),
                if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rating.comment!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompactRatingWidget extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;

  const CompactRatingWidget({
    Key? key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: size,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size - 2,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
