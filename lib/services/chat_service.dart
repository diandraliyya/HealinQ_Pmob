import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  User _requireUser() {
    final User? user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return user;
  }

  Future<List<ChatRoomModel>> getMyChatRooms() {
    return _loadRooms();
  }

  Future<ChatRoomModel> getChatRoom(String roomId) async {
    final List<ChatRoomModel> rooms = await _loadRooms(roomId: roomId);

    if (rooms.isEmpty) {
      throw Exception('Room chat tidak ditemukan.');
    }

    return rooms.first;
  }

  Stream<List<ChatMessageModel>> watchMessages(String roomId) {
    final User user = _requireUser();

    return _client
        .from('messages')
        .stream(primaryKey: <String>['id'])
        .eq('room_id', roomId)
        .order(
          'created_at',
          ascending: true,
        )
        .map((List<Map<String, dynamic>> rows) {
      final List<ChatMessageModel> messages = rows
          .map(
            (Map<String, dynamic> row) => ChatMessageModel.fromMap(
              row,
              currentUserId: user.id,
            ),
          )
          .toList();

      /*
       * Sort ulang di sisi Flutter supaya urutan tetap stabil
       * meskipun payload realtime datang tidak berurutan.
       *
       * Pesan lama berada di atas dan pesan terbaru di bawah.
       * ID dipakai sebagai tie-breaker apabila created_at sama.
       */
      messages.sort(
        (
          ChatMessageModel first,
          ChatMessageModel second,
        ) {
          final int timeComparison =
              first.createdAt.compareTo(second.createdAt);

          if (timeComparison != 0) {
            return timeComparison;
          }

          return first.id.compareTo(second.id);
        },
      );

      return messages;
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    _requireUser();

    final String cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      throw Exception('Pesan tidak boleh kosong.');
    }

    if (cleanContent.length > 4000) {
      throw Exception('Pesan maksimal 4000 karakter.');
    }

    try {
      await _client.rpc(
        'send_chat_message',
        params: <String, dynamic>{
          'p_room_id': roomId,
          'p_content': cleanContent,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    }
  }

  Future<void> markMessagesRead(String roomId) async {
    _requireUser();

    try {
      await _client.rpc(
        'mark_chat_messages_read',
        params: <String, dynamic>{
          'p_room_id': roomId,
        },
      );
    } catch (_) {
      // Read receipt tidak boleh membuat room gagal digunakan.
    }
  }

  Future<List<ChatRoomModel>> _loadRooms({String? roomId}) async {
    final User user = _requireUser();

    try {
      await _syncSessionStatusesQuietly();

      final Map<String, dynamic> profile = Map<String, dynamic>.from(
        await _client
            .from('profiles')
            .select('id, role, status')
            .eq('id', user.id)
            .single(),
      );

      final String currentRole = profile['role']?.toString() ?? '';

      if (currentRole != 'user' && currentRole != 'counselor') {
        throw Exception('Akun ini tidak memiliki akses chat.');
      }

      if (profile['status']?.toString() != 'active') {
        throw Exception('Akun sedang tidak aktif.');
      }

      dynamic roomQuery = _client.from('chat_rooms').select(
            'id, consultation_id, user_id, counselor_id, created_at',
          );

      if (roomId != null) {
        roomQuery = roomQuery.eq('id', roomId);
      }

      final List<dynamic> rawRooms = await roomQuery.order(
        'created_at',
        ascending: false,
      );

      if (rawRooms.isEmpty) {
        return <ChatRoomModel>[];
      }

      final List<Map<String, dynamic>> rooms = rawRooms
          .map(
            (dynamic row) => Map<String, dynamic>.from(row as Map),
          )
          .toList();

      final List<String> consultationIds = rooms
          .map(
            (Map<String, dynamic> room) =>
                room['consultation_id']?.toString() ?? '',
          )
          .where((String id) => id.isNotEmpty)
          .toList();

      final List<String> counselorIds = rooms
          .map(
            (Map<String, dynamic> room) =>
                room['counselor_id']?.toString() ?? '',
          )
          .where((String id) => id.isNotEmpty)
          .toSet()
          .toList();

      final List<String> roomIds = rooms
          .map(
            (Map<String, dynamic> room) => room['id']?.toString() ?? '',
          )
          .where((String id) => id.isNotEmpty)
          .toList();

      final List<dynamic> consultationRows = await _client
          .from('consultations')
          .select(
            'id, booking_code, user_id, counselor_id, consultation_type, '
            'scheduled_start, scheduled_end, notes, status, created_at, updated_at',
          )
          .inFilter('id', consultationIds);

      final List<dynamic> participantRows =
          await _client.rpc(
        'get_my_chat_participants',
        params: <String, dynamic>{
          'p_room_ids': roomIds,
        },
      );

      final List<dynamic> counselorRows = counselorIds.isEmpty
          ? <dynamic>[]
          : await _client
              .from('counselor_profiles')
              .select('id, specialization')
              .inFilter('id', counselorIds);

      final List<dynamic> messageRows = await _client
          .from('messages')
          .select('id, room_id, sender_id, content, created_at, read_at')
          .inFilter('room_id', roomIds)
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> consultationById =
          <String, Map<String, dynamic>>{};
      for (final dynamic raw in consultationRows) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(raw as Map);
        final String id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) consultationById[id] = item;
      }

      final Map<String, Map<String, dynamic>>
          participantByRoom =
          <String, Map<String, dynamic>>{};

      for (final dynamic raw in participantRows) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(raw as Map);

        final String participantRoomId =
            item['room_id']?.toString() ?? '';

        if (participantRoomId.isNotEmpty) {
          participantByRoom[participantRoomId] = item;
        }
      }

      final Map<String, Map<String, dynamic>> counselorById =
          <String, Map<String, dynamic>>{};
      for (final dynamic raw in counselorRows) {
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(raw as Map);
        final String id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) counselorById[id] = item;
      }

      final Map<String, Map<String, dynamic>> latestMessageByRoom =
          <String, Map<String, dynamic>>{};
      final Map<String, int> unreadByRoom = <String, int>{};

      for (final dynamic raw in messageRows) {
        final Map<String, dynamic> message =
            Map<String, dynamic>.from(raw as Map);
        final String messageRoomId = message['room_id']?.toString() ?? '';

        if (messageRoomId.isEmpty) continue;

        latestMessageByRoom.putIfAbsent(
          messageRoomId,
          () => message,
        );

        final bool isUnread =
            message['sender_id']?.toString() != user.id &&
                message['read_at'] == null;

        if (isUnread) {
          unreadByRoom[messageRoomId] =
              (unreadByRoom[messageRoomId] ?? 0) + 1;
        }
      }

      final List<ChatRoomModel> result = <ChatRoomModel>[];

      for (final Map<String, dynamic> room in rooms) {
        final String id = room['id']?.toString() ?? '';
        final String consultationId =
            room['consultation_id']?.toString() ?? '';
        final String userId = room['user_id']?.toString() ?? '';
        final String counselorId = room['counselor_id']?.toString() ?? '';

        final Map<String, dynamic>? consultation =
            consultationById[consultationId];

        if (id.isEmpty || consultation == null) continue;

        final bool counselorView = currentRole == 'counselor';
        final Map<String, dynamic>? otherProfile =
            participantByRoom[id];
        final Map<String, dynamic>? latestMessage = latestMessageByRoom[id];

        final String otherName =
            otherProfile?['full_name']?.toString().trim() ?? '';

        result.add(
          ChatRoomModel(
            roomId: id,
            consultationId: consultationId,
            userId: userId,
            counselorId: counselorId,
            currentRole: currentRole,
            otherParticipantName: otherName.isNotEmpty
                ? otherName
                : counselorView
                    ? 'User'
                    : 'Counselor',
            otherParticipantAvatarPath:
                otherProfile?['avatar_path']?.toString(),
            specialization:
                counselorById[counselorId]?['specialization']?.toString() ?? '',
            bookingCode: consultation['booking_code']?.toString() ?? '-',
            consultationStatus:
                consultation['status']?.toString() ?? 'confirmed',
            scheduledStart: DateTime.parse(
              consultation['scheduled_start'].toString(),
            ).toLocal(),
            scheduledEnd: DateTime.parse(
              consultation['scheduled_end'].toString(),
            ).toLocal(),
            consultationNotes: consultation['notes']?.toString(),
            lastMessage:
                latestMessage?['content']?.toString() ?? 'Belum ada pesan.',
            lastMessageAt: latestMessage?['created_at'] == null
                ? null
                : DateTime.tryParse(
                    latestMessage!['created_at'].toString(),
                  )?.toLocal(),
            unreadCount: unreadByRoom[id] ?? 0,
          ),
        );
      }

      result.sort((ChatRoomModel first, ChatRoomModel second) {
        int rank(ChatRoomModel room) {
          if (room.isActive) return 0;
          if (room.isUpcoming) return 1;
          return 2;
        }

        final int rankCompare = rank(first).compareTo(rank(second));
        if (rankCompare != 0) return rankCompare;

        if (first.isUpcoming && second.isUpcoming) {
          return first.scheduledStart.compareTo(second.scheduledStart);
        }

        final DateTime firstTime =
            first.lastMessageAt ?? first.scheduledStart;
        final DateTime secondTime =
            second.lastMessageAt ?? second.scheduledStart;
        return secondTime.compareTo(firstTime);
      });

      return result;
    } on PostgrestException catch (error) {
      throw Exception(_translateError(error));
    } catch (error) {
      throw Exception(_cleanError(error.toString()));
    }
  }

  Future<void> _syncSessionStatusesQuietly() async {
    try {
      await _client.rpc('sync_online_consultation_statuses');
    } catch (_) {
      // Validasi RPC kirim pesan tetap menjadi pengaman utama.
    }
  }

  String _translateError(PostgrestException error) {
    final String message =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''}'
            .toLowerCase();

    if (message.contains('room chat belum aktif')) {
      return 'Room chat baru dapat digunakan saat jadwal konsultasi dimulai.';
    }

    if (message.contains('sesi chat sudah berakhir')) {
      return 'Sesi chat sudah berakhir. Riwayat pesan tetap dapat dibaca.';
    }

    if (message.contains('kamu bukan peserta room chat ini')) {
      return 'Kamu tidak memiliki akses ke room chat ini.';
    }

    if (message.contains('konsultasi belum aktif untuk chat')) {
      return 'Konsultasi belum terkonfirmasi untuk chat.';
    }

    if (message.contains('akun tidak aktif')) {
      return 'Akun sedang tidak aktif.';
    }

    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Kamu tidak memiliki izin untuk mengakses chat ini.';
    }

    return error.message.trim().isEmpty
        ? 'Terjadi kesalahan pada room chat.'
        : error.message.trim();
  }

  String _cleanError(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }
}
