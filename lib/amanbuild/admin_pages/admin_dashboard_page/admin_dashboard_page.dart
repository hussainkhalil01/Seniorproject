import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  static const String routeName = 'AdminDashboard';
  static const String routePath = '/adminDashboard';

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = [
    (icon: Icons.dashboard_rounded, label: 'Overview'),
    (icon: Icons.manage_accounts_rounded, label: 'Clients'),
    (icon: Icons.people_rounded, label: 'Contractors'),
    (icon: Icons.star_rounded, label: 'Reviews'),
    (icon: Icons.chat_bubble_rounded, label: 'Chats'),
    (icon: Icons.receipt_long_rounded, label: 'Orders'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = currentUserDocument?.role ?? '';

    if (role != 'admin') {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: theme.primaryText),
            onPressed: () => context.pop(),
          ),
          title: Text('Admin',
              style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.w700, color: theme.primaryText)),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.lock_rounded, size: 40, color: theme.error),
            ),
            const SizedBox(height: 20),
            Text('Access Restricted',
                style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            const SizedBox(height: 8),
            Text('This area is for authorized admins only.',
                style: GoogleFonts.ubuntu(
                    fontSize: 14, color: theme.secondaryText)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('Admin',
                          style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFF4A026),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
          labelStyle:
              GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: _tabs
              .map((t) => Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(t.label),
                    ]),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _OverviewTab(),
          _UsersTab(),
          _ContractorsTab(),
          _ReviewsTab(),
          _ChatsTab(),
          _OrdersTab(),
        ],
      ),
    );
  }
}

Widget _statCard(
    BuildContext ctx, String label, String value, IconData icon, Color color) {
  final theme = FlutterFlowTheme.of(ctx);
  return Card(
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.07),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: theme.secondaryBackground,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: GoogleFonts.ubuntu(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText)),
                Text(label,
                    style: GoogleFonts.ubuntu(
                        fontSize: 12, color: theme.secondaryText)),
              ]),
        ),
      ]),
    ),
  );
}

Widget _sectionTitle(BuildContext ctx, String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title,
          style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FlutterFlowTheme.of(ctx).primaryText)),
    );

Widget _loadingOrError(BuildContext ctx, AsyncSnapshot snap) {
  final theme = FlutterFlowTheme.of(ctx);
  if (snap.connectionState == ConnectionState.waiting) {
    return Center(child: SpinKitFadingCube(color: theme.primary, size: 36));
  }
  return Center(
      child: Text('Failed to load data',
          style: GoogleFonts.ubuntu(color: theme.secondaryText)));
}

Widget _emptyState(BuildContext ctx, String message) {
  final theme = FlutterFlowTheme.of(ctx);
  return Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_rounded, size: 52, color: theme.alternate),
      const SizedBox(height: 12),
      Text(message,
          style: GoogleFonts.ubuntu(fontSize: 14, color: theme.secondaryText)),
    ]),
  );
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day}/${dt.month}/${dt.year}';
}

