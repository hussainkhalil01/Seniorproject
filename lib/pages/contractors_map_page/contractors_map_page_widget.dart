import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/contractor_profile_page/contractor_profile_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractorsMapPageWidget extends StatefulWidget {
  const ContractorsMapPageWidget({
    super.key,
    this.highlightRef,
  });

  final DocumentReference? highlightRef;

  static String routeName = 'ContractorsMapPage';
  static String routePath = '/contractorsMapPage';

  @override
  State<ContractorsMapPageWidget> createState() =>
      _ContractorsMapPageWidgetState();
}

class _ContractorsMapPageWidgetState extends State<ContractorsMapPageWidget> {
  final MapController _mapController = MapController();
  Position? _userPosition;
  List<UsersRecord> _contractors = [];
  UsersRecord? _selectedContractor;
  bool _loading = true;

  static const _bahrainCenter = ll.LatLng(26.2235, 50.5876);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadContractors();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadContractors() async {
    // Try role-filtered first; if empty, load all users with a location set
    QuerySnapshot<Map<String, dynamic>> snap;
    snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'service_provider')
        .get();
    if (snap.docs.isEmpty) {
      snap = await FirebaseFirestore.instance
          .collection('users')
          .where('latitude', isGreaterThan: 0)
          .get();
    }

    final contractors =
        snap.docs.map((d) => UsersRecord.fromSnapshot(d)).toList();

    List<UsersRecord> sorted = contractors
        .where((c) => c.latitude != 0.0 || c.longitude != 0.0)
        .toList();

    if (_userPosition != null) {
      sorted.sort((a, b) {
        final da = _distKm(_userPosition!.latitude, _userPosition!.longitude,
            a.latitude, a.longitude);
        final db = _distKm(_userPosition!.latitude, _userPosition!.longitude,
            b.latitude, b.longitude);
        return da.compareTo(db);
      });
    }

    if (mounted) {
      setState(() {
        _contractors = sorted;
        _loading = false;
      });
    }

