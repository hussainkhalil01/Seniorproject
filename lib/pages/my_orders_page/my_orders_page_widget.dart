import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_orders_page_model.dart';
export 'my_orders_page_model.dart';

// ── Status config ────────────────────────────────────────────────────────────
({Color color, String label, IconData icon}) _statusConfig(String status) =>
    switch (status) {
      'pending' => (
          color: const Color(0xFFFF9800),
          label: 'Awaiting Confirmation',
          icon: Icons.access_time_rounded
        ),
      'confirmed' => (
          color: const Color(0xFF2196F3),
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded
        ),
      'partially_paid' => (
          color: const Color(0xFF9C27B0),
          label: 'Partially Paid',
          icon: Icons.payments_outlined
        ),
      'paid' => (
          color: const Color(0xFF4CAF50),
          label: 'Fully Paid',
          icon: Icons.payment_rounded
        ),
      'in_progress' => (
          color: const Color(0xFF9C27B0),
          label: 'In Progress',
          icon: Icons.work_outline_rounded
        ),
      'completed' => (
          color: const Color(0xFF4CAF50),
          label: 'Completed',
          icon: Icons.check_circle_rounded
        ),
      'cancelled' => (
          color: const Color(0xFFF44336),
          label: 'Cancelled',
          icon: Icons.cancel_rounded
        ),
      _ => (
          color: const Color(0xFF9E9E9E),
          label: 'Unknown',
          icon: Icons.help_outline_rounded
        ),
    };

// ── Page ─────────────────────────────────────────────────────────────────────
class MyOrdersPageWidget extends StatefulWidget {
  const MyOrdersPageWidget({super.key});

  static String routeName = 'MyOrdersPage';
  static String routePath = '/myOrdersPage';

  @override
  State<MyOrdersPageWidget> createState() => _MyOrdersPageWidgetState();
}

class _MyOrdersPageWidgetState extends State<MyOrdersPageWidget> {
  late MyOrdersPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyOrdersPageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await authManager.refreshUser();
      if (!mounted) return;
      if (currentUserEmailVerified ||
          currentUserDocument?.role == 'service_provider') return;

      context.goNamed(
        EmailVerifyPageWidget.routeName,
        extra: <String, dynamic>{
          '__transition_info__': const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 150),
          ),
        },
      );
      await authManager.sendEmailVerification();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isProvider = currentUserDocument?.role == 'service_provider';
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.primaryBackground,
          appBar: AppBar(
            backgroundColor: theme.secondaryBackground,
            automaticallyImplyLeading: false,
            elevation: 0,
            shadowColor: Colors.black12,
            title: Text(
              isProvider ? 'My Services' : 'My Orders',
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: theme.primaryText,
              ),
            ),
          ),
          body: isProvider
              ? _OrdersTab(queryField: 'provider_uid', isProvider: true)
              : _OrdersTab(queryField: 'client_uid', isProvider: false),
        ),
      ),
    );
  }
}

// ── Orders tab ───────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.queryField, required this.isProvider});

  final String queryField;
  final bool isProvider;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(queryField, isEqualTo: currentUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitFadingCube(color: theme.primary, size: 40),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load orders.',
              style: GoogleFonts.ubuntu(color: theme.secondaryText),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final aTime = (a.data() as Map)['created_at'] as Timestamp?;
            final bTime = (b.data() as Map)['created_at'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        if (docs.isEmpty) {
          return _EmptyState(isProvider: isProvider);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _OrderCard(
              orderId: docs[i].id,
              data: data,
              isProvider: isProvider,
            );
          },
        );
      },
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isProvider});
  final bool isProvider;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProvider
                  ? Icons.receipt_long_rounded
                  : Icons.shopping_bag_rounded,
              size: 40,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isProvider ? 'No service orders yet' : 'No purchases yet',
            style: GoogleFonts.ubuntu(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProvider
                ? 'Payment requests you send\nwill appear here.'
                : 'Orders from service providers\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(fontSize: 14, color: theme.secondaryText),
          ),
        ],
      ),
    );
  }
}