Future<void> _logAdminAction(String action, Map<String, dynamic> extra) async {
  await FirebaseFirestore.instance.collection('admin_logs').add({
    'action': action,
    'admin_uid': currentUserUid,
    'admin_email': currentUserEmail,
    'timestamp': FieldValue.serverTimestamp(),
    ...extra,
  });
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams(),
      builder: (ctx, snap) {
        if (!snap.hasData) return _loadingOrError(ctx, snap);

        final usersSnap = snap.data![0];
        final ordersSnap = snap.data![1];
        final chatsSnap = snap.data![2];

        final allUsers = usersSnap.docs;
        final contractors = allUsers
            .where((d) => (d.data() as Map)['role'] == 'service_provider')
            .toList();
        final clients = allUsers
            .where((d) =>
                (d.data() as Map)['role'] != 'service_provider' &&
                (d.data() as Map)['role'] != 'admin')
            .toList();
        final orders = ordersSnap.docs;
        final chats = chatsSnap.docs;

        final statusCounts = <String, int>{};
        for (final o in orders) {
          final s = (o.data() as Map)['status'] as String? ?? 'unknown';
          statusCounts[s] = (statusCounts[s] ?? 0) + 1;
        }

        final ratingBuckets = [0, 0, 0, 0, 0]; // 1-star thru 5-star
        int ratedCount = 0;
        for (final c in contractors) {
          final avg =
              ((c.data() as Map)['rating_avg'] as num?)?.toDouble() ?? 0;
          if (avg > 0) {
            ratedCount++;
            final bucket = (avg.round() - 1).clamp(0, 4);
            ratingBuckets[bucket]++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Summary',
                style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText)),
            const SizedBox(height: 10),
            _statCard(ctx, 'Total Contractors', contractors.length.toString(),
                Icons.build_rounded, theme.primary),
            const SizedBox(height: 10),
            _statCard(ctx, 'Total Clients', clients.length.toString(),
                Icons.person_rounded, const Color(0xFF26A69A)),
            const SizedBox(height: 10),
            _statCard(ctx, 'Total Orders', orders.length.toString(),
                Icons.receipt_long_rounded, const Color(0xFFF4A026)),
            const SizedBox(height: 10),
            _statCard(ctx, 'Total Chats', chats.length.toString(),
                Icons.chat_bubble_rounded, const Color(0xFF9C27B0)),
            _sectionTitle(ctx, 'Orders by Status'),
            Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: theme.secondaryBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusBar(
                        ctx,
                        'Pending',
                        statusCounts['pending'] ?? 0,
                        orders.length,
                        const Color(0xFFFF9800)),
                    const SizedBox(height: 10),
                    _buildStatusBar(
                        ctx,
                        'Confirmed',
                        statusCounts['confirmed'] ?? 0,
                        orders.length,
                        const Color(0xFF2196F3)),
                    const SizedBox(height: 10),
                    _buildStatusBar(
                        ctx,
                        'Partially Paid',
                        statusCounts['partially_paid'] ?? 0,
                        orders.length,
                        const Color(0xFF9C27B0)),
                    const SizedBox(height: 10),
                    _buildStatusBar(
                        ctx,
                        'Fully Paid',
                        statusCounts['paid'] ?? 0,
                        orders.length,
                        const Color(0xFF26A69A)),
                    const SizedBox(height: 10),
                    _buildStatusBar(
                        ctx,
                        'Completed',
                        statusCounts['completed'] ?? 0,
                        orders.length,
                        const Color(0xFF4CAF50)),
                    const SizedBox(height: 10),
                    _buildStatusBar(
                        ctx,
                        'Cancelled',
                        statusCounts['cancelled'] ?? 0,
                        orders.length,
                        const Color(0xFFF44336)),
                  ],
                ),
              ),
            ),
            _sectionTitle(ctx, 'Contractor Ratings Overview'),
            Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: theme.secondaryBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ratedCount == 0
                    ? _emptyState(ctx, 'No rated contractors yet')
                    : Column(children: [
                        for (int i = 4; i >= 0; i--)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildStatusBar(
                              ctx,
                              '${i + 1} Star${i == 0 ? '' : 's'}',
                              ratingBuckets[i],
                              ratedCount,
                              _starColor(i),
                            ),
                          ),
                      ]),
              ),
            ),
            _sectionTitle(ctx, 'Top Rated Contractors'),
            ..._topContractors(ctx, contractors, theme),
          ]),
        );
      },
    );
  }

  Color _starColor(int i) => switch (i) {
        4 => const Color(0xFF4CAF50),
        3 => const Color(0xFF8BC34A),
        2 => const Color(0xFFFFC107),
        1 => const Color(0xFFFF9800),
        _ => const Color(0xFFF44336),
      };

  Widget _buildStatusBar(
      BuildContext ctx, String label, int count, int total, Color color) {
    final theme = FlutterFlowTheme.of(ctx);
    final frac = total == 0 ? 0.0 : count / total;
    return Row(children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style:
                GoogleFonts.ubuntu(fontSize: 12, color: theme.secondaryText)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: theme.alternate,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 28,
        child: Text('$count',
            textAlign: TextAlign.right,
            style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.primaryText)),
      ),
    ]);
  }

  List<Widget> _topContractors(BuildContext ctx,
      List<QueryDocumentSnapshot> contractors, FlutterFlowTheme theme) {
    final rated = contractors
        .where((d) =>
            (((d.data() as Map)['rating_avg'] as num?)?.toDouble() ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final aAvg = ((a.data() as Map)['rating_avg'] as num?)?.toDouble() ?? 0;
        final bAvg = ((b.data() as Map)['rating_avg'] as num?)?.toDouble() ?? 0;
        return bAvg.compareTo(aAvg);
      });
    if (rated.isEmpty) {
      return [_emptyState(ctx, 'No rated contractors yet')];
    }
    return rated.take(3).map((d) {
      final data = d.data() as Map<String, dynamic>;
      final name = data['display_name'] as String? ?? 'Contractor';
      final avg = ((data['rating_avg'] as num?)?.toDouble() ?? 0);
      final count = data['rating_count'] as int? ?? 0;
      final photo = data['photo_url'] as String? ?? '';
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: theme.secondaryBackground,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            backgroundColor: theme.primary.withValues(alpha: 0.1),
            child: photo.isEmpty
                ? Icon(Icons.person_rounded, color: theme.primary)
                : null,
          ),
          title: Text(name,
              style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
              '${data['categories']?.isNotEmpty == true ? (data['categories'] as List).first : 'Contractor'}',
              style:
                  GoogleFonts.ubuntu(fontSize: 12, color: theme.secondaryText)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    size: 15, color: Color(0xFFFFC107)),
                const SizedBox(width: 3),
                Text(avg.toStringAsFixed(1),
                    style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
              Text('$count reviews',
                  style: GoogleFonts.ubuntu(
                      fontSize: 11, color: theme.secondaryText)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Stream<List<QuerySnapshot>> _combineStreams() {
    final db = FirebaseFirestore.instance;
    final usersStream = db.collection('users').snapshots();

    return usersStream.asyncMap((users) async {
      final orders = await db.collection('orders').get();
      final chats = await db.collection('chats').get();
      return [users, orders, chats];
    });
  }
}

class _ContractorsTab extends StatefulWidget {
  const _ContractorsTab();

  @override
  State<_ContractorsTab> createState() => _ContractorsTabState();
}

class _ContractorsTabState extends State<_ContractorsTab> {
  String _sort = 'highest_rated';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(children: [
      Container(
        color: theme.secondaryBackground,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search contractors…',
              hintStyle:
                  GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: theme.secondaryText),
              filled: true,
              fillColor: theme.primaryBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Highest Rated', 'highest_rated', theme),
                const SizedBox(width: 8),
                _filterChip('Lowest Rated', 'lowest_rated', theme),
                const SizedBox(width: 8),
                _filterChip('Most Reviewed', 'most_reviewed', theme),
                const SizedBox(width: 8),
                _filterChip('Most Reported', 'most_reported', theme),
              ],
            ),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'service_provider')
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _loadingOrError(ctx, snap);
            var docs = snap.data!.docs;
            if (_query.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name =
                    (data['display_name'] as String? ?? '').toLowerCase();
                final cats = ((data['categories'] as List?) ?? [])
                    .join(' ')
                    .toLowerCase();
                return name.contains(_query) || cats.contains(_query);
              }).toList();
            }
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              switch (_sort) {
                case 'lowest_rated':
                  final aAvg = (aData['rating_avg'] as num?)?.toDouble() ?? 0;
                  final bAvg = (bData['rating_avg'] as num?)?.toDouble() ?? 0;
                  return aAvg.compareTo(bAvg);
                case 'most_reviewed':
                  final aC = aData['rating_count'] as int? ?? 0;
                  final bC = bData['rating_count'] as int? ?? 0;
                  return bC.compareTo(aC);
                case 'most_reported':
                  final aR = aData['report_count'] as int? ?? 0;
                  final bR = bData['report_count'] as int? ?? 0;
                  return bR.compareTo(aR);
                default: // highest_rated
                  final aAvg = (aData['rating_avg'] as num?)?.toDouble() ?? 0;
                  final bAvg = (bData['rating_avg'] as num?)?.toDouble() ?? 0;
                  return bAvg.compareTo(aAvg);
              }
            });

            if (docs.isEmpty) {
              return _emptyState(ctx, 'No contractors found');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _ContractorCard(data: data, docId: docs[i].id);
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, String value, FlutterFlowTheme theme) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? theme.primary : theme.alternate, width: 1.2),
        ),
        child: Text(label,
            style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.secondaryText)),
      ),
    );
  }
}

