import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/rating_provider.dart';
import '../../utils/app_helpers.dart';

class RateDriverScreen extends StatefulWidget {
  final String shipmentId;
  final String driverId;
  final String driverName;
  final String? driverAvatar;

  const RateDriverScreen({
    Key? key,
    required this.shipmentId,
    required this.driverId,
    required this.driverName,
    this.driverAvatar,
  }) : super(key: key);

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _quickComments = [
    'خدمة ممتازة',
    'سائق محترم',
    'وصل في الوقت المحدد',
    'سائق لطيف',
    'أنصح بالتعامل معه',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم السائق'),
      ),
      body: Consumer<RatingProvider>(
        builder: (context, ratingProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Driver Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.driverAvatar != null
                      ? NetworkImage(widget.driverAvatar!)
                      : null,
                  child: widget.driverAvatar == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),

                // Driver Name
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'كيف كانت تجربتك مع السائق؟',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Rating Stars
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 48,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() => _rating = rating);
                  },
                  glow: false,
                ),
                const SizedBox(height: 16),

                // Rating Text
                Text(
                  _getRatingText(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: _rating > 0 ? Colors.amber[700] : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Comment Field
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'اكتب تعليقك هنا (اختياري)...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Comments
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickComments.map((comment) {
                    final isSelected = _commentController.text == comment;
                    return ActionChip(
                      label: Text(
                        comment,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _commentController.text = comment;
                        });
                      },
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Error Message
                if (ratingProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ratingProvider.error!,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating == 0 || ratingProvider.isLoading
                        ? null
                        : _submitRating,
                    child: ratingProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('إرسال التقييم'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getRatingText() {
    if (_rating == 0) return 'اضغط على النجوم للتقييم';
    if (_rating <= 1) return 'سيء جداً';
    if (_rating <= 2) return 'سيء';
    if (_rating <= 3) return 'مقبول';
    if (_rating <= 4) return 'جيد';
    return 'ممتاز';
  }

  Future<void> _submitRating() async {
    final ratingProvider = context.read<RatingProvider>();

    try {
      await ratingProvider.createRating(
        widget.shipmentId,
        widget.driverId,
        _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        AppHelpers.showSnackBar(context, 'تم إرسال التقييم بنجاح');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Error is already handled in provider
    }
  }
}
