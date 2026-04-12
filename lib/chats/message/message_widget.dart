import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/user_profile_sheet/user_profile_sheet_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'message_model.dart';
export 'message_model.dart';

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    required this.chatRef,
  });

  final DocumentReference? chatRef;

  static String routeName = 'Message';
  static String routePath = '/message';

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  late MessageModel _model;
  late final AudioRecorder _audioRecorder;
  late final ap.AudioPlayer _audioPlayer;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _recordingTimer;
  bool _isRecording = false;
  bool _isUploadingVoice = false;
  bool _isClearing = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordedAudioPath;
  String? _playingAudioSource;
  ap.PlayerState _playerState = ap.PlayerState.stopped;

  // Pending location to be sent when user taps the send button
  Map<String, double>? _pendingLocation;

  bool get _hasPendingLocation => _pendingLocation != null;

  bool get _hasTypedMessage =>
      (_model.textField11TextController.text).trim().isNotEmpty;

  bool get _hasRecordedPreview =>
      (_recordedAudioPath?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MessageModel());
    _audioRecorder = AudioRecorder();
    _audioPlayer = ap.AudioPlayer();

    _model.textField11TextController ??= TextEditingController();
    _model.textField11FocusNode ??= FocusNode();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _playerState = state;
        if (state == ap.PlayerState.stopped) {
          _playingAudioSource = null;
        }
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      safeSetState(() {
        _playerState = ap.PlayerState.completed;
        _playingAudioSource = null;
      });
    });

    // Mark conversation as read when the chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.chatRef?.update({
        'last_message_seen_by': FieldValue.arrayUnion([currentUserReference]),
      });
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_audioPlayer.dispose());
    unawaited(_audioRecorder.dispose());
    _model.dispose();

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _sendTextMessage() async {
    final messageText = _model.textField11TextController.text.trim();
    if (messageText.isEmpty) {
      return;
    }

    _model.messageTemp = messageText;
    EasyDebounce.cancel('_model.textField11TextController');
    _model.textField11TextController?.value = TextEditingValue.empty;
    safeSetState(() {});

    // Translate for recipient if they have a preferred language set
    String? translationToStore;
    try {
      final chatDoc = await ChatsRecord.getDocumentOnce(widget.chatRef!);
      final recipientRef = chatDoc.userA == currentUserReference
          ? chatDoc.userB
          : chatDoc.userA;
      if (recipientRef != null) {
        final recipientDoc =
            await UsersRecord.getDocumentOnce(recipientRef);
        final targetLang = recipientDoc.preferredLanguage;
        if (targetLang.isNotEmpty) {
          final hasArabic = _model.messageTemp.runes
              .any((r) => r >= 0x0600 && r <= 0x06FF);
          final sourceLang = hasArabic ? 'ar' : 'en';

          if (sourceLang != targetLang) {
            // Run spell correction and translation concurrently
            final spellFuture = (!hasArabic)
                ? _correctSpelling(_model.messageTemp)
                : Future<String?>.value(null);
            final corrected = await spellFuture;
            final textToTranslate =
                (corrected != null && corrected.isNotEmpty)
                    ? corrected
                    : _model.messageTemp;
            final translated =
                await _translateText(textToTranslate, targetLang);
            if (translated != null && translated.isNotEmpty) {
              translationToStore = translated;
            }
          } else {
            // Same language — show spell correction only
            translationToStore =
                await _correctSpelling(_model.messageTemp);
          }
        }
      }
    } catch (_) {
      // Failed; send original text only
    }

    await ChatMessagesRecord.collection.doc().set(createChatMessagesRecordData(
          user: currentUserReference,
          chat: widget.chatRef,
          text: _model.messageTemp,
          translatedText: translationToStore,
          timestamp: getCurrentTimestamp,
          isRead: false,
        ));

    final chatUpdateData = createChatsRecordData(
      lastMessageTime: getCurrentTimestamp,
      lastMessageSentBy: currentUserReference,
      lastMessage: _model.messageTemp,
    );
    chatUpdateData['last_message_seen_by'] = [currentUserReference];
    chatUpdateData['deleted_by'] = [];
    await widget.chatRef!.update(chatUpdateData);
  }

  Future<String?> _translateText(String text, String targetLang) async {
    try {
      // Detect source language by checking for Arabic script characters.
      // This covers the main cases: Arabic <-> English.
      final hasArabic = text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
      final sourceLang = hasArabic ? 'ar' : 'en';

      // Don't translate if source == target
      if (sourceLang == targetLang) return null;

      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeQueryComponent(text)}&langpair=$sourceLang|$targetLang',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final translated =
            body['responseData']?['translatedText'] as String?;
        if (translated == null || translated.isEmpty) return null;
        // Only reject all-caps ASCII error strings (e.g. "PLEASE SELECT TWO DISTINCT LANGUAGES").
        // Arabic and other scripts have no case so we must NOT apply the uppercase check to them.
        final isAllCapsLatinError = RegExp(r'^[A-Z\s]+$').hasMatch(translated);
        if (isAllCapsLatinError) return null;
        return translated;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _correctSpelling(String text) async {
    try {
      final hasArabic =
          text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
      // Use explicit language codes for better accuracy
      final langCode = hasArabic ? 'ar' : 'en-US';

      final response = await http
          .post(
            Uri.parse('https://api.languagetool.org/v2/check'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body:
                'language=$langCode&text=${Uri.encodeQueryComponent(text)}',
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final matches =
            (body['matches'] as List<dynamic>? ?? []);
        if (matches.isEmpty) return null;

        // Apply corrections from end to start to preserve offsets
        String corrected = text;
        for (final match in matches.reversed) {
          final offset = match['offset'] as int;
          final length = match['length'] as int;
          final replacements =
              match['replacements'] as List<dynamic>? ?? [];
          if (replacements.isEmpty) continue;
          final replacement =
              (replacements.first['value'] as String?) ?? '';
          // Skip pure capitalisation changes (e.g. "nam" → "Nam")
          // Only apply real spelling/grammar fixes
          if (replacement.toLowerCase() ==
              text.substring(offset, offset + length).toLowerCase()) {
            continue;
          }
          corrected = corrected.substring(0, offset) +
              replacement +
              corrected.substring(offset + length);
        }
        if (corrected == text) return null;
        return corrected;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording || _isUploadingVoice) {
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showSnackBar(
            'Microphone permission is required to record voice messages.');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final recordingPath =
          '${tempDir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';

      await _audioPlayer.stop();
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: recordingPath,
      );

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) {
          return;
        }
        safeSetState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });

      safeSetState(() {
        _isRecording = true;
        _recordedAudioPath = null;
        _recordingDuration = Duration.zero;
        _playingAudioSource = null;
      });
    } catch (_) {
      _showSnackBar('Unable to start recording right now.');
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      final recordingPath = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      safeSetState(() {
        _isRecording = false;
        _recordedAudioPath = recordingPath;
      });

      if (recordingPath == null || recordingPath.isEmpty) {
        _showSnackBar('Recording did not complete. Please try again.');
      }
    } catch (_) {
      _recordingTimer?.cancel();
      safeSetState(() {
        _isRecording = false;
      });
      _showSnackBar('Unable to stop recording right now.');
    }
  }

  Future<void> _discardRecordedVoice() async {
    if (_playingAudioSource == _recordedAudioPath) {
      await _audioPlayer.stop();
    }

    safeSetState(() {
      _recordedAudioPath = null;
      _recordingDuration = Duration.zero;
      _playingAudioSource = null;
      _playerState = ap.PlayerState.stopped;
    });
  }

  Future<void> _toggleAudioPlayback(String source) async {
    try {
      if (_playingAudioSource == source) {
        if (_playerState == ap.PlayerState.playing) {
          await _audioPlayer.pause();
          return;
        }

        if (_playerState == ap.PlayerState.paused) {
          await _audioPlayer.resume();
          return;
        }
      }

      safeSetState(() {
        _playingAudioSource = source;
      });

      await _audioPlayer.stop();
      await _audioPlayer.play(_buildAudioSource(source));
    } catch (_) {
      _showSnackBar('Unable to play this voice message.');
    }
  }

  ap.Source _buildAudioSource(String source) {
    if (kIsWeb ||
        source.startsWith('http://') ||
        source.startsWith('https://')) {
      return ap.UrlSource(source);
    }
    return ap.DeviceFileSource(source);
  }

  Future<void> _sendRecordedVoice() async {
    if (!_hasRecordedPreview || _isUploadingVoice) {
      return;
    }

    final recordingPath = _recordedAudioPath!;

    safeSetState(() {
      _isUploadingVoice = true;
    });

    try {
      // Save a permanent copy in the app's documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName =
          'voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      final permanentPath = '${docsDir.path}/$fileName';
      await File(recordingPath).copy(permanentPath);

      await ChatMessagesRecord.collection
          .doc()
          .set(createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: '',
            audio: permanentPath,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      final chatUpdateData = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: 'Voice message',
      );
      chatUpdateData['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdateData);

      await _discardRecordedVoice();
    } catch (e) {
      debugPrint('[VoiceSave] error: $e');
      _showSnackBar('Failed to save voice message: ${e.toString()}');
    } finally {
      if (mounted) {
        safeSetState(() {
          _isUploadingVoice = false;
        });
      }
    }
  }

  // ── Attachment helpers ──────────────────────────────────────────────────

  static bool _isImagePath(String path) {
    final l = path.toLowerCase();
    return l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.png') ||
        l.endsWith('.gif') ||
        l.endsWith('.webp') ||
        l.endsWith('.heic') ||
        l.endsWith('.bmp');
  }

  Future<void> _showAttachmentSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachmentSheet(
        onCamera: () async {
          Navigator.pop(context);
          await _pickAndSendImage(ImageSource.camera);
        },
        onGallery: () async {
          Navigator.pop(context);
          await _pickAndSendImage(ImageSource.gallery);
        },
        onVideo: () async {
          Navigator.pop(context);
          await _pickAndSendVideo();
        },
        onFile: () async {
          Navigator.pop(context);
          await _pickAndSendFile();
        },
        onLocation: () async {
          Navigator.pop(context);
          await _sendLocation();
        },
      ),
    );
  }

  // Step 1: get location and show preview — does NOT send yet
  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission denied.');
        return;
      }

      _showSnackBar('Getting your location...');

      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      if (!mounted) return;
      setState(() {
        _pendingLocation = {'lat': pos.latitude, 'lng': pos.longitude};
      });
    } catch (e) {
      _showSnackBar('Failed to get location.');
    }
  }

  // Step 2: actually send — called by the send button
  Future<void> _sendPendingLocation() async {
    if (_pendingLocation == null) return;
    final lat = _pendingLocation!['lat']!;
    final lng = _pendingLocation!['lng']!;
    setState(() => _pendingLocation = null);

    try {
      final locationText = '__location__:$lat,$lng,My Location';

      await ChatMessagesRecord.collection.doc().set(
          createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: locationText,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      final chatUpdate = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: '📍 Location',
      );
      chatUpdate['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdate);
    } catch (e) {
      _showSnackBar('Failed to send location.');
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final permanentPath =
          '${docsDir.path}/img_${DateTime.now().microsecondsSinceEpoch}.$ext';
      await File(picked.path).copy(permanentPath);

      await ChatMessagesRecord.collection.doc().set(
          createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: '',
            image: permanentPath,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      final chatUpdate = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: '📷 Photo',
      );
      chatUpdate['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdate);
    } catch (e) {
      _showSnackBar('Failed to send image.');
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final permanentPath =
          '${docsDir.path}/vid_${DateTime.now().microsecondsSinceEpoch}.$ext';
      await File(picked.path).copy(permanentPath);

      await ChatMessagesRecord.collection.doc().set(
          createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: '',
            video: permanentPath,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      final chatUpdate = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: '🎥 Video',
      );
      chatUpdate['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdate);
    } catch (e) {
      _showSnackBar('Failed to send video.');
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final sourcePath = result.files.single.path!;
      final fileName = result.files.single.name;

      final docsDir = await getApplicationDocumentsDirectory();
      final permanentPath =
          '${docsDir.path}/file_${DateTime.now().microsecondsSinceEpoch}_$fileName';
      await File(sourcePath).copy(permanentPath);

      await ChatMessagesRecord.collection.doc().set(
          createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: fileName,
            image: permanentPath,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      final chatUpdate = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: '📄 $fileName',
      );
      chatUpdate['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdate);
    } catch (e) {
      _showSnackBar('Failed to send file.');
    }
  }

  // ── Order / Invoice helpers ────────────────────────────────────────────

  void _showSendOrderSheet(ChatsRecord chatRecord) {
    final isUserA = currentUserReference == chatRecord.userA;
    final clientRef = isUserA ? chatRecord.userB : chatRecord.userA;
    final clientName = isUserA ? chatRecord.userBName : chatRecord.userAName;
    final clientPhoto = isUserA ? chatRecord.userBPhoto : chatRecord.userAPhoto;
    final clientUid = clientRef?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendOrderSheet(
        onSend: ({
          required String title,
          required String description,
          required double amount,
          required String currency,
          required int deliveryDays,
          required String notes,
        }) async {
          await _sendOrderRequest(
            chatRecord: chatRecord,
            title: title,
            description: description,
            amount: amount,
            currency: currency,
            deliveryDays: deliveryDays,
            notes: notes,
            clientRef: clientRef,
            clientUid: clientUid,
            clientName: clientName,
            clientPhoto: clientPhoto,
          );
        },
      ),
    );
  }

  Future<void> _sendOrderRequest({
    required ChatsRecord chatRecord,
    required String title,
    required String description,
    required double amount,
    required String currency,
    required int deliveryDays,
    required String notes,
    required DocumentReference? clientRef,
    required String clientUid,
    required String clientName,
    required String clientPhoto,
  }) async {
    try {
      final providerUid = currentUserReference?.id ?? '';
      final providerName = currentUserDocument?.displayName ?? '';
      final providerPhoto = currentUserDocument?.photoUrl ?? '';

      // Compute installment plan
      final installmentsTotal =
          deliveryDays <= 30 ? 1 : (deliveryDays / 30).ceil();
      final installmentAmount = amount / installmentsTotal;

      // 1. Create order doc
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      await orderRef.set({
        'title': title,
        'description': description,
        'amount': amount,
        'currency': currency,
        'delivery_days': deliveryDays,
        'notes': notes,
        'status': 'pending',
        'installments_total': installmentsTotal,
        'installments_paid': 0,
        'months_completed': 0,
        'installment_amount': installmentAmount,
        'provider_ref': currentUserReference,
        'client_ref': clientRef,
        'provider_uid': providerUid,
        'client_uid': clientUid,
        'provider_name': providerName,
        'client_name': clientName,
        'provider_photo': providerPhoto,
        'client_photo': clientPhoto,
        'chat_ref': widget.chatRef,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Send special chat message
      final messageText = '__order__:${orderRef.id}';
      await ChatMessagesRecord.collection.doc().set(
          createChatMessagesRecordData(
            user: currentUserReference,
            chat: widget.chatRef,
            text: messageText,
            timestamp: getCurrentTimestamp,
            isRead: false,
          ));

      // 3. Update chat preview
      final chatUpdate = createChatsRecordData(
        lastMessageTime: getCurrentTimestamp,
        lastMessageSentBy: currentUserReference,
        lastMessage: '💰 Payment request: $title',
      );
      chatUpdate['last_message_seen_by'] = [currentUserReference];
      await widget.chatRef!.update(chatUpdate);
    } catch (e) {
      _showSnackBar('Failed to send invoice: ${e.toString()}');
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        onSelected: (country) {
          _model.textField11TextController?.text =
              (_model.textField11TextController?.text ?? '') + country;
          safeSetState(() {});
        },
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear chat',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'All messages in this conversation will be permanently deleted.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.ubuntu(
                    color: FlutterFlowTheme.of(context).secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.ubuntu(
                    color: FlutterFlowTheme.of(context).error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    safeSetState(() => _isClearing = true);

    // Show a progress dialog so the user knows something is happening
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                const SizedBox(height: 16),
                Text('Deleting messages...',
                    style: GoogleFonts.ubuntu(
                        color: FlutterFlowTheme.of(context).primaryText)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch directly from server — bypass local cache completely
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_messages')
          .where('chat', isEqualTo: widget.chatRef)
          .get(const GetOptions(source: Source.server));

      final docs = snapshot.docs;
      debugPrint('[ClearChat] deleting ${docs.length} messages');

      // Commit in chunks of 400 (Firestore batch limit is 500)
      const chunkSize = 400;
      for (int i = 0; i < docs.length; i += chunkSize) {
        final end = (i + chunkSize < docs.length) ? i + chunkSize : docs.length;
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Reset the chat preview fields
      await widget.chatRef!.update({
        'last_message': '',
        'last_message_time': FieldValue.delete(),
        'last_message_sent_by': FieldValue.delete(),
        'last_message_seen_by': [],
      });
    } catch (e) {
      debugPrint('[ClearChat] error: $e');
      if (mounted) _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // close progress dialog
        safeSetState(() => _isClearing = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildComposer(BuildContext context) {
    if (_isRecording) {
      return Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(
              Icons.fiber_manual_record_rounded,
              color: FlutterFlowTheme.of(context).error,
              size: 14.0,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                'Recording... ${_formatDuration(_recordingDuration)}',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.ubuntu(),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            Text(
              'Tap again to stop',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.ubuntu(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      );
    }

    // ── Location preview ───────────────────────────────────────────────
    if (_hasPendingLocation) {
      final lat = _pendingLocation!['lat']!;
      final lng = _pendingLocation!['lng']!;
      final theme = FlutterFlowTheme.of(context);
      return Container(
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Color(0xFF26A69A), size: 20.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Location',
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                    style: theme.bodySmall.override(
                      font: GoogleFonts.ubuntu(),
                      color: theme.secondaryText,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Tap ➤ to send',
              style: theme.bodySmall.override(
                font: GoogleFonts.ubuntu(),
                color: theme.secondaryText,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasRecordedPreview) {
      final previewPath = _recordedAudioPath!;
      final isPlayingPreview = _playingAudioSource == previewPath &&
          _playerState == ap.PlayerState.playing;
      return Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: _isUploadingVoice
                  ? null
                  : () => _toggleAudioPlayback(previewPath),
              child: Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlayingPreview
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 22.0,
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice message ready',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Preview it, then tap send',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.ubuntu(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              _formatDuration(_recordingDuration),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.ubuntu(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: TextFormField(
        controller: _model.textField11TextController,
        focusNode: _model.textField11FocusNode,
        onChanged: (_) => EasyDebounce.debounce(
          '_model.textField11TextController',
          const Duration(milliseconds: 200),
          () => safeSetState(() {}),
        ),
        textCapitalization: TextCapitalization.sentences,
        obscureText: false,
        maxLines: 5,
        minLines: 1,
        decoration: InputDecoration(
          hintText: 'Message',
          hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.ubuntu(),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
              ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        ),
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.ubuntu(),
              fontSize: 15.0,
              letterSpacing: 0.0,
            ),
        validator:
            _model.textField11TextControllerValidator.asValidator(context),
      ),
    );
  }

  Widget _buildMessageBody(
    BuildContext context,
    ChatMessagesRecord message,
    bool isMine,
  ) {
    // ── Voice message ────────────────────────────────────────────────────
    if (message.hasAudio() && message.audio.isNotEmpty) {
      final isPlayingThisMessage = _playingAudioSource == message.audio &&
          _playerState == ap.PlayerState.playing;
      final titleColor =
          isMine ? Colors.white : FlutterFlowTheme.of(context).primaryText;
      final subtitleColor = isMine
          ? Colors.white.withValues(alpha: 0.78)
          : FlutterFlowTheme.of(context).secondaryText;

      return GestureDetector(
        onTap: () => _toggleAudioPlayback(message.audio),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 170.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.18)
                      : FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlayingThisMessage
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isMine
                      ? Colors.white
                      : FlutterFlowTheme.of(context).primary,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice message',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                          color: titleColor,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    isPlayingThisMessage ? 'Tap to pause' : 'Tap to play',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.ubuntu(),
                          color: subtitleColor,
                          letterSpacing: 0.0,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ── Video message ────────────────────────────────────────────────────
    if (message.hasVideo() && message.video.isNotEmpty) {
      final accent =
          isMine ? Colors.white.withValues(alpha: 0.18) : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12);
      final iconColor =
          isMine ? Colors.white : FlutterFlowTheme.of(context).primary;
      final textColor =
          isMine ? Colors.white : FlutterFlowTheme.of(context).primaryText;
      final subColor = isMine
          ? Colors.white.withValues(alpha: 0.75)
          : FlutterFlowTheme.of(context).secondaryText;
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 170.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(Icons.videocam_rounded, color: iconColor, size: 20.0),
            ),
            const SizedBox(width: 10.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                          color: textColor,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        )),
                Text('Video message',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.ubuntu(),
                          color: subColor,
                          letterSpacing: 0,
                        )),
              ],
            ),
          ],
        ),
      );
    }

    // ── Image or File message ─────────────────────────────────────────────
    if (message.hasImage() && message.image.isNotEmpty) {
      // If it's a file (non-image extension), show a file card
      if (!_isImagePath(message.image)) {
        final fileName = message.text.isNotEmpty
            ? message.text
            : message.image.split('/').last;
        final textColor =
            isMine ? Colors.white : FlutterFlowTheme.of(context).primaryText;
        final subColor = isMine
            ? Colors.white.withValues(alpha: 0.75)
            : FlutterFlowTheme.of(context).secondaryText;
        final iconBg = isMine
            ? Colors.white.withValues(alpha: 0.18)
            : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12);
        final iconColor =
            isMine ? Colors.white : FlutterFlowTheme.of(context).primary;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 170.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.0,
                height: 36.0,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child:
                    Icon(Icons.insert_drive_file_rounded, color: iconColor, size: 20.0),
              ),
              const SizedBox(width: 10.0),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font:
                                GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                            color: textColor,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text('File',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.ubuntu(),
                              color: subColor,
                              letterSpacing: 0,
                            )),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // It's an image — render the photo
      final imageFile = File(message.image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: imageFile.existsSync()
            ? Image.file(imageFile,
                width: 200.0, height: 200.0, fit: BoxFit.cover)
            : Image.network(message.image,
                width: 200.0, height: 200.0, fit: BoxFit.cover),
      );
    }

    // ── Location card ─────────────────────────────────────────────────
    if (message.text.startsWith('__location__:')) {
      final parts =
          message.text.substring('__location__:'.length).split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]) ?? 0.0;
        final lng = double.tryParse(parts[1]) ?? 0.0;
        final label = parts.length >= 3 ? parts.sublist(2).join(',') : 'Location';
        return _LocationBubble(lat: lat, lng: lng, label: label, isMine: isMine);
      }
    }

    // ── Order / Invoice card ────────────────────────────────────────────
    if (message.text.startsWith('__order__:')) {
      final orderId = message.text.substring('__order__:'.length);
      return _OrderBubble(orderId: orderId, isMine: isMine);
    }

    // ── Plain text ───────────────────────────────────────────────────────
    final hasTranslation =
        !isMine && message.translatedText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.text,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.ubuntu(),
                color: isMine
                    ? Colors.white
                    : FlutterFlowTheme.of(context).primaryText,
                fontSize: 15.0,
                letterSpacing: 0.0,
              ),
        ),
        if (hasTranslation) ...[
          const SizedBox(height: 4.0),
          Text(
            message.translatedText,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.ubuntu(fontStyle: FontStyle.italic),
                  color: FlutterFlowTheme.of(context)
                      .secondaryText
                      .withValues(alpha: 0.75),
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (_hasPendingLocation) {
      await _sendPendingLocation();
      return;
    }

    if (_hasTypedMessage) {
      await _sendTextMessage();
      return;
    }

    if (_isRecording) {
      await _stopVoiceRecording();
      return;
    }

    if (_hasRecordedPreview) {
      await _sendRecordedVoice();
      return;
    }

    await _startVoiceRecording();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatsRecord>(
      stream: ChatsRecord.getDocument(widget.chatRef!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitFadingCube(
                  color: FlutterFlowTheme.of(context).primary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final messageChatsRecord = snapshot.data!;
        final isUserA = currentUserReference == messageChatsRecord.userA;
        final otherName = isUserA
            ? messageChatsRecord.userBName
            : messageChatsRecord.userAName;
        final otherPhoto = isUserA
            ? messageChatsRecord.userBPhoto
            : messageChatsRecord.userAPhoto;
        final lastActive = dateTimeFormat(
          "relative",
          messageChatsRecord.lastMessageTime,
          locale: FFLocalizations.of(context).languageShortCode ??
              FFLocalizations.of(context).languageCode,
        );

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              elevation: 0.5,
              shadowColor: Colors.black12,
              titleSpacing: 0,
              title: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 24.0,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  // Avatar
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final otherRef = isUserA
                          ? messageChatsRecord.userB
                          : messageChatsRecord.userA;
                      if (otherRef != null) {
                        UserProfileSheetWidget.show(
                          context,
                          userRef: otherRef,
                          userName: otherName,
                          userPhoto: otherPhoto,
                        );
                      }
                    },
                    child: Container(
                      width: 42.0,
                      height: 42.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: otherPhoto.isNotEmpty
                            ? Image.network(otherPhoto,
                                width: 42.0, height: 42.0, fit: BoxFit.cover)
                            : Container(
                                color: FlutterFlowTheme.of(context).accent1,
                                child: Icon(Icons.person_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 22.0),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  // Name + last active
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          otherName,
                          style:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.ubuntu(
                                        fontWeight: FontWeight.w600),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lastActive,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.ubuntu(),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 12.0,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _CallingDialog(
                        name: otherName,
                        photoUrl: otherPhoto,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.phone_outlined,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 22.0,
                  ),
                ),
                // Payment request button — providers only
                if (currentUserDocument?.role == 'service_provider')
                  IconButton(
                    onPressed: () => _showSendOrderSheet(messageChatsRecord),
                    tooltip: 'Send Invoice',
                    icon: Icon(
                      Icons.request_page_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 22.0,
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 22.0,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) async {
                    if (value == 'clear_chat') {
                      await _clearChat();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'clear_chat',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded,
                              size: 20,
                              color: FlutterFlowTheme.of(context).error),
                          const SizedBox(width: 12),
                          Text('Clear chat',
                              style: GoogleFonts.ubuntu(
                                  color: FlutterFlowTheme.of(context).error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Messages list
                Expanded(
                  child: StreamBuilder<List<ChatMessagesRecord>>(
                    stream: queryChatMessagesRecord(
                      queryBuilder: (chatMessagesRecord) => chatMessagesRecord
                          .where('chat', isEqualTo: widget.chatRef)
                          .orderBy('timestamp', descending: true),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: SizedBox(
                            width: 40.0,
                            height: 40.0,
                            child: SpinKitFadingCube(
                              color: FlutterFlowTheme.of(context).primary,
                              size: 40.0,
                            ),
                          ),
                        );
                      }
                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet.\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.ubuntu(),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 16.0),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMine = msg.user == currentUserReference;
                          final hasAudio =
                              msg.hasAudio() && msg.audio.isNotEmpty;
                          final time = dateTimeFormat(
                            "Hm",
                            msg.timestamp,
                            locale:
                                FFLocalizations.of(context).languageShortCode ??
                                    FFLocalizations.of(context).languageCode,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMine) ...[
                                  CircleAvatar(
                                    radius: 14.0,
                                    backgroundImage: otherPhoto.isNotEmpty
                                        ? NetworkImage(otherPhoto)
                                        : null,
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).accent1,
                                    child: otherPhoto.isEmpty
                                        ? Icon(Icons.person_rounded,
                                            size: 14.0,
                                            color: FlutterFlowTheme.of(context)
                                                .primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 6.0),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.sizeOf(context).width *
                                                  0.65,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          borderRadius: BorderRadius.only(
                                            topLeft:
                                                const Radius.circular(18.0),
                                            topRight:
                                                const Radius.circular(18.0),
                                            bottomLeft: Radius.circular(
                                                isMine ? 18.0 : 4.0),
                                            bottomRight: Radius.circular(
                                                isMine ? 4.0 : 18.0),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.06),
                                              blurRadius: 4.0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14.0, vertical: 10.0),
                                          child: _buildMessageBody(
                                            context,
                                            msg,
                                            isMine,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3.0),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            time,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.ubuntu(),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  fontSize: 11.0,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                          if (isMine) ...[
                                            const SizedBox(width: 3.0),
                                            Icon(
                                              hasAudio
                                                  ? Icons.graphic_eq_rounded
                                                  : Icons.done_all_rounded,
                                              size: 14.0,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMine) const SizedBox(width: 4.0),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Input bar
                Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8.0,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: _isRecording
                                  ? null
                                  : _hasRecordedPreview && !_isUploadingVoice
                                      ? _discardRecordedVoice
                                      : _hasPendingLocation
                                          ? () => setState(() => _pendingLocation = null)
                                          : !_hasRecordedPreview
                                              ? _showAttachmentSheet
                                              : null,
                              child: Icon(
                                _hasRecordedPreview || _hasPendingLocation
                                    ? Icons.delete_outline_rounded
                                    : Icons.attach_file_rounded,
                                color: _hasRecordedPreview || _hasPendingLocation
                                    ? FlutterFlowTheme.of(context).error
                                    : _isRecording
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryText
                                            .withValues(alpha: 0.35)
                                        : FlutterFlowTheme.of(context)
                                            .primary,
                                size: 24.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: _buildComposer(context),
                          ),
                          const SizedBox(width: 8.0),
                          GestureDetector(
                            onTap:
                                _isUploadingVoice ? null : _handlePrimaryAction,
                            child: Container(
                              width: 44.0,
                              height: 44.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                shape: BoxShape.circle,
                              ),
                              child: _isUploadingVoice
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _hasTypedMessage || _hasRecordedPreview || _hasPendingLocation
                                          ? Icons.send_rounded
                                          : _isRecording
                                              ? Icons.stop_rounded
                                              : Icons.mic_rounded,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// In-app calling overlay
// ---------------------------------------------------------------------------
class _CallingDialog extends StatefulWidget {
  const _CallingDialog({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  State<_CallingDialog> createState() => _CallingDialogState();
}

class _CallingDialogState extends State<_CallingDialog> {
  late final Timer _timer;
  int _seconds = 0;
  bool _callStarted = false;

  @override
  void initState() {
    super.initState();
    // Simulate ringing for 3 seconds then connect
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _callStarted = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
      });
    });
  }

  @override
  void dispose() {
    if (_callStarted) _timer.cancel();
    super.dispose();
  }

  String get _timeLabel {
    if (!_callStarted) return 'Calling...';
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 46,
              backgroundImage: widget.photoUrl.isNotEmpty
                  ? NetworkImage(widget.photoUrl)
                  : null,
              backgroundColor:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
              child: widget.photoUrl.isEmpty
                  ? Icon(Icons.person_rounded,
                      size: 46, color: FlutterFlowTheme.of(context).primary)
                  : null,
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Status / timer
            Text(
              _timeLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 36),
            // End call button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Country picker bottom sheet
// ---------------------------------------------------------------------------
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  static const _allCountries = [
    '🇧🇭 Bahrain', '🇸🇦 Saudi Arabia', '🇦🇪 UAE', '🇰🇼 Kuwait',
    '🇶🇦 Qatar', '🇴🇲 Oman', '🇯🇴 Jordan', '🇪🇬 Egypt',
    '🇮🇶 Iraq', '🇱🇧 Lebanon', '🇾🇪 Yemen', '🇸🇾 Syria',
    '🇵🇦 Pakistan', '🇮🇳 India', '🇵🇭 Philippines', '🇧🇩 Bangladesh',
    '🇳🇵 Nepal', '🇱🇰 Sri Lanka', '🇬🇧 UK', '🇺🇸 USA',
    '🇨🇦 Canada', '🇦🇺 Australia', '🇩🇪 Germany', '🇫🇷 France',
    '🇮🇹 Italy', '🇪🇸 Spain', '🇳🇱 Netherlands', '🇹🇷 Turkey',
    '🇲🇾 Malaysia', '🇸🇬 Singapore', '🇮🇩 Indonesia', '🇵🇸 Palestine',
    '🇲🇦 Morocco', '🇹🇳 Tunisia', '🇩🇿 Algeria', '🇱🇾 Libya',
    '🇸🇩 Sudan', '🇸🇴 Somalia', '🇪🇹 Ethiopia', '🇿🇦 South Africa',
  ];

  String _query = '';
  final _searchController = TextEditingController();

  List<String> get _filtered => _query.isEmpty
      ? _allCountries
      : _allCountries
          .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Choose Country',
                style: GoogleFonts.ubuntu(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: GoogleFonts.ubuntu(
                      color: theme.secondaryText, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: theme.secondaryText),
                  filled: true,
                  fillColor: theme.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: GoogleFonts.ubuntu(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final country = _filtered[i];
                  return ListTile(
                    title: Text(country,
                        style: GoogleFonts.ubuntu(
                            fontSize: 15, color: theme.primaryText)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelected(country);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attachment options bottom sheet
// ---------------------------------------------------------------------------
class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onVideo,
    required this.onFile,
    required this.onLocation,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onVideo;
  final VoidCallback onFile;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.alternate,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Share',
            style: GoogleFonts.ubuntu(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          // Row 1: Camera, Gallery, Video, File
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFF5B8AF5),
                onTap: onCamera,
              ),
              _AttachOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF4CAF50),
                onTap: onGallery,
              ),
              _AttachOption(
                icon: Icons.videocam_rounded,
                label: 'Video',
                color: const Color(0xFFE53935),
                onTap: onVideo,
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'File',
                color: const Color(0xFFFB8C00),
                onTap: onFile,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachOption(
                icon: Icons.location_on_rounded,
                label: 'Location',
                color: const Color(0xFF26A69A),
                onTap: onLocation,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Location bubble ─────────────────────────────────────────────────────────

class _LocationBubble extends StatelessWidget {
  const _LocationBubble({
    required this.lat,
    required this.lng,
    required this.label,
    required this.isMine,
  });

  final double lat;
  final double lng;
  final String label;
  final bool isMine;

  Future<void> _openMap() async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bgColor = isMine
        ? Colors.white.withValues(alpha: 0.15)
        : theme.secondaryBackground;
    final textColor = isMine ? Colors.white : theme.primaryText;
    final subColor = isMine
        ? Colors.white.withValues(alpha: 0.75)
        : theme.secondaryText;
    final iconColor = isMine ? Colors.white : const Color(0xFF26A69A);
    final iconBg = isMine
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFF26A69A).withValues(alpha: 0.12);

    return GestureDetector(
      onTap: _openMap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isMine ? null : Border.all(color: theme.alternate, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Map illustration area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: 220,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMine
                        ? [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.08),
                          ]
                        : [
                            const Color(0xFF26A69A).withValues(alpha: 0.12),
                            const Color(0xFF26A69A).withValues(alpha: 0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid lines to suggest a map
                    CustomPaint(
                      size: const Size(220, 110),
                      painter: _MapGridPainter(
                          lineColor: isMine
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFF26A69A).withValues(alpha: 0.15)),
                    ),
                    // Pin icon
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(Icons.location_on_rounded,
                              color: iconColor, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Tap to open map',
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom info strip
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(Icons.location_on_rounded,
                        color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                          style: GoogleFonts.ubuntu(
                              fontSize: 10, color: subColor),
                        ),
                      ],
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
}

// Simple grid painter to give the map illustration context
class _MapGridPainter extends CustomPainter {
  final Color lineColor;
  const _MapGridPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.lineColor != lineColor;
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order bubble (in-chat order card)
// ---------------------------------------------------------------------------
class _OrderBubble extends StatelessWidget {
  const _OrderBubble({required this.orderId, required this.isMine});
  final String orderId;
  final bool isMine;

  static const _statusCfg = {
    'pending': (color: Color(0xFFFF9800), label: 'Awaiting Confirmation',
        icon: Icons.access_time_rounded),
    'confirmed': (color: Color(0xFF2196F3), label: 'Confirmed',
        icon: Icons.check_circle_outline_rounded),
    'partially_paid': (color: Color(0xFF9C27B0), label: 'Partially Paid',
        icon: Icons.payments_outlined),
    'paid': (color: Color(0xFF4CAF50), label: 'Fully Paid',
        icon: Icons.payment_rounded),
    'in_progress': (color: Color(0xFF9C27B0), label: 'In Progress',
        icon: Icons.work_outline_rounded),
    'completed': (color: Color(0xFF4CAF50), label: 'Completed',
        icon: Icons.check_circle_rounded),
    'cancelled': (color: Color(0xFFF44336), label: 'Cancelled',
        icon: Icons.cancel_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: 200,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(isMine ? Colors.white : theme.primary),
              ),
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return Text('Order not found',
              style: GoogleFonts.ubuntu(
                  color: isMine ? Colors.white : theme.primaryText));
        }

        final status = data['status'] as String? ?? 'pending';
        final cfg = _statusCfg[status] ??
            (color: const Color(0xFF9E9E9E),
            label: status,
            icon: Icons.help_outline_rounded);
        final title = data['title'] as String? ?? 'Service Order';
        final description = data['description'] as String? ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final currency = data['currency'] as String? ?? 'BHD';
        final deliveryDays = data['delivery_days'] as int? ?? 0;
        final installmentsTotal = data['installments_total'] as int? ?? 1;
        final installmentsPaid = data['installments_paid'] as int? ?? 0;
        final installmentAmount =
            (data['installment_amount'] as num?)?.toDouble() ?? amount;
        final monthsCompleted = data['months_completed'] as int? ?? 0;
        final providerUid = data['provider_uid'] as String? ?? '';
        final isProvider = currentUserUid == providerUid;

        final cardBg = isMine
            ? Colors.white.withValues(alpha: 0.12)
            : theme.primaryBackground;
        final textColor =
            isMine ? Colors.white : theme.primaryText;
        final subColor = isMine
            ? Colors.white.withValues(alpha: 0.75)
            : theme.secondaryText;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Icon(cfg.icon, size: 13, color: cfg.color),
                    const SizedBox(width: 5),
                    Text(cfg.label,
                        style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cfg.color)),
                    const Spacer(),
                    Icon(Icons.receipt_long_rounded,
                        size: 14, color: subColor),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Main content
              Text(title,
                  style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ubuntu(fontSize: 12, color: subColor)),
              ],
              const SizedBox(height: 8),
              // Offer details row
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: subColor),
                  const SizedBox(width: 4),
                  Text('$deliveryDays day${deliveryDays == 1 ? '' : 's'} delivery',
                      style: GoogleFonts.ubuntu(
                          fontSize: 11, color: subColor)),
                  const Spacer(),
                  Text('$amount $currency',
                      style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMine ? Colors.white : theme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showOrderDetail(context, data),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.4)
                                : theme.alternate),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('View',
                          style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: isMine ? Colors.white : theme.primaryText)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionButton(
                        context, status, isProvider, isMine, theme, data,
                        installmentsPaid: installmentsPaid,
                        installmentsTotal: installmentsTotal,
                        installmentAmount: installmentAmount,
                        monthsCompleted: monthsCompleted,
                        currency: currency,
                        amount: amount),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String status,
    bool isProvider,
    bool isMine,
    FlutterFlowTheme theme,
    Map<String, dynamic> data, {
    required int installmentsPaid,
    required int installmentsTotal,
    required double installmentAmount,
    required int monthsCompleted,
    required String currency,
    required double amount,
  }) {
    String fmt(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

    // Client can pay whenever there are still unpaid months
    final canPayNext = installmentsPaid < installmentsTotal;
    final canMarkMonth = isProvider &&
        installmentsPaid > monthsCompleted &&
        monthsCompleted < installmentsTotal;
    final allMonthsDone = monthsCompleted >= installmentsTotal;
    final currentWorkMonth = monthsCompleted + 1;

    // ── CLIENT ──────────────────────────────────────────────────────────────
    if (!isProvider) {
      // Pending → Confirm
      if (status == 'pending') {
        return FilledButton(
          onPressed: () => _confirmOrder(context, theme),
          style: FilledButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Confirm',
              style: GoogleFonts.ubuntu(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        );
      }
      // Confirmed / partially paid → Pay (if unlocked) or waiting
      if (status == 'confirmed' || status == 'partially_paid') {
        if (canPayNext) {
          final isFirst = installmentsPaid == 0 && installmentsTotal > 1;
          final label = isFirst
              ? 'Pay / Choose'
              : 'Pay ${fmt(installmentAmount)} $currency';
          return FilledButton(
            onPressed: () => _handlePayment(context, theme, installmentsPaid,
                installmentsTotal, installmentAmount, amount, currency),
            style: FilledButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          );
        }
        return _StatusLabel(
            label: 'Waiting M$currentWorkMonth',
            color: const Color(0xFFFF9800));
      }
    }

    // ── PROVIDER ─────────────────────────────────────────────────────────────
    if (isProvider) {
      if (status == 'pending') {
        return _StatusLabel(label: 'Pending', color: const Color(0xFFFF9800));
      }
      if (status == 'confirmed') {
        return _StatusLabel(
            label: 'Awaiting Pay', color: const Color(0xFF2196F3));
      }
      if (status == 'partially_paid' || status == 'paid') {
        if (canMarkMonth) {
          return FilledButton(
            onPressed: () =>
                _markMonthComplete(context, theme, currentWorkMonth),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('M$currentWorkMonth Done',
                style: GoogleFonts.ubuntu(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          );
        }
        if (allMonthsDone) {
          return FilledButton(
            onPressed: () => _markDelivered(context, theme),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Delivered',
                style: GoogleFonts.ubuntu(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          );
        }
        return _StatusLabel(
            label: 'Waiting pay', color: const Color(0xFF9E9E9E));
      }
      if (status == 'in_progress') {
        return FilledButton(
          onPressed: () => _markDelivered(context, theme),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Delivered',
              style: GoogleFonts.ubuntu(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        );
      }
    }

    // Status label (no action)
    final cfg = const {
          'paid': (label: 'Paid ✓', color: Color(0xFF4CAF50)),
          'completed': (label: 'Completed ✓', color: Color(0xFF4CAF50)),
          'cancelled': (label: 'Cancelled', color: Color(0xFFF44336)),
        }[status] ??
        (label: status, color: Color(0xFF9E9E9E));
    return _StatusLabel(label: cfg.label, color: cfg.color);
  }

  void _confirmOrder(BuildContext context, FlutterFlowTheme theme) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Order?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'Accept this service request? Payment will be required after.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.ubuntu(color: theme.secondaryText))),
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
    ).then((ok) async {
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
                content:
                    Text('Order confirmed!', style: GoogleFonts.ubuntu()),
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
    });
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
    String fmt(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

    final isInstallment = installmentsTotal > 1;
    final title =
        (await FirebaseFirestore.instance.collection('orders').doc(orderId).get())
                .data()?['title'] as String? ??
            'Service Order';
    if (!context.mounted) return;

    final remainingMonths = installmentsTotal - installmentsPaid;
    final remainingTotal = installmentAmount * remainingMonths;

    // Installment order → always show full vs monthly choice
    if (isInstallment) {
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
                    const SizedBox(height: 18),
                    // ── Pay Full Amount ──────────────────────────────────
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop('full'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
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
                                            color:
                                                theme.secondaryText)),
                                  ],
                                ),
                              ),
                              Text('${fmt(remainingTotal)} $currency',
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
                    // ── Pay Monthly (with counter) ───────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
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
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: theme.secondaryText,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text('Pay Monthly',
                                  style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('How many months to pay now?',
                              style: GoogleFonts.ubuntu(
                                  fontSize: 12,
                                  color: theme.secondaryText)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: monthCount > 1
                                    ? () =>
                                        setSheet(() => monthCount--)
                                    : null,
                                icon: Icon(
                                    Icons
                                        .remove_circle_outline_rounded,
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
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$monthCount month${monthCount > 1 ? 's' : ''}',
                                  style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    monthCount < remainingMonths
                                        ? () => setSheet(
                                            () => monthCount++)
                                        : null,
                                icon: Icon(
                                    Icons.add_circle_outline_rounded,
                                    color:
                                        monthCount < remainingMonths
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
                                      fontSize: 12)),
                              Text(
                                  '${fmt(partialTotal)} $currency',
                                  style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: theme.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                                  'Pay ${fmt(partialTotal)} $currency',
                                  style: GoogleFonts.ubuntu(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
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

      final int selectedMonths = choice == 'full'
          ? remainingMonths
          : (int.tryParse(choice) ?? 1);
      final double payAmt = choice == 'full'
          ? remainingTotal
          : installmentAmount * selectedMonths;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
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
                Text('${fmt(payAmt)} $currency',
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
                  style:
                      GoogleFonts.ubuntu(color: theme.secondaryText)),
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
                  style:
                      GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
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
                content:
                    Text('Error: $e', style: GoogleFonts.ubuntu())));
        }
      }
      return;
    }

    // Single (non-installment) payment
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Payment',
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
              Text('Total:', style: GoogleFonts.ubuntu()),
              Text('${fmt(totalAmount)} $currency',
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
                  style: GoogleFonts.ubuntu(color: theme.secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
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
        'installments_paid': 1,
        'status': 'paid',
        'paid_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Payment done! ✅', style: GoogleFonts.ubuntu()),
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

  void _showOrderDetail(BuildContext context, Map<String, dynamic> data) {
    final providerUid = data['provider_uid'] as String? ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailInChat(
          orderId: orderId,
          data: data,
          isProvider: currentUserUid == providerUid),
    );
  }

  void _markMonthComplete(
      BuildContext context, FlutterFlowTheme theme, int monthNum) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Month $monthNum Complete?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text(
            'Confirm Month $monthNum work is done. The client will be notified to pay the next installment.',
            style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.ubuntu(color: theme.secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((ok) async {
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
              content: Text('Month $monthNum done ✅',
                  style: GoogleFonts.ubuntu()),
              backgroundColor: const Color(0xFF2196F3),
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
    });
  }

  Future<void> _markDelivered(
      BuildContext context, FlutterFlowTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark as Delivered?',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text('Confirm delivery to the client?',
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text('Error: $e', style: GoogleFonts.ubuntu())));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Status label chip (no action)
// ---------------------------------------------------------------------------
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

// ---------------------------------------------------------------------------
// Order detail sheet (from chat bubble)
// ---------------------------------------------------------------------------
class _OrderDetailInChat extends StatelessWidget {
  const _OrderDetailInChat(
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
    final statusCfg = switch (status) {
      'pending' => (color: const Color(0xFFFF9800), label: 'Pending Payment'),
      'paid' => (color: const Color(0xFF2196F3), label: 'Paid'),
      'in_progress' => (color: const Color(0xFF9C27B0), label: 'In Progress'),
      'completed' => (color: const Color(0xFF4CAF50), label: 'Completed'),
      'cancelled' => (color: const Color(0xFFF44336), label: 'Cancelled'),
      _ => (color: const Color(0xFF9E9E9E), label: status),
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
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
                    color: theme.alternate, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Order Details',
                      style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusCfg.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusCfg.label,
                      style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusCfg.color)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(description,
                  style: GoogleFonts.ubuntu(
                      fontSize: 14, color: theme.secondaryText)),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _Row(icon: Icons.person_rounded, label: 'Provider', value: providerName),
            _Row(icon: Icons.person_outline_rounded, label: 'Client', value: clientName),
            _Row(
                icon: Icons.payments_rounded,
                label: 'Amount',
                value: '$amount $currency',
                valueColor: theme.primary),
            _Row(
                icon: Icons.schedule_rounded,
                label: 'Delivery',
                value: '$deliveryDays day${deliveryDays == 1 ? '' : 's'}'),
            if (createdAt != null)
              _Row(
                  icon: Icons.calendar_today_rounded,
                  label: 'Created',
                  value:
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
            if (paidAt != null)
              _Row(
                  icon: Icons.check_circle_rounded,
                  label: 'Paid On',
                  value: '${paidAt.day}/${paidAt.month}/${paidAt.year}',
                  valueColor: const Color(0xFF4CAF50)),
            if (completedAt != null)
              _Row(
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
                child: Text(notes,
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: theme.secondaryText)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
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

// ---------------------------------------------------------------------------
// Send Order / Invoice bottom sheet
// ---------------------------------------------------------------------------
typedef _SendOrderCallback = Future<void> Function({
  required String title,
  required String description,
  required double amount,
  required String currency,
  required int deliveryDays,
  required String notes,
});

class _SendOrderSheet extends StatefulWidget {
  const _SendOrderSheet({required this.onSend});
  final _SendOrderCallback onSend;

  @override
  State<_SendOrderSheet> createState() => _SendOrderSheetState();
}

class _SendOrderSheetState extends State<_SendOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '3');
  final _notesCtrl = TextEditingController();
  // Currency is fixed to BHD
  bool _isSending = false;

  static const _currency = 'BHD';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _daysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      await widget.onSend(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
        currency: _currency,
        deliveryDays: int.tryParse(_daysCtrl.text.trim()) ?? 1,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.request_page_rounded,
                          color: theme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Send Payment Request',
                        style: GoogleFonts.ubuntu(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText)),
                  ],
                ),
                const SizedBox(height: 20),
                // Service title
                _label(context, 'Service Title *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(
                      context, 'e.g. House Cleaning Service'),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                // Description
                _label(context, 'Description'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration(
                      context, 'Describe the service you will provide...'),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                ),
                const SizedBox(height: 14),
                // Amount (BHD)
                _label(context, 'Amount (BHD) *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration:
                      _inputDecoration(context, '0.00'),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Delivery days
                _label(context, 'Delivery Days *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(context, '1'),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) return 'Must be ≥ 1';
                    if (n > 730) return 'Max 730 days (2 years)';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Notes
                _label(context, 'Notes (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: _inputDecoration(context, 'Any special notes...'),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSending ? null : _submit,
                    icon: _isSending
                        ? Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 4),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                        _isSending ? 'Sending...' : 'Send Invoice',
                        style: GoogleFonts.ubuntu(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(text,
      style: GoogleFonts.ubuntu(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FlutterFlowTheme.of(context).primaryText));

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.ubuntu(color: theme.secondaryText, fontSize: 13),
      filled: true,
      fillColor: theme.primaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.alternate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.alternate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.error),
      ),
    );
  }
}
