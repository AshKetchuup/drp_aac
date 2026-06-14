/// Single source of truth for the backend base URL. Override at build time with
/// `--dart-define=API_BASE_URL=https://...` (e.g. to point at a local backend).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.ismailmehmood.co.uk',
);