class _ContractorCard extends StatelessWidget {
  const _ContractorCard({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final name = data['display_name'] as String? ?? 'Contractor';
    final email = data['email'] as String? ?? '';
    final avg = (data['rating_avg'] as num?)?.toDouble() ?? 0.0;
    final count = data['rating_count'] as int? ?? 0;
    final cats = (data['categories'] as List?)?.cast<String>() ?? [];
    final photo = data['photo_url'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            backgroundColor: theme.primary.withValues(alpha: 0.1),
            child: photo.isEmpty
                ? Icon(Icons.person_rounded, size: 24, color: theme.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(email,
                  style: GoogleFonts.ubuntu(
                      fontSize: 12, color: theme.secondaryText)),
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: cats.take(2).map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c,
                          style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              color: theme.primary,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
            ]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFFFC107)),
                const SizedBox(width: 4),
                Text(avg.toStringAsFixed(1),
                    style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 2),
              Text('$count review${count != 1 ? 's' : ''}',
                  style: GoogleFonts.ubuntu(
                      fontSize: 11, color: theme.secondaryText)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  bool _loading = false;

  Future<List<_ReviewEntry>> _fetchAllReviews() async {
    final db = FirebaseFirestore.instance;

    final reviewsSnap = await db
        .collection('reviews')
        .orderBy('created_time', descending: true)
        .get();

    final entries = <_ReviewEntry>[];
    for (final r in reviewsSnap.docs) {
      final rData = r.data();
      final contractorRef = rData['contractor_ref'] as DocumentReference?;
      if (contractorRef == null) continue;

      String contractorName = 'Contractor';
      try {
        final cSnap = await contractorRef.get();
        if (cSnap.exists) {
          contractorName = (cSnap.data() as Map?)?['display_name'] as String? ??
              'Contractor';
        }
      } catch (_) {}

      entries.add(_ReviewEntry(
        reviewId: r.id,
        contractorId: contractorRef.id,
        contractorRef: contractorRef,
        contractorName: contractorName,
        reviewerName: rData['reviewer_name'] as String? ?? 'User',
        rating: (rData['rating'] as num?)?.toDouble() ?? 0,
        comment: rData['comment'] as String? ?? '',
        date: (rData['created_time'] as Timestamp?)?.toDate(),
      ));
    }
    return entries;
  }

  Future<void> _deleteReview(BuildContext ctx, _ReviewEntry entry) async {
    final theme = FlutterFlowTheme.of(ctx);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Review?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove this review by "${entry.reviewerName}" for "${entry.contractorName}"?\n\nThis action cannot be undone.',
          style: GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('Delete',
                style: GoogleFonts.ubuntu(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(entry.reviewId)
          .delete();
      final remaining = await FirebaseFirestore.instance
          .collection('reviews')
          .where('contractor_ref', isEqualTo: entry.contractorRef)
          .get();
      if (remaining.docs.isEmpty) {
        await entry.contractorRef
            .update({'rating_avg': 0.0, 'rating_count': 0});
      } else {
        double sum = 0;
        for (final r in remaining.docs) {
          sum += (r.data()['rating'] as num?)?.toDouble() ?? 0;
        }
        await entry.contractorRef.update({
          'rating_avg': sum / remaining.docs.length,
          'rating_count': remaining.docs.length,
        });
      }
      await _logAdminAction('delete_review', {
        'review_id': entry.reviewId,
        'contractor_id': entry.contractorId,
        'contractor_name': entry.contractorName,
        'reviewer_name': entry.reviewerName,
      });
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Review deleted',
            style: GoogleFonts.ubuntu(color: Colors.white)),
        backgroundColor: theme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Failed to delete review',
            style: GoogleFonts.ubuntu(color: Colors.white)),
        backgroundColor: theme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Stack(children: [
      FutureBuilder<List<_ReviewEntry>>(
        future: _fetchAllReviews(),
        builder: (ctx, snap) {
          if (!snap.hasData) return _loadingOrError(ctx, snap);
          final reviews = snap.data!;
          if (reviews.isEmpty) return _emptyState(ctx, 'No reviews yet');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (ctx, i) {
              final r = reviews[i];
              return _ReviewCard(
                entry: r,
                onDelete: () => _deleteReview(ctx, r),
              );
            },
          );
        },
      ),
      if (_loading)
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child:
              Center(child: SpinKitFadingCube(color: theme.primary, size: 36)),
        ),
    ]);
  }
}

