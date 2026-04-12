import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WriteReviewPageWidget extends StatefulWidget {
  const WriteReviewPageWidget({
    super.key,
    required this.contractorRef,
    required this.contractorName,
  });

  final DocumentReference contractorRef;
  final String contractorName;

  static String routeName = 'WriteReviewPage';
  static String routePath = '/writeReviewPage';

  @override
  State<WriteReviewPageWidget> createState() => _WriteReviewPageWidgetState();
}

class _WriteReviewPageWidgetState extends State<WriteReviewPageWidget> {
  int _selectedStars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short comment.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'contractor_ref': widget.contractorRef,
        'reviewer_uid': currentUserUid,
        'reviewer_name': currentUserDisplayName.isNotEmpty
            ? currentUserDisplayName
            : currentUserEmail,
        'reviewer_photo': currentUserPhoto,
        'rating': _selectedStars,
        'comment': _commentCtrl.text.trim(),
        'created_time': FieldValue.serverTimestamp(),
      });

      // Recalculate and denormalize rating on the contractor doc
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: widget.contractorRef)
          .get();
      final count = reviewsSnap.docs.length;
      final total = reviewsSnap.docs.fold<double>(
          0.0,
          (sum, d) =>
              sum + ((d.data()['rating'] as num?)?.toDouble() ?? 0));
      final avg = count > 0 ? total / count : 0.0;
      await widget.contractorRef
          .update({'rating_avg': avg, 'rating_count': count});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted! Thank you.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Write a Review',
          style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryText),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contractor name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.star_rounded,
                      color: theme.primary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Rating for',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contractorName,
                    style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Star rating selector
            Text(
              'Your Rating *',
              style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _selectedStars;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled
                          ? const Color(0xFFFFC107)
                          : theme.secondaryText,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),

            if (_selectedStars > 0) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _ratingLabel(_selectedStars),
                  style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      color: theme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Comment / Feedback
            Text(
              'Your Feedback *',
              style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 400,
              style: GoogleFonts.ubuntu(
                  fontSize: 14, color: theme.primaryText),
              decoration: InputDecoration(
                hintText:
                    'Share your experience with this contractor...',
                hintStyle: GoogleFonts.ubuntu(
                    fontSize: 14, color: theme.secondaryText),
                filled: true,
                fillColor: theme.secondaryBackground,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: theme.primary, width: 1.5),
                ),
                counterStyle: GoogleFonts.ubuntu(
                    fontSize: 12, color: theme.secondaryText),
              ),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  disabledBackgroundColor:
                      theme.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'Submit Review',
                        style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
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
        return '';
    }
  }
}
