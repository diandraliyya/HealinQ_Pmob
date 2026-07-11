import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_activity_model.dart';

class AdminActivityService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdminActivityModel>> getActivities() async {
    final response = await _client.rpc(
      'get_admin_activity_logs',
    );

    return (response as List)
        .map(
          (e) => AdminActivityModel.fromMap(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}