// ── Order card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.isProvider,
  });

  final String orderId;
  final Map<String, dynamic> data;
  final bool isProvider;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = data['status'] as String? ?? 'pending';
    final cfg = _statusConfig(status);
    final title = data['title'] as String? ?? 'Service Order';
    final description = data['description'] as String? ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'BHD';
    final deliveryDays = data['delivery_days'] as int? ?? 0;
    final notes = data['notes'] as String? ?? '';
    final createdAt = (data['created_at'] as Timestamp?)?.toDate();
    final otherName = isProvider
        ? (data['client_name'] as String? ?? 'Client')
        : (data['provider_name'] as String? ?? 'Provider');
    final otherPhoto = isProvider
        ? (data['client_photo'] as String? ?? '')
        : (data['provider_photo'] as String? ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.secondaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      otherPhoto.isNotEmpty ? NetworkImage(otherPhoto) : null,
                  backgroundColor: theme.accent1,
                  child: otherPhoto.isEmpty
                      ? Icon(Icons.person_rounded,
                          size: 18, color: theme.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProvider ? 'To: $otherName' : 'From: $otherName',
                        style: GoogleFonts.ubuntu(
                            fontSize: 13, color: theme.secondaryText),
                      ),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: GoogleFonts.ubuntu(
                              fontSize: 12, color: theme.secondaryText),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cfg.color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg.icon, size: 11, color: cfg.color),
                      const SizedBox(width: 4),
                      Text(
                        cfg.label,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cfg.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Card body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.schedule_rounded,
                      label:
                          '$deliveryDays Day${deliveryDays == 1 ? '' : 's'} Delivery',
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.payments_rounded,
                      label: '$amount $currency',
                      highlight: true,
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_rounded,
                            size: 14, color: theme.secondaryText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: GoogleFonts.ubuntu(
                                fontSize: 12, color: theme.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Action buttons ──
          _buildActions(context, status, theme),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, String status, FlutterFlowTheme theme) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'BHD';
    final installmentsTotal = data['installments_total'] as int? ?? 1;
    final installmentsPaid = data['installments_paid'] as int? ?? 0;
    final installmentAmount =
        (data['installment_amount'] as num?)?.toDouble() ?? amount;
    final monthsCompleted = data['months_completed'] as int? ?? 0;
    final isInstallment = installmentsTotal > 1;
    // Client can pay whenever there are still unpaid months
    final canPayNext = installmentsPaid < installmentsTotal;
    // Provider marks current month done when paid > completed
    final canMarkMonth = isProvider &&
        installmentsPaid > monthsCompleted &&
        monthsCompleted < installmentsTotal;
    final currentWorkMonth = monthsCompleted + 1;
    final allMonthsDone = monthsCompleted >= installmentsTotal;

    // ── CLIENT ───────────────────────────────────────────────────────────────
    if (!isProvider) {
      // Step 1: Pending → Confirm or Decline
      if (status == 'pending') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => _declineOrder(context, theme),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: Text('Decline',
                    style: GoogleFonts.ubuntu(
                        fontSize: 14, color: theme.error)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmOrder(context, theme),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('Confirm Order',
                      style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Confirmed / Partially paid → Timeline + Pay or Waiting
      if (status == 'confirmed' || status == 'partially_paid') {
        final nextMon = installmentsPaid + 1;
        final payLabel = isInstallment
            ? 'Pay Month $nextMon: ${_fmt(installmentAmount)} $currency'
            : 'Pay ${_fmt(amount)} $currency';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isInstallment) ...[
                _MonthsTimeline(
                  installmentsPaid: installmentsPaid,
                  installmentsTotal: installmentsTotal,
                  monthsCompleted: monthsCompleted,
                  installmentAmount: installmentAmount,
                  currency: currency,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _showDetail(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.alternate),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text('Details',
                        style: GoogleFonts.ubuntu(
                            fontSize: 14, color: theme.primaryText)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: canPayNext
                        ? FilledButton.icon(
                            onPressed: () => _handlePayment(
                                context,
                                theme,
                                installmentsPaid,
                                installmentsTotal,
                                installmentAmount,
                                amount,
                                currency),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(payLabel,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.primaryBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.alternate),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_top_rounded,
                                    size: 14,
                                    color: theme.secondaryText),
                                const SizedBox(width: 6),
                                Text(
                                    'Waiting — Month $currentWorkMonth in progress',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 12,
                                        color: theme.secondaryText)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      // Fully paid → Timeline + Track
      if (status == 'paid' || status == 'in_progress') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isInstallment) ...[
                _MonthsTimeline(
                  installmentsPaid: installmentsPaid,
                  installmentsTotal: installmentsTotal,
                  monthsCompleted: monthsCompleted,
                  installmentAmount: installmentAmount,
                  currency: currency,
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDetail(context),
                  icon: Icon(Icons.track_changes_rounded,
                      size: 18, color: theme.primary),
                  label: Text('Track Order',
                      style: GoogleFonts.ubuntu(color: theme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // ── PROVIDER ─────────────────────────────────────────────────────────────
    if (isProvider) {
      if (status == 'pending') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 16, color: theme.secondaryText),
                const SizedBox(width: 8),
                Text('Waiting for client confirmation',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText)),
              ],
            ),
          ),
        );
      }
      if (status == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_rounded,
                    size: 16, color: theme.secondaryText),
                const SizedBox(width: 8),
                Text('Waiting for payment',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText)),
              ],
            ),
          ),
        );
      }
      // Partially paid or fully paid → Timeline + smart action
      if (status == 'partially_paid' || status == 'paid') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isInstallment) ...[
                _MonthsTimeline(
                  installmentsPaid: installmentsPaid,
                  installmentsTotal: installmentsTotal,
                  monthsCompleted: monthsCompleted,
                  installmentAmount: installmentAmount,
                  currency: currency,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _showDetail(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.alternate),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text('Details',
                        style: GoogleFonts.ubuntu(
                            fontSize: 14, color: theme.primaryText)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: canMarkMonth
                        ? FilledButton.icon(
                            onPressed: () => _markMonthComplete(
                                context,
                                theme,
                                currentWorkMonth,
                                installmentsTotal),
                            icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18),
                            label: Text(
                                'Month $currentWorkMonth Done',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : allMonthsDone
                            ? FilledButton.icon(
                                onPressed: () =>
                                    _markDelivered(context, theme),
                                icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18),
                                label: Text('Mark Delivered',
                                    style: GoogleFonts.ubuntu(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              )
                            : Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: theme.alternate),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_top_rounded,
                                        size: 14,
                                        color: theme.secondaryText),
                                    const SizedBox(width: 6),
                                    Text(
                                        'Waiting for Month ${installmentsPaid + 1} payment',
                                        style: GoogleFonts.ubuntu(
                                            fontSize: 12,
                                            color: theme.secondaryText)),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
      if (status == 'in_progress') {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => _showDetail(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.alternate),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: Text('Details',
                    style: GoogleFonts.ubuntu(
                        fontSize: 14, color: theme.primaryText)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _markDelivered(context, theme),
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: Text('Mark Delivered',
                      style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Default: view details only
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _showDetail(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: FlutterFlowTheme.of(context).alternate),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('View Details',
              style: GoogleFonts.ubuntu(
                  color: FlutterFlowTheme.of(context).primaryText)),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
          orderId: orderId, data: data, isProvider: isProvider),
    );
  }

  Future<void> _confirmOrder(
      BuildContext context, FlutterFlowTheme theme) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Order?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'You are accepting this service request. Payment will be required next.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      GoogleFonts.ubuntu(color: theme.secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style:
                    GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'confirmed',
        'confirmed_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Order confirmed! Proceed to pay.',
                  style: GoogleFonts.ubuntu()),
              backgroundColor: const Color(0xFF2196F3)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }

  Future<void> _declineOrder(
      BuildContext context, FlutterFlowTheme theme) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Decline Order?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text('This will cancel the service request.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Back',
                  style:
                      GoogleFonts.ubuntu(color: theme.secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Decline',
                style:
                    GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }

  Future<void> _handlePayment(
    BuildContext context,
    FlutterFlowTheme theme,
    int installmentsPaid,
    int installmentsTotal,
    double installmentAmount,
    double totalAmount,
    String currency,
  ) async {
    final isInstallment = installmentsTotal > 1;
    final title = data['title'] as String? ?? 'Service Order';

    // Installment order → always show full vs monthly choice
    if (isInstallment) {
      await _showPaymentChoiceAndPay(
          context, theme, installmentAmount, totalAmount, currency, title,
          installmentsTotal, installmentsPaid);
      return;
    }

    // Single payment (non-installment)
    final payAmount = totalAmount;
    final installmentNum = installmentsPaid + 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Payment',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            if (isInstallment) ...[
              const SizedBox(height: 4),
              Text(
                  'Installment $installmentNum of $installmentsTotal',
                  style: GoogleFonts.ubuntu(
                      color: theme.secondaryText, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      isInstallment
                          ? 'This installment:'
                          : 'Total:',
                      style: GoogleFonts.ubuntu()),
                  Text('${_fmt(payAmount)} $currency',
                      style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: theme.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      GoogleFonts.ubuntu(color: theme.secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm Payment',
                style:
                    GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final newPaid = installmentsPaid + 1;
    final isFullyPaid = newPaid >= installmentsTotal;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'installments_paid': newPaid,
        'status': isFullyPaid ? 'paid' : 'partially_paid',
        if (isFullyPaid) 'paid_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
                isFullyPaid
                    ? 'Fully paid! ✅'
                    : 'Installment $newPaid/$installmentsTotal paid ✅',
                style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF4CAF50),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content:
                  Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  Future<void> _showPaymentChoiceAndPay(
    BuildContext context,
    FlutterFlowTheme theme,
    double installmentAmount,
    double totalAmount,
    String currency,
    String title,
    int installmentsTotal,
    int installmentsPaid,
  ) async {
    final remainingMonths = installmentsTotal - installmentsPaid;
    final remainingTotal = installmentAmount * remainingMonths;
    // Returns: 'full' = pay all, '1','2',... = pay N months
    int monthCount = 1;
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final partialTotal = installmentAmount * monthCount;
          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Choose Payment Plan',
                      style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: GoogleFonts.ubuntu(
                          fontSize: 13, color: theme.secondaryText)),
                  const SizedBox(height: 20),
                  // ── Pay Full Amount ──────────────────────────────────────
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop('full'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: theme.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    theme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.payment_rounded,
                                  color: theme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Pay Full Amount',
                                      style: GoogleFonts.ubuntu(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  Text('One payment, all done',
                                      style: GoogleFonts.ubuntu(
                                          fontSize: 12,
                                          color: theme.secondaryText)),
                                ],
                              ),
                            ),
                            Text('${_fmt(remainingTotal)} $currency',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: theme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Pay Monthly (with month counter) ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.alternate),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_month_rounded,
                                  color: theme.secondaryText, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text('Pay Monthly',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('How many months to pay now?',
                            style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                color: theme.secondaryText)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: monthCount > 1
                                  ? () => setSheet(() => monthCount--)
                                  : null,
                              icon: Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: monthCount > 1
                                      ? theme.primary
                                      : theme.secondaryText),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$monthCount month${monthCount > 1 ? 's' : ''}',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              ),
                            ),
                            IconButton(
                              onPressed: monthCount < remainingMonths
                                  ? () => setSheet(() => monthCount++)
                                  : null,
                              icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: monthCount < remainingMonths
                                      ? theme.primary
                                      : theme.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total to pay:',
                                style: GoogleFonts.ubuntu(
                                    color: theme.secondaryText,
                                    fontSize: 13)),
                            Text('${_fmt(partialTotal)} $currency',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: theme.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop('$monthCount'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: Text(
                                'Pay ${_fmt(partialTotal)} $currency',
                                style: GoogleFonts.ubuntu(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel',
                        style: GoogleFonts.ubuntu(
                            color: theme.secondaryText)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (choice == null || !context.mounted) return;

    final int selectedMonths =
        choice == 'full' ? remainingMonths : (int.tryParse(choice) ?? 1);
    final double payAmount =
        choice == 'full' ? remainingTotal : installmentAmount * selectedMonths;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            choice == 'full'
                ? 'Pay Full Amount'
                : 'Pay $selectedMonths Month${selectedMonths > 1 ? "s" : ""}',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(choice == 'full' ? 'Total:' : 'Amount:',
                  style: GoogleFonts.ubuntu()),
              Text('${_fmt(payAmount)} $currency',
                  style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: theme.primary)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final newTotalPaid = installmentsPaid + selectedMonths;
    final isFullyPaid = newTotalPaid >= installmentsTotal;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'installments_paid': newTotalPaid,
        'status': isFullyPaid ? 'paid' : 'partially_paid',
        if (isFullyPaid) 'paid_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
                isFullyPaid
                    ? 'Full payment done! ✅'
                    : '$selectedMonths month${selectedMonths > 1 ? "s" : ""} paid ✅',
                style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF4CAF50),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }

  Future<void> _markMonthComplete(
    BuildContext context,
    FlutterFlowTheme theme,
    int monthNum,
    int installmentsTotal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Month $monthNum Complete?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'Confirm that Month $monthNum work is done.\n'
            'The client will be notified to pay the next installment.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style:
                    GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'months_completed': monthNum});
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Month $monthNum marked complete ✅',
                style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF2196F3),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content:
                  Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }

  Future<void> _markDelivered(
      BuildContext context, FlutterFlowTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as Delivered?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'This will mark the order as completed and notify the client.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Order marked as delivered ✅',
                style: GoogleFonts.ubuntu()),
            backgroundColor: const Color(0xFF4CAF50),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }
}

