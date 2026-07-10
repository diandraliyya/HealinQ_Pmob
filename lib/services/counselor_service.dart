import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_counselor_model.dart';

class CounselorService {
  final SupabaseClient _supabase;

  CounselorService({
    SupabaseClient? supabaseClient,
  }) : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<List<AdminCounselorModel>> getAllCounselors() async {
    try {
      final List<dynamic> profileRows =
          await _supabase.from('profiles').select('''
          id,
          username,
          full_name,
          email,
          role,
          status,
          created_at
        ''').eq('role', 'counselor').order(
                'created_at',
                ascending: false,
              );

      if (profileRows.isEmpty) {
        return <AdminCounselorModel>[];
      }

      final List<String> counselorIds = <String>[];

      for (final dynamic row in profileRows) {
        final Map<String, dynamic> profile =
            Map<String, dynamic>.from(row as Map);

        final String id = profile['id']?.toString() ?? '';

        if (id.isNotEmpty) {
          counselorIds.add(id);
        }
      }

      if (counselorIds.isEmpty) {
        return <AdminCounselorModel>[];
      }

      final List<dynamic> counselorProfileRows =
          await _supabase.from('counselor_profiles').select('''
          id,
          specialization,
          years_experience,
          location,
          professional_bio,
          offers_online,
          offers_offline,
          price_online,
          price_offline,
          rating,
          rating_count,
          is_available,
          approved_at,
          approved_by
        ''').inFilter(
        'id',
        counselorIds,
      );

      final Map<String, Map<String, dynamic>> counselorDetailsById =
          <String, Map<String, dynamic>>{};

      for (final dynamic row in counselorProfileRows) {
        final Map<String, dynamic> detail =
            Map<String, dynamic>.from(row as Map);

        final String id = detail['id']?.toString() ?? '';

        if (id.isNotEmpty) {
          counselorDetailsById[id] = detail;
        }
      }

      final List<AdminCounselorModel> counselors = <AdminCounselorModel>[];

      for (final dynamic row in profileRows) {
        final Map<String, dynamic> profile =
            Map<String, dynamic>.from(row as Map);

        final String id = profile['id']?.toString() ?? '';

        final Map<String, dynamic> mergedData = <String, dynamic>{
          ...profile,
          'counselor_profiles': counselorDetailsById[id] ?? <String, dynamic>{},
        };

        counselors.add(
          AdminCounselorModel.fromMap(mergedData),
        );
      }

      return counselors;
    } on PostgrestException catch (error) {
      throw Exception(
        _translateDatabaseError(error),
      );
    } catch (error) {
      throw Exception(
        _cleanErrorMessage(error.toString()),
      );
    }
  }

