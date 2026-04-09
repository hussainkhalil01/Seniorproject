import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "full_name" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  bool hasFullName() => _fullName != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "role" field.
  String? _role;
  String get role => _role ?? '';
  bool hasRole() => _role != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "short_description" field.
  String? _shortDescription;
  String get shortDescription => _shortDescription ?? '';
  bool hasShortDescription() => _shortDescription != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "categories" field.
  List<String>? _categories;
  List<String> get categories => _categories ?? const [];
  bool hasCategories() => _categories != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "last_active_time" field.
  DateTime? _lastActiveTime;
  DateTime? get lastActiveTime => _lastActiveTime;
  bool hasLastActiveTime() => _lastActiveTime != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "is_online" field.
  bool? _isOnline;
  bool get isOnline => _isOnline ?? false;
  bool hasIsOnline() => _isOnline != null;

  // "is_disabled" field.
  bool? _isDisabled;
  bool get isDisabled => _isDisabled ?? false;
  bool hasIsDisabled() => _isDisabled != null;

  // "preferred_language" field.
  String? _preferredLanguage;
  String get preferredLanguage => _preferredLanguage ?? '';
  bool hasPreferredLanguage() => _preferredLanguage != null;

  void _initializeFields() {
    _uid = snapshotData['uid'] as String?;
    _fullName = snapshotData['full_name'] as String?;
    _email = snapshotData['email'] as String?;
    _role = snapshotData['role'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _shortDescription = snapshotData['short_description'] as String?;
    _title = snapshotData['title'] as String?;
    _categories = getDataList(snapshotData['categories']);
    _phoneNumber = snapshotData['phone_number'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _lastActiveTime = snapshotData['last_active_time'] as DateTime?;
    _displayName = snapshotData['display_name'] as String?;
    _isOnline = snapshotData['is_online'] as bool?;
    _isDisabled = snapshotData['is_disabled'] as bool?;
    _preferredLanguage = snapshotData['preferred_language'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? uid,
  String? fullName,
  String? email,
  String? role,
  String? photoUrl,
  String? shortDescription,
  String? title,
  String? phoneNumber,
  DateTime? createdTime,
  DateTime? lastActiveTime,
  String? displayName,
  bool? isOnline,
  bool? isDisabled,
  String? preferredLanguage,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'role': role,
      'photo_url': photoUrl,
      'short_description': shortDescription,
      'title': title,
      'phone_number': phoneNumber,
      'created_time': createdTime,
      'last_active_time': lastActiveTime,
      'display_name': displayName,
      'is_online': isOnline,
      'is_disabled': isDisabled,
      'preferred_language': preferredLanguage,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    const listEquality = ListEquality();
    return e1?.uid == e2?.uid &&
        e1?.fullName == e2?.fullName &&
        e1?.email == e2?.email &&
        e1?.role == e2?.role &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.shortDescription == e2?.shortDescription &&
        e1?.title == e2?.title &&
        listEquality.equals(e1?.categories, e2?.categories) &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.createdTime == e2?.createdTime &&
        e1?.lastActiveTime == e2?.lastActiveTime &&
        e1?.displayName == e2?.displayName &&
        e1?.isOnline == e2?.isOnline &&
        e1?.isDisabled == e2?.isDisabled &&
        e1?.preferredLanguage == e2?.preferredLanguage;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.uid,
        e?.fullName,
        e?.email,
        e?.role,
        e?.photoUrl,
        e?.shortDescription,
        e?.title,
        e?.categories,
        e?.phoneNumber,
        e?.createdTime,
        e?.lastActiveTime,
        e?.displayName,
        e?.isOnline,
        e?.isDisabled,
        e?.preferredLanguage
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