class _ReviewEntry {
  final String reviewId;
  final String contractorId;
  final DocumentReference contractorRef;
  final String contractorName;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime? date;

  _ReviewEntry({
    required this.reviewId,
    required this.contractorId,
    required this.contractorRef,
    required this.contractorName,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.entry, required this.onDelete});
  final _ReviewEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.person_rounded, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.reviewerName,
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('For: ${entry.contractorName}',
                        style: GoogleFonts.ubuntu(
                            fontSize: 12, color: theme.secondaryText)),
                  ]),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Icon(
                  i < entry.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: const Color(0xFFFFC107),
                );
              }),
            ),
          ]),
          if (entry.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(entry.comment,
                  style: GoogleFonts.ubuntu(
                      fontSize: 13, color: theme.primaryText)),
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: theme.secondaryText),
            const SizedBox(width: 4),
            Text(_formatDate(entry.date),
                style: GoogleFonts.ubuntu(
                    fontSize: 12, color: theme.secondaryText)),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: theme.error,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, size: 15),
              label: Text('Remove',
                  style: GoogleFonts.ubuntu(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(children: [
      Container(
        color: theme.secondaryBackground,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by participant name…',
            hintStyle:
                GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: theme.secondaryText),
            filled: true,
            fillColor: theme.primaryBackground,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .orderBy('last_message_time', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _loadingOrError(ctx, snap);
            var docs = snap.data!.docs;
            if (_query.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final a = (data['user_a_name'] as String? ?? '').toLowerCase();
                final b = (data['user_b_name'] as String? ?? '').toLowerCase();
                return a.contains(_query) || b.contains(_query);
              }).toList();
            }
            if (docs.isEmpty) {
              return _emptyState(ctx, 'No conversations found');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _ChatCard(
                    chatId: docs[i].id, data: data, chatRef: docs[i].reference);
              },
            );
          },
        ),
      ),
    ]);
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard(
      {required this.chatId, required this.data, required this.chatRef});
  final String chatId;
  final Map<String, dynamic> data;
  final DocumentReference chatRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final userA = data['user_a_name'] as String? ?? 'User A';
    final userB = data['user_b_name'] as String? ?? 'User B';
    final lastMsg = data['last_message'] as String? ?? '';
    final lastTime = (data['last_message_time'] as Timestamp?)?.toDate();
    final photoA = data['user_a_photo'] as String? ?? '';
    final isReported = data['reported'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isReported
          ? theme.error.withValues(alpha: 0.05)
          : theme.secondaryBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openChat(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    photoA.isNotEmpty ? NetworkImage(photoA) : null,
                backgroundColor: theme.primary.withValues(alpha: 0.1),
                child: photoA.isEmpty
                    ? Icon(Icons.chat_rounded, color: theme.primary, size: 20)
                    : null,
              ),
              if (isReported)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        color: theme.error, shape: BoxShape.circle),
                    child: const Icon(Icons.flag_rounded,
                        size: 9, color: Colors.white),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$userA  ↔  $userB',
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      lastMsg.startsWith('__')
                          ? '📎 Attachment'
                          : lastMsg.isEmpty
                              ? 'No messages yet'
                              : lastMsg,
                      style: GoogleFonts.ubuntu(
                          fontSize: 12, color: theme.secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatDate(lastTime),
                    style: GoogleFonts.ubuntu(
                        fontSize: 11, color: theme.secondaryText)),
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                    onTap: () => _toggleReport(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReported
                            ? theme.error.withValues(alpha: 0.12)
                            : theme.alternate,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            isReported
                                ? Icons.flag_rounded
                                : Icons.flag_outlined,
                            size: 12,
                            color:
                                isReported ? theme.error : theme.secondaryText),
                        const SizedBox(width: 4),
                        Text(isReported ? 'Reported' : 'Flag',
                            style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                color: isReported
                                    ? theme.error
                                    : theme.secondaryText,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: theme.secondaryText),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext ctx) async {
    await _logAdminAction('admin_view_chat', {'chat_id': chatId});
    if (!ctx.mounted) return;
    final theme = FlutterFlowTheme.of(ctx);
    final userA = data['user_a_name'] as String? ?? 'User A';
    final userB = data['user_b_name'] as String? ?? 'User B';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$userA  ↔  $userB',
                          style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.primaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Read-only · Admin view',
                            style: GoogleFonts.ubuntu(
                                fontSize: 11,
                                color: theme.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            Divider(height: 20, color: theme.alternate),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_messages')
                    .where('chat', isEqualTo: chatRef)
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (ctx2, snap) {
                  if (!snap.hasData) {
                    return Center(
                        child:
                            SpinKitFadingCube(color: theme.primary, size: 28));
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('No messages yet',
                          style:
                              GoogleFonts.ubuntu(color: theme.secondaryText)),
                    );
                  }
                  return ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final msg = docs[i].data() as Map<String, dynamic>;
                      final text = msg['text'] as String? ?? '';
                      final image = msg['image'] as String? ?? '';
                      final video = msg['video'] as String? ?? '';
                      final audio = msg['audio'] as String? ?? '';
                      final ts = (msg['timestamp'] as Timestamp?)?.toDate();
                      final senderRef = msg['user'] as DocumentReference?;
                      final userARef = data['user_a'] as DocumentReference?;
                      final isA = senderRef?.id == userARef?.id;
                      final senderLabel = isA ? userA : userB;

                      final isLocation = text.startsWith('__location__:');
                      final isOrder = text.startsWith('__order__:');
                      final isPayment = text.startsWith('__payment__') ||
                          text.startsWith('Payment request:');
                      final isImage = image.isNotEmpty;
                      final isVideo = video.isNotEmpty;
                      final isAudio = audio.isNotEmpty;
                      final isEmpty =
                          text.isEmpty && !isImage && !isVideo && !isAudio;
                      if (isEmpty) return const SizedBox.shrink();

                      Widget bubbleContent;
                      if (isLocation) {
                        bubbleContent = Row(children: [
                          Icon(Icons.location_on_rounded,
                              size: 16, color: theme.primary),
                          const SizedBox(width: 6),
                          Text('Shared a location',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  color: theme.primaryText,
                                  fontStyle: FontStyle.italic)),
                        ]);
                      } else if (isOrder) {
                        final oid = text
                            .substring('__order__:'.length)
                            .substring(
                                0,
                                text
                                    .substring('__order__:'.length)
                                    .length
                                    .clamp(0, 8))
                            .toUpperCase();
                        bubbleContent = Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4A026)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                size: 14, color: Color(0xFFF4A026)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Request',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryText)),
                                Text('#$oid',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 11,
                                        color: theme.secondaryText)),
                              ],
                            ),
                          ),
                        ]);
                      } else if (isPayment) {
                        final label =
                            isPayment && text.startsWith('Payment request:')
                                ? text
                                : 'Payment request';
                        bubbleContent = Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_rounded,
                                size: 14, color: Color(0xFF4CAF50)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(label,
                                style: GoogleFonts.ubuntu(
                                    fontSize: 13, color: theme.primaryText)),
                          ),
                        ]);
                      } else if (isImage) {
                        bubbleContent = Row(children: [
                          Icon(Icons.image_rounded,
                              size: 16, color: theme.secondaryText),
                          const SizedBox(width: 6),
                          Text('📷 Photo',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  color: theme.primaryText,
                                  fontStyle: FontStyle.italic)),
                        ]);
                      } else if (isVideo) {
                        bubbleContent = Row(children: [
                          Icon(Icons.videocam_rounded,
                              size: 16, color: theme.secondaryText),
                          const SizedBox(width: 6),
                          Text('🎥 Video',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  color: theme.primaryText,
                                  fontStyle: FontStyle.italic)),
                        ]);
                      } else if (isAudio) {
                        bubbleContent = Row(children: [
                          Icon(Icons.mic_rounded,
                              size: 16, color: theme.secondaryText),
                          const SizedBox(width: 6),
                          Text('🎵 Voice message',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  color: theme.primaryText,
                                  fontStyle: FontStyle.italic)),
                        ]);
                      } else {
                        bubbleContent = Text(text,
                            style: GoogleFonts.ubuntu(
                                fontSize: 14, color: theme.primaryText));
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: isA
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: isA ? 4 : 0, right: isA ? 0 : 4),
                              child: Text(senderLabel,
                                  style: GoogleFonts.ubuntu(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.secondaryText)),
                            ),
                            const SizedBox(height: 3),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isA
                                      ? theme.secondaryBackground
                                      : theme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isA ? 4 : 16),
                                    bottomRight: Radius.circular(isA ? 16 : 4),
                                  ),
                                  border: Border.all(
                                      color: theme.alternate
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    bubbleContent,
                                    const SizedBox(height: 4),
                                    Text(
                                      ts != null
                                          ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                          : '',
                                      style: GoogleFonts.ubuntu(
                                          fontSize: 10,
                                          color: theme.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border:
                    Border(top: BorderSide(color: theme.alternate, width: 1)),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.lock_outline_rounded,
                    size: 14, color: theme.secondaryText),
                const SizedBox(width: 6),
                Text(
                  'Admin view — messaging is disabled',
                  style: GoogleFonts.ubuntu(
                      fontSize: 12, color: theme.secondaryText),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggleReport(BuildContext ctx) async {
    final isReported = data['reported'] as bool? ?? false;
    await chatRef.update({'reported': !isReported});
    await _logAdminAction(
        isReported ? 'unflag_chat' : 'flag_chat', {'chat_id': chatId});
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _filter = 'all';
  String _query = '';
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('partially_paid', 'Partially Paid'),
    ('paid', 'Fully Paid'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(children: [
      Container(
        color: theme.secondaryBackground,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by client or contractor…',
              hintStyle:
                  GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: theme.secondaryText),
              filled: true,
              fillColor: theme.primaryBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final selected = _filter == s.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = s.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            selected ? theme.primary : theme.primaryBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? theme.primary : theme.alternate,
                            width: 1.2),
                      ),
                      child: Text(s.$2,
                          style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : theme.secondaryText)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _loadingOrError(ctx, snap);
            var docs = snap.data!.docs;

            if (_filter != 'all') {
              docs = docs
                  .where((d) => (d.data() as Map)['status'] == _filter)
                  .toList();
            }
            if (_query.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final client =
                    (data['client_name'] as String? ?? '').toLowerCase();
                final provider =
                    (data['provider_name'] as String? ?? '').toLowerCase();
                final title = (data['title'] as String? ?? '').toLowerCase();
                return client.contains(_query) ||
                    provider.contains(_query) ||
                    title.contains(_query);
              }).toList();
            }

            if (docs.isEmpty) {
              return _emptyState(ctx, 'No orders found');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _AdminOrderCard(orderId: docs[i].id, data: data);
              },
            );
          },
        ),
      ),
    ]);
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.orderId, required this.data});
  final String orderId;
  final Map<String, dynamic> data;

  static ({Color color, String label, IconData icon}) _statusConfig(
          String status) =>
      switch (status) {
        'pending' => (
            color: const Color(0xFFFF9800),
            label: 'Pending',
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
            label: 'Paid',
            icon: Icons.payment_rounded
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = data['status'] as String? ?? 'pending';
    final cfg = _statusConfig(status);
    final title = data['title'] as String? ?? 'Service Order';
    final clientName = data['client_name'] as String? ?? 'Client';
    final providerName = data['provider_name'] as String? ?? 'Provider';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final createdAt = (data['created_at'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.secondaryBackground,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cfg.color.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(cfg.icon, size: 15, color: cfg.color),
            const SizedBox(width: 6),
            Text(cfg.label,
                style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cfg.color)),
            const Spacer(),
            Text(
              'BHD ${amount.toStringAsFixed(3)}',
              style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Row(children: [
              _infoChip(context, Icons.person_outline_rounded, clientName),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: theme.secondaryText),
              const SizedBox(width: 8),
              _infoChip(context, Icons.build_circle_outlined, providerName),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: theme.secondaryText),
              const SizedBox(width: 4),
              Text(_formatDate(createdAt),
                  style: GoogleFonts.ubuntu(
                      fontSize: 12, color: theme.secondaryText)),
              const SizedBox(width: 16),
              Icon(Icons.receipt_outlined,
                  size: 13, color: theme.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '#${orderId.substring(0, orderId.length.clamp(0, 8)).toUpperCase()}',
                  style: GoogleFonts.ubuntu(
                      fontSize: 12, color: theme.secondaryText),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showOrderDetails(context),
                icon: const Icon(Icons.info_outline_rounded, size: 15),
                label: Text('View Payment Details',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showOrderDetails(BuildContext context) {
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
    final clientName = data['client_name'] as String? ?? 'Client';
    final providerName = data['provider_name'] as String? ?? 'Provider';
    final installmentsTotal = data['installments_total'] as int? ?? 1;
    final installmentsPaid = data['installments_paid'] as int? ?? 0;
    final installmentAmount =
        (data['installment_amount'] as num?)?.toDouble() ?? amount;
    final monthsCompleted = data['months_completed'] as int? ?? 0;
    final amountPaid = (data['amount_paid'] as num?)?.toDouble() ?? 0;
    final remaining = amount - amountPaid;
    final isInstallment = installmentsTotal > 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: Text('Order Details',
                      style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cfg.icon, size: 13, color: cfg.color),
                    const SizedBox(width: 5),
                    Text(cfg.label,
                        style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cfg.color)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '#${orderId.substring(0, orderId.length.clamp(0, 8)).toUpperCase()}',
                style: GoogleFonts.ubuntu(
                    fontSize: 12, color: theme.secondaryText),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _detailSection(theme, 'Service Information', [
                    _detailRow(
                        theme, Icons.work_outline_rounded, 'Title', title),
                    if (description.isNotEmpty)
                      _detailRow(theme, Icons.description_outlined,
                          'Description', description),
                    _detailRow(theme, Icons.schedule_rounded, 'Delivery',
                        '$deliveryDays day${deliveryDays == 1 ? '' : 's'}'),
                    _detailRow(theme, Icons.calendar_today_rounded, 'Created',
                        _formatDate(createdAt)),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(theme, 'Parties', [
                    _detailRow(
                        theme, Icons.person_rounded, 'Client', clientName),
                    _detailRow(theme, Icons.build_circle_outlined, 'Contractor',
                        providerName),
                  ]),
                  const SizedBox(height: 16),
                  _detailSection(theme, 'Payment Summary', [
                    _detailRow(theme, Icons.payments_rounded, 'Total Amount',
                        '$currency ${amount.toStringAsFixed(3)}'),
                    if (amountPaid > 0)
                      _detailRow(
                          theme,
                          Icons.check_circle_outline_rounded,
                          'Amount Paid',
                          '$currency ${amountPaid.toStringAsFixed(3)}',
                          valueColor: const Color(0xFF4CAF50)),
                    if (remaining > 0 && amountPaid > 0)
                      _detailRow(
                          theme,
                          Icons.hourglass_bottom_rounded,
                          'Remaining',
                          '$currency ${remaining.toStringAsFixed(3)}',
                          valueColor: const Color(0xFFFF9800)),
                  ]),
                  const SizedBox(height: 16),
                  if (isInstallment) ...[
                    _detailSection(theme, 'Installment Plan', [
                      _detailRow(
                          theme,
                          Icons.calendar_month_rounded,
                          'Total Months',
                          '$installmentsTotal month${installmentsTotal == 1 ? '' : 's'}'),
                      _detailRow(theme, Icons.done_all_rounded, 'Months Paid',
                          '$installmentsPaid of $installmentsTotal'),
                      _detailRow(
                          theme,
                          Icons.pending_actions_rounded,
                          'Months Remaining',
                          '${installmentsTotal - installmentsPaid} left'),
                      _detailRow(
                          theme,
                          Icons.monetization_on_rounded,
                          'Per Month',
                          '$currency ${installmentAmount.toStringAsFixed(3)}'),
                      if (monthsCompleted > 0)
                        _detailRow(theme, Icons.event_available_rounded,
                            'Months Completed', '$monthsCompleted'),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Payment Progress',
                                      style: GoogleFonts.ubuntu(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryText)),
                                  Text(
                                    '${installmentsTotal == 0 ? 0 : ((installmentsPaid / installmentsTotal) * 100).round()}%',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primary),
                                  ),
                                ]),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: installmentsTotal == 0
                                    ? 0
                                    : installmentsPaid / installmentsTotal,
                                minHeight: 10,
                                backgroundColor: theme.alternate,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4CAF50)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$installmentsPaid of $installmentsTotal installments paid',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 12, color: theme.secondaryText),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (notes.isNotEmpty)
                    _detailSection(theme, 'Notes', [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(notes,
                            style: GoogleFonts.ubuntu(
                                fontSize: 13, color: theme.primaryText)),
                      ),
                    ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailSection(
      FlutterFlowTheme theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.secondaryText)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _detailRow(
      FlutterFlowTheme theme, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: theme.secondaryText),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: valueColor ?? theme.primaryText)),
                ),
              ]),
        ),
      ]),
    );
  }

  Widget _infoChip(BuildContext ctx, IconData icon, String label) {
    final theme = FlutterFlowTheme.of(ctx);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: theme.secondaryText),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.ubuntu(fontSize: 12, color: theme.primaryText)),
          ),
        ]),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _filter = 'all'; // all | active | paused | deleted
  String _role = 'all'; // all | client | service_provider
  String _query = '';
  final _searchCtrl = TextEditingController();

  static const _statusFilters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('paused', 'Paused'),
    ('deleted', 'Deleted'),
  ];

  static const _roleFilters = [
    ('all', 'All Roles'),
    ('client', 'Clients'),
    ('service_provider', 'Contractors'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(children: [
      Container(
        color: theme.secondaryBackground,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              hintStyle:
                  GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: theme.secondaryText),
              filled: true,
              fillColor: theme.primaryBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final sel = _filter == s.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = s.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            sel ? _statusColor(s.$1) : theme.primaryBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? _statusColor(s.$1) : theme.alternate,
                            width: 1.2),
                      ),
                      child: Text(s.$2,
                          style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : theme.secondaryText)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roleFilters.map((r) {
                final sel = _role == r.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _role = r.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? theme.primary : theme.primaryBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? theme.primary : theme.alternate,
                            width: 1.2),
                      ),
                      child: Text(r.$2,
                          style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : theme.secondaryText)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('created_time', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return _loadingOrError(ctx, snap);
            var docs = snap.data!.docs;

            if (_role != 'all') {
              docs = docs
                  .where((d) => (d.data() as Map)['role'] == _role)
                  .toList();
            }
            docs = docs
                .where((d) => (d.data() as Map)['role'] != 'admin')
                .toList();

            if (_filter != 'all') {
              docs = docs
                  .where((d) => _accountStatus(d.data() as Map) == _filter)
                  .toList();
            }

            if (_query.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name =
                    (data['display_name'] as String? ?? '').toLowerCase();
                final email = (data['email'] as String? ?? '').toLowerCase();
                return name.contains(_query) || email.contains(_query);
              }).toList();
            }

            if (docs.isEmpty) {
              return _emptyState(ctx, 'No accounts found');
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _UserAccountCard(
                  docId: docs[i].id,
                  data: data,
                  onRefresh: () => setState(() {}),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  static Color _statusColor(String status) => switch (status) {
        'active' => const Color(0xFF4CAF50),
        'paused' => const Color(0xFFFF9800),
        'deleted' => const Color(0xFFF44336),
        _ => const Color(0xFF9E9E9E),
      };

  static String _accountStatus(Map data) {
    if (data['deleted'] == true) return 'deleted';
    if (data['paused'] == true) return 'paused';
    return 'active';
  }
}

class _UserAccountCard extends StatelessWidget {
  const _UserAccountCard({
    required this.docId,
    required this.data,
    required this.onRefresh,
  });

  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  static Color _statusColor(String s) => switch (s) {
        'active' => const Color(0xFF4CAF50),
        'paused' => const Color(0xFFFF9800),
        'deleted' => const Color(0xFFF44336),
        _ => const Color(0xFF9E9E9E),
      };

  static ({String label, Color color, IconData icon}) _statusCfg(String s) =>
      switch (s) {
        'paused' => (
            label: 'Paused',
            color: const Color(0xFFFF9800),
            icon: Icons.pause_circle_rounded
          ),
        'deleted' => (
            label: 'Deleted',
            color: const Color(0xFFF44336),
            icon: Icons.delete_forever_rounded
          ),
        _ => (
            label: 'Active',
            color: const Color(0xFF4CAF50),
            icon: Icons.check_circle_rounded
          ),
      };

  String _accountStatus() {
    if (data['deleted'] == true) return 'deleted';
    if (data['paused'] == true) return 'paused';
    return 'active';
  }

  String _roleLabel(String role) => switch (role) {
        'service_provider' => 'Contractor',
        'client' => 'Client',
        _ => role,
      };

  Future<void> _pauseResume(BuildContext ctx) async {
    final theme = FlutterFlowTheme.of(ctx);
    final isPaused = data['paused'] == true;
    final name = data['display_name'] as String? ?? 'this account';
    final action = isPaused ? 'Resume' : 'Pause';
    final actionDesc = isPaused
        ? 'This will restore their access to the app.'
        : 'This will prevent them from logging in or using the app.';
    final color = isPaused ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$action Account?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                  isPaused
                      ? Icons.play_circle_rounded
                      : Icons.pause_circle_rounded,
                  color: color,
                  size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$action "$name"?\n$actionDesc',
                  style: GoogleFonts.ubuntu(
                      fontSize: 13, color: theme.primaryText),
                ),
              ),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(action,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'paused': !isPaused});
      await _logAdminAction(isPaused ? 'resume_account' : 'pause_account', {
        'target_uid': docId,
        'target_name': name,
        'target_role': data['role'] ?? '',
      });
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Account ${isPaused ? 'resumed' : 'paused'}',
              style: GoogleFonts.ubuntu(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Failed: $e',
              style: GoogleFonts.ubuntu(color: Colors.white)),
          backgroundColor: FlutterFlowTheme.of(ctx).error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _delete(BuildContext ctx) async {
    final theme = FlutterFlowTheme.of(ctx);
    final name = data['display_name'] as String? ?? 'this account';
    final isAlreadyDeleted = data['deleted'] == true;

    final step1 = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: theme.error, size: 22),
          const SizedBox(width: 8),
          Text('Delete Account?',
              style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'You are about to delete "$name".\n\n'
              'The account will be marked as deleted and the user '
              'will lose all access to the app.\n\n'
              'This action is logged and cannot be easily undone.',
              style: GoogleFonts.ubuntu(fontSize: 13, color: theme.primaryText),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(color: theme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('Proceed',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (step1 != true || !ctx.mounted) return;

    final nameCtrl = TextEditingController();
    final step2 = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (sCtx, setSt) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm Deletion',
              style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Type the account name to confirm:',
              style:
                  GoogleFonts.ubuntu(fontSize: 13, color: theme.secondaryText),
            ),
            const SizedBox(height: 10),
            Text('"$name"',
                style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.error)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              onChanged: (_) => setSt(() {}),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type name here…',
                filled: true,
                fillColor: theme.primaryBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              style: GoogleFonts.ubuntu(fontSize: 14),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text('Cancel',
                  style: GoogleFonts.ubuntu(color: theme.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: nameCtrl.text.trim() == name
                      ? theme.error
                      : theme.alternate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: nameCtrl.text.trim() == name
                  ? () => Navigator.pop(dCtx, true)
                  : null,
              child: Text('Delete',
                  style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    if (step2 != true || !ctx.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'deleted': true,
        'paused': true,
        'deleted_at': FieldValue.serverTimestamp(),
      });
      await _logAdminAction('delete_account', {
        'target_uid': docId,
        'target_name': name,
        'target_role': data['role'] ?? '',
        'was_already_deleted': isAlreadyDeleted,
      });
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Account deleted',
              style: GoogleFonts.ubuntu(color: Colors.white)),
          backgroundColor: theme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Failed: $e',
              style: GoogleFonts.ubuntu(color: Colors.white)),
          backgroundColor: FlutterFlowTheme.of(ctx).error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final status = _accountStatus();
    final cfg = _statusCfg(status);
    final name = data['display_name'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? '';
    final role = data['role'] as String? ?? 'client';
    final photo = data['photo_url'] as String? ?? '';
    final createdAt = (data['created_time'] as Timestamp?)?.toDate();
    final isPaused = data['paused'] == true;
    final isDeleted = data['deleted'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDeleted
          ? theme.error.withValues(alpha: 0.04)
          : isPaused
              ? const Color(0xFFFF9800).withValues(alpha: 0.04)
              : theme.secondaryBackground,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                backgroundColor: theme.primary.withValues(alpha: 0.1),
                child: photo.isEmpty
                    ? Icon(Icons.person_rounded, size: 22, color: theme.primary)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.secondaryBackground, width: 2),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (email.isNotEmpty)
                    Text(email,
                        style: GoogleFonts.ubuntu(
                            fontSize: 12, color: theme.secondaryText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cfg.icon, size: 12, color: cfg.color),
                const SizedBox(width: 4),
                Text(cfg.label,
                    style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cfg.color)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: role == 'service_provider'
                    ? theme.primary.withValues(alpha: 0.1)
                    : theme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    role == 'service_provider'
                        ? Icons.build_circle_outlined
                        : Icons.person_outline_rounded,
                    size: 12,
                    color: role == 'service_provider'
                        ? theme.primary
                        : theme.secondary),
                const SizedBox(width: 4),
                Text(_roleLabel(role),
                    style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: role == 'service_provider'
                            ? theme.primary
                            : theme.secondary)),
              ]),
            ),
            const SizedBox(width: 10),
            if (createdAt != null) ...[
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: theme.secondaryText),
              const SizedBox(width: 4),
              Text(
                'Joined ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: GoogleFonts.ubuntu(
                    fontSize: 11, color: theme.secondaryText),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            if (!isDeleted) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pauseResume(context),
                  icon: Icon(
                    isPaused
                        ? Icons.play_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isPaused ? 'Resume' : 'Pause',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isPaused
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800),
                    side: BorderSide(
                      color: isPaused
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                          : const Color(0xFFFF9800).withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleted ? null : () => _delete(context),
                icon: Icon(
                  isDeleted
                      ? Icons.delete_forever_rounded
                      : Icons.delete_outline_rounded,
                  size: 16,
                ),
                label: Text(
                  isDeleted ? 'Deleted' : 'Delete',
                  style: GoogleFonts.ubuntu(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDeleted ? theme.secondaryText : theme.error,
                  side: BorderSide(
                    color: isDeleted
                        ? theme.alternate
                        : theme.error.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
