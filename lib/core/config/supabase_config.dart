/// Configuração de conexão com o Supabase
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ujeonefljdxofpdyhvyh.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqZW9uZWZsamR4b2ZwZHlodnloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI3NjYwMjcsImV4cCI6MjEwODM0MjAyN30.lBLBu_Y8pqmKq9V5lwDdh7ngxEi6doLMAbj4cKIbrAc',
  );

  static const String avatarsBucket = 'avatars';
}