    // Animate to highlighted or user position after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.highlightRef != null) {
        final match = contractors.where(
            (c) => c.reference.id == widget.highlightRef!.id);
        if (match.isNotEmpty) {
          _mapController.move(
              ll.LatLng(match.first.latitude, match.first.longitude), 14);
        }
      } else if (_userPosition != null) {
        _mapController.move(
            ll.LatLng(_userPosition!.latitude, _userPosition!.longitude), 12);
      }
    });
  }

  void _animateTo(ll.LatLng pos, {double zoom = 14}) {
    _mapController.move(pos, zoom);
  }

  Future<void> _openInGoogleMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final fallback = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  void _showContractorSheet(UsersRecord c) {
    final theme = FlutterFlowTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(2))),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: c.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: c.photoUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover)
                      : Container(
                          width: 56,
                          height: 56,
                          color: theme.accent1,
                          child: Icon(Icons.person_rounded,
                              color: theme.primary, size: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.fullName.isNotEmpty ? c.fullName : c.displayName,
                        style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText),
                      ),
                      if (c.title.isNotEmpty)
                        Text(c.title,
                            style: GoogleFonts.ubuntu(
                                fontSize: 13, color: theme.secondaryText)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openInGoogleMaps(
                        c.latitude,
                        c.longitude,
                        c.fullName.isNotEmpty ? c.fullName : c.displayName,
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Open in Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primary,
                      side: BorderSide(color: theme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToProfile(c);
                    },
                    icon: const Icon(Icons.person_rounded, size: 18),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      textStyle: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(UsersRecord c) {
    context.pushNamed(
      ContractorProfilePageWidget.routeName,
      queryParameters: {
        'contractorRef': serializeParam(
          c.reference,
          ParamType.DocumentReference,
        ),
      },
    );
  }

  double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  String _formatDist(UsersRecord c) {
    if (_userPosition == null || (c.latitude == 0.0 && c.longitude == 0.0)) {
      return '';
    }
    final km = _distKm(
        _userPosition!.latitude, _userPosition!.longitude,
        c.latitude, c.longitude);
    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m away'
        : '${km.toStringAsFixed(1)} km away';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bahrainCenter,
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.amanbuild.app',
                maxZoom: 19,
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ll.LatLng(
                          _userPosition!.latitude,
                          _userPosition!.longitude),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x4D0077FF),
                                blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _contractors.map((c) {
                  final isHighlighted =
                      widget.highlightRef?.id == c.reference.id;
                  return Marker(
                    point: ll.LatLng(c.latitude, c.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedContractor = c);
                        _showContractorSheet(c);
                      },
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isHighlighted
                            ? Colors.blue
                            : theme.primary,
                        size: 44,
                        shadows: const [
                          Shadow(
                              color: Color(0x40000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(color: theme.primary),
              ),
            ),

          // App bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: theme.primaryText, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        'Contractors Map',
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Recenter button
                    if (_userPosition != null)
                      GestureDetector(
                        onTap: () => _animateTo(
                          ll.LatLng(_userPosition!.latitude,
                              _userPosition!.longitude),
                          zoom: 12,
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x26000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.my_location_rounded,
                              color: theme.primary, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom contractors list
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.65,
            builder: (context, scrollCtrl) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, -4))
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.alternate,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '${_contractors.length} Contractors',
                            style: GoogleFonts.ubuntu(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.primaryText,
                            ),
                          ),
                          if (_userPosition != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· sorted by distance',
                              style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _contractors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_off_rounded,
                                      size: 48, color: theme.accent2),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No contractors found',
                                    style: GoogleFonts.ubuntu(
                                        fontSize: 15,
                                        color: theme.secondaryText),
                                  ),
                                ],
                              ))
                          : ListView.builder(
                              controller: scrollCtrl,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: _contractors.length,
                              itemBuilder: (context, i) {
                                final c = _contractors[i];
                                final dist = _formatDist(c);
                                final isHighlighted =
                                    widget.highlightRef?.id ==
                                        c.reference.id;
                                return GestureDetector(
                                  onTap: () {
                                    _animateTo(
                                      ll.LatLng(c.latitude, c.longitude),
                                      zoom: 15,
                                    );
                                    setState(
                                        () => _selectedContractor = c);
                                  },
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isHighlighted
                                          ? theme.primary
                                              .withValues(alpha: 0.08)
                                          : theme.secondaryBackground,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: isHighlighted
                                          ? Border.all(
                                              color: theme.primary,
                                              width: 1.5)
                                          : null,
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x0D000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 2))
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: c.photoUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: c.photoUrl,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover)
                                              : Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: theme.accent1,
                                                  child: Icon(
                                                      Icons.person_rounded,
                                                      color: theme.primary)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.fullName.isNotEmpty
                                                    ? c.fullName
                                                    : c.displayName,
                                                style: GoogleFonts.ubuntu(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14,
                                                  color: theme.primaryText,
                                                ),
                                              ),
                                              Text(
                                                c.title,
                                                style: GoogleFonts.ubuntu(
                                                    fontSize: 12,
                                                    color:
                                                        theme.secondaryText),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (dist.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .location_on_rounded,
                                                      size: 12,
                                                      color: theme.primary),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    dist,
                                                    style: GoogleFonts.ubuntu(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (c.ratingAvg > 0) ...[
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.star_rounded,
                                                      size: 12,
                                                      color:
                                                          Color(0xFFFFC107)),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    c.ratingAvg
                                                        .toStringAsFixed(1),
                                                    style: GoogleFonts.ubuntu(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: theme
                                                            .primaryText),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  _navigateToProfile(c),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: theme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Profile',
                                                  style: GoogleFonts.ubuntu(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            GestureDetector(
                                              onTap: () => _openInGoogleMaps(
                                                c.latitude,
                                                c.longitude,
                                                c.fullName.isNotEmpty
                                                    ? c.fullName
                                                    : c.displayName,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF34A853),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons.map_rounded,
                                                        color: Colors.white,
                                                        size: 12),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Maps',
                                                      style: GoogleFonts.ubuntu(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
