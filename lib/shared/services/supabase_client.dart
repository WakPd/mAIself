import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseClientService {
  SupabaseClientService._();

  static final SupabaseClientService instance = SupabaseClientService._();

  SupabaseClient get client => Supabase.instance.client;
}