// ── Small chips ──────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.highlight = false});
  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final fg = highlight ? theme.primary : theme.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? theme.primary.withValues(alpha: 0.08)
            : theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlight
                ? theme.primary.withValues(alpha: 0.25)
                : theme.alternate),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  fontWeight:
                      highlight ? FontWeight.w600 : FontWeight.normal,
                  color: highlight ? theme.primary : theme.primaryText)),
        ],
      ),
    );
  }
}

// ── Monthly progress timeline ────────────────────────────────────────────────
class _MonthsTimeline extends StatelessWidget {
  const _MonthsTimeline({
    required this.installmentsPaid,
    required this.installmentsTotal,
    required this.monthsCompleted,
    required this.installmentAmount,
    required this.currency,
  });
  final int installmentsPaid, installmentsTotal, monthsCompleted;
  final double installmentAmount;
  final String currency;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        children: List.generate(installmentsTotal, (i) {
          final monthNum = i + 1;
          final isPaid = installmentsPaid >= monthNum;
          final isDone = monthsCompleted >= monthNum;
          final isNextPay = monthNum == installmentsPaid + 1;
          final isLast = i == installmentsTotal - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    // Circle state icon
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF4CAF50)
                                .withValues(alpha: 0.15)
                            : isPaid
                                ? const Color(0xFF2196F3)
                                    .withValues(alpha: 0.12)
                                : theme.alternate,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Color(0xFF4CAF50))
                            : isPaid
                                ? const Icon(Icons.work_outline_rounded,
                                    size: 13,
                                    color: Color(0xFF2196F3))
                                : Text(
                                    '$monthNum',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.secondaryText),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Month label + amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Month $monthNum',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText)),
                          Text('${_fmt(installmentAmount)} $currency',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 11,
                                  color: theme.secondaryText)),
                        ],
                      ),
                    ),
                    // Payment tag
                    _tag(
                      label: isPaid ? 'Paid ✓' : isNextPay ? 'Next' : 'Locked',
                      fg: isPaid
                          ? const Color(0xFF4CAF50)
                          : isNextPay
                              ? theme.primary
                              : theme.secondaryText,
                      bg: isPaid
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.10)
                          : isNextPay
                              ? theme.primary.withValues(alpha: 0.10)
                              : theme.alternate.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    // Work completion tag
                    _tag(
                      label: isDone ? 'Done ✓' : isPaid ? 'Working' : '—',
                      fg: isDone
                          ? const Color(0xFF4CAF50)
                          : isPaid
                              ? const Color(0xFF2196F3)
                              : theme.secondaryText,
                      bg: isDone
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.10)
                          : isPaid
                              ? const Color(0xFF2196F3).withValues(alpha: 0.10)
                              : Colors.transparent,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1, indent: 52, color: theme.alternate),
            ],
          );
        }),
      ),
    );
  }

  Widget _tag(
          {required String label,
          required Color fg,
          required Color bg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: GoogleFonts.ubuntu(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg)),
      );
}