  Future<AdminCounselorModel> getCounselorById(
    String counselorId,
  ) async {
    if (counselorId.trim().isEmpty) {
      throw Exception('Counselor ID tidak valid.');
    }

    try {
      final Map<String, dynamic> profile =
          await _supabase.from('profiles').select('''
              id,
              username,
              full_name,
              email,
              role,
              status,
              created_at
            ''').eq('id', counselorId).eq('role', 'counselor').single();

      final List<dynamic> counselorProfileRows =
          await _supabase.from('counselor_profiles').select('''
              id,
              specialization,
              years_experience,
              location,
              professional_bio,
              offers_online,
              offers_offline,
              price_online,
              price_offline,
              rating,
              rating_count,
              is_available,
              approved_at,
              approved_by
            ''').eq('id', counselorId).limit(1);

      final Map<String, dynamic> counselorProfile = counselorProfileRows.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(
              counselorProfileRows.first as Map,
            );

      return AdminCounselorModel.fromMap(
        <String, dynamic>{
          ...profile,
          'counselor_profiles': counselorProfile,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateDatabaseError(error),
      );
    } catch (error) {
      throw Exception(
        _cleanErrorMessage(error.toString()),
      );
    }
  }

  Future<void> approveCounselor(
    String counselorId,
  ) async {
    await _setCounselorStatus(
      counselorId: counselorId,
      status: 'active',
    );
  }

  Future<void> setCounselorInactive(
    String counselorId,
  ) async {
    await _setCounselorStatus(
      counselorId: counselorId,
      status: 'inactive',
    );
  }

  Future<void> suspendCounselor(
    String counselorId,
  ) async {
    await _setCounselorStatus(
      counselorId: counselorId,
      status: 'suspended',
    );
  }

  Future<void> returnCounselorToPending(
    String counselorId,
  ) async {
    await _setCounselorStatus(
      counselorId: counselorId,
      status: 'pending',
    );
  }

  Future<void> _setCounselorStatus({
    required String counselorId,
    required String status,
  }) async {
    const List<String> validStatuses = <String>[
      'pending',
      'active',
      'inactive',
      'suspended',
    ];

    if (counselorId.trim().isEmpty) {
      throw Exception('Counselor ID tidak valid.');
    }

    if (!validStatuses.contains(status)) {
      throw Exception('Status counselor tidak valid.');
    }

    try {
      await _supabase.rpc(
        'set_counselor_status',
        params: <String, dynamic>{
          'p_counselor_id': counselorId,
          'p_status': status,
        },
      );
    } on PostgrestException catch (error) {
      throw Exception(
        _translateDatabaseError(error),
      );
    } catch (error) {
      throw Exception(
        _cleanErrorMessage(error.toString()),
      );
    }
  }

  Future<void> updateCounselorProfile({
    required String counselorId,
    required String fullName,
    required String specialization,
    required int yearsExperience,
    required String location,
    required String bio,
    required bool offersOnline,
    required bool offersOffline,
    required double priceOnline,
    required double priceOffline,
  }) async {
    if (counselorId.trim().isEmpty) {
      throw Exception('Counselor ID tidak valid.');
    }

    if (fullName.trim().isEmpty) {
      throw Exception('Nama counselor wajib diisi.');
    }

    if (!offersOnline && !offersOffline) {
      throw Exception(
        'Counselor harus menyediakan minimal satu jenis konsultasi.',
      );
    }

    if (yearsExperience < 0) {
      throw Exception(
        'Lama pengalaman tidak boleh kurang dari 0.',
      );
    }

    if (priceOnline < 0 || priceOffline < 0) {
      throw Exception(
        'Harga konsultasi tidak boleh kurang dari 0.',
      );
    }

    try {
      await _supabase
          .from('profiles')
          .update(<String, dynamic>{
            'full_name': fullName.trim(),
          })
          .eq('id', counselorId)
          .eq('role', 'counselor');

      await _supabase.from('counselor_profiles').update(<String, dynamic>{
        'specialization':
            specialization.trim().isEmpty ? null : specialization.trim(),
        'years_experience': yearsExperience,
        'location': location.trim().isEmpty ? null : location.trim(),
        'professional_bio': bio.trim().isEmpty ? null : bio.trim(),
        'offers_online': offersOnline,
        'offers_offline': offersOffline,
        'price_online': priceOnline,
        'price_offline': priceOffline,
      }).eq('id', counselorId);
    } on PostgrestException catch (error) {
      throw Exception(
        _translateDatabaseError(error),
      );
    } catch (error) {
      throw Exception(
        _cleanErrorMessage(error.toString()),
      );
    }
  }

  Future<Map<String, dynamic>> createCounselor({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String specialization,
    required int yearsExperience,
    required String location,
    required String professionalBio,
    required bool offersOnline,
    required bool offersOffline,
    required double priceOnline,
    required double priceOffline,
  }) async {
    final Session? session = _supabase.auth.currentSession;

    if (session == null) {
      throw Exception(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
      );
    }

    if (fullName.trim().length < 3) {
      throw Exception(
        'Nama counselor minimal 3 karakter.',
      );
    }

    final String cleanUsername = username.trim().toLowerCase();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(cleanUsername)) {
      throw Exception(
        'Username harus terdiri dari 3–30 karakter dan hanya boleh menggunakan huruf, angka, atau underscore.',
      );
    }

    final String cleanEmail = email.trim().toLowerCase();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail)) {
      throw Exception('Format email tidak valid.');
    }

    if (password.length < 6) {
      throw Exception(
        'Password minimal 6 karakter.',
      );
    }

    if (!offersOnline && !offersOffline) {
      throw Exception(
        'Pilih minimal satu jenis konsultasi.',
      );
    }

    if (yearsExperience < 0) {
      throw Exception(
        'Lama pengalaman tidak boleh negatif.',
      );
    }

    if (priceOnline < 0 || priceOffline < 0) {
      throw Exception(
        'Harga konsultasi tidak boleh negatif.',
      );
    }

    try {
      final FunctionResponse response = await _supabase.functions.invoke(
        'create-counselor',
        headers: <String, String>{
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: <String, dynamic>{
          'full_name': fullName.trim(),
          'username': cleanUsername,
          'email': cleanEmail,
          'password': password,
          'specialization': specialization.trim(),
          'years_experience': yearsExperience,
          'location': location.trim(),
          'professional_bio': professionalBio.trim(),
          'offers_online': offersOnline,
          'offers_offline': offersOffline,
          'price_online': offersOnline ? priceOnline : 0,
          'price_offline': offersOffline ? priceOffline : 0,
        },
      );

      final dynamic rawData = response.data;

      final Map<String, dynamic> result;

      if (rawData is Map<String, dynamic>) {
        result = rawData;
      } else if (rawData is Map) {
        result = Map<String, dynamic>.from(rawData);
      } else {
        throw Exception(
          'Respons server tidak valid.',
        );
      }

      final bool success = result['success'] == true;

      if (response.status < 200 || response.status >= 300 || !success) {
        throw Exception(
          result['message']?.toString() ?? 'Gagal membuat counselor.',
        );
      }

      return result;
    } catch (error) {
      final String message =
          error.toString().replaceFirst('Exception: ', '').trim();

      if (message.toLowerCase().contains(
                'already registered',
              ) ||
          message.toLowerCase().contains(
                'already been registered',
              )) {
        throw Exception(
          'Email tersebut sudah terdaftar.',
        );
      }

      if (message.toLowerCase().contains(
                'invalid jwt',
              ) ||
          message.toLowerCase().contains(
                'unauthorized',
              )) {
        throw Exception(
          'Sesi admin tidak valid. Silakan logout lalu login kembali.',
        );
      }

      throw Exception(
        message.isEmpty ? 'Gagal membuat counselor.' : message,
      );
    }
  }

  String _translateDatabaseError(
    PostgrestException error,
  ) {
    final String message = error.message.toLowerCase();

    if (message.contains(
      'only an active admin can change counselor status',
    )) {
      return 'Hanya admin aktif yang dapat mengubah status counselor.';
    }

    if (message.contains('counselor not found')) {
      return 'Data counselor tidak ditemukan.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Akses database ditolak. Pastikan akun yang login adalah admin aktif.';
    }

    if (message.contains('invalid counselor status')) {
      return 'Status counselor tidak valid.';
    }

    return error.message;
  }

  String _cleanErrorMessage(String message) {
    return message.replaceFirst('Exception: ', '').trim();
  }
}
