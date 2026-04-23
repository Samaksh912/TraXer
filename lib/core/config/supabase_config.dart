class SupabaseConfig {
  static const String url = String.fromEnvironment('https://wchhltilessnllukhrzu.supabase.co/rest/v1/');
  static const String anonKey = String.fromEnvironment('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjaGhsdGlsZXNzbmxsdWtocnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MzA4NTksImV4cCI6MjA5MjUwNjg1OX0.');

  static void validate() {
	if (url.isEmpty || anonKey.isEmpty) {
	  throw StateError(
		'Missing Supabase config. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
	  );
	}
  }
}

