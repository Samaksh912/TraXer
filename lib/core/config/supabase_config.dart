import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL']?.trim() ?? '';

  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static void validate() {
	final missing = <String>[];

	if (url.isEmpty) {
	  missing.add('SUPABASE_URL');
	}

	if (anonKey.isEmpty) {
	  missing.add('SUPABASE_ANON_KEY');
	}

	if (missing.isNotEmpty) {
	  throw StateError(
		'Missing Supabase config: ${missing.join(', ')}. '
		'Create a root .env file with both variables.',
	  );
	}
  }
}