// ── Order detail sheet ───────────────────────────────────────────────────────
class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet(
      {required this.orderId,
      required this.data,
      required this.isProvider});
  final String orderId;
  final Map<String, dynamic> data;
  final bool isProvider;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = data['status'] as String? ?? 'pending';
    final cfg = _statusConfig(status);
    final title = data['title'] as String? ?? 'Service Order';
    final description = data['description'] as String? ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final currency = data['currency'] as String? ?? 'BHD';
    final deliveryDays = data['delivery_days'] as int? ?? 0;
    final notes = data['notes'] as String? ?? '';
    final createdAt = (data['created_at'] as Timestamp?)?.toDate();
    final paidAt = (data['paid_at'] as Timestamp?)?.toDate();
    final completedAt = (data['completed_at'] as Timestamp?)?.toDate();
    final providerName = data['provider_name'] as String? ?? 'Provider';
    final clientName = data['client_name'] as String? ?? 'Client';
    final providerPhoto = data['provider_photo'] as String? ?? '';
    final clientPhoto = data['client_photo'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Order Details',
                style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            const SizedBox(height: 20),
            // Parties row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Party(name: providerName, photo: providerPhoto, label: 'Provider'),
                Icon(Icons.arrow_forward_rounded, color: theme.secondaryText),
                _Party(name: clientName, photo: clientPhoto, label: 'Client'),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.ubuntu(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description,
                  style: GoogleFonts.ubuntu(
                      fontSize: 14, color: theme.secondaryText)),
            ],
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.request_page_rounded,
                label: 'Status',
                value: cfg.label,
                valueColor: cfg.color),
            _DetailRow(
                icon: Icons.payments_rounded,
                label: 'Amount',
                value: '$amount $currency',
                valueColor: theme.primary),
            _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Delivery',
                value: '$deliveryDays day${deliveryDays == 1 ? '' : 's'}'),
            if (createdAt != null)
              _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Created',
                  value:
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
            if (paidAt != null)
              _DetailRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Paid On',
                  value: '${paidAt.day}/${paidAt.month}/${paidAt.year}',
                  valueColor: const Color(0xFF4CAF50)),
            if (completedAt != null)
              _DetailRow(
                  icon: Icons.done_all_rounded,
                  label: 'Delivered',
                  value:
                      '${completedAt.day}/${completedAt.month}/${completedAt.year}',
                  valueColor: const Color(0xFF4CAF50)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.alternate),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes',
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText)),
                    const SizedBox(height: 4),
                    Text(notes,
                        style: GoogleFonts.ubuntu(color: theme.secondaryText)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Party extends StatelessWidget {
  const _Party(
      {required this.name, required this.photo, required this.label});
  final String name, photo, label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          backgroundColor: theme.accent1,
          child: photo.isEmpty
              ? Icon(Icons.person_rounded, color: theme.primary, size: 22)
              : null,
        ),
        const SizedBox(height: 6),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.primaryText)),
        Text(label,
            style:
                GoogleFonts.ubuntu(fontSize: 11, color: theme.secondaryText)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
  final IconData icon;
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.secondaryText),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.ubuntu(
                  fontSize: 13, color: theme.secondaryText)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.ubuntu(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.primaryText)),
        ],
      ),
    );
  }
}
