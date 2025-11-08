import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheersync/core/constants/colors.dart';
import 'package:sheersync/core/widgets/custom_snackbar.dart';
import 'package:sheersync/data/models/review_model.dart';
import 'package:sheersync/data/models/user_model.dart';
import 'package:sheersync/data/repositories/review_repository.dart';
import 'package:sheersync/data/providers/auth_provider.dart';

class ReviewScreen extends StatefulWidget {
  final String barberId;
  final String appointmentId;
  final String barberName;

  const ReviewScreen({
    super.key,
    required this.barberId,
    required this.appointmentId,
    required this.barberName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  final TextEditingController _commentController = TextEditingController();
  
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isAnonymous = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final client = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        actions: [
          if (_selectedRating > 0)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isSubmitting ? null : _submitReview,
              tooltip: 'Submit Review',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barber Info Header
            _buildBarberHeader(),
            const SizedBox(height: 24),
            
            // Rating Section
            _buildRatingSection(),
            const SizedBox(height: 24),
            
            // Comment Section
            _buildCommentSection(),
            const SizedBox(height: 24),
            
            // Anonymous Option
            _buildAnonymousOption(),
            const SizedBox(height: 32),
            
            // Submit Button
            _buildSubmitButton(client),
          ],
        ),
      ),
    );
  }

  Widget _buildBarberHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.person,
                size: 25,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.barberName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Professional Barber',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Appointment: ${widget.appointmentId.substring(0, 8)}...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to rate your barber',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Star Rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starNumber;
                      });
                    },
                    child: Icon(
                      starNumber <= _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      size: 48,
                      color: _selectedRating >= starNumber
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(_selectedRating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your experience (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tell others about your experience with ${widget.barberName}',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What did you like about the service? Was there anything that could be improved?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_commentController.text.length}/500 characters',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousOption() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Post anonymously',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Your name and photo will not be shown',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(UserModel client) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting || _selectedRating == 0 ? null : () => _submitReview(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                _selectedRating == 0 ? 'Select a Rating' : 'Submit Review',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      showCustomSnackBar(
        context,
        'Please select a rating',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final client = authProvider.user!;

      final review = ReviewModel(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}_${client.id}',
        appointmentId: widget.appointmentId,
        barberId: widget.barberId,
        clientId: client.id,
        clientName: _isAnonymous ? 'Anonymous' : client.fullName,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Submit review to repository
      await _reviewRepository.createReview(review);

      // Show success message
      showCustomSnackBar(
        context,
        'Review submitted successfully!',
        type: SnackBarType.success,
      );

      // Navigate back after a short delay
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Failed to submit review: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}