/// SQLite DDL for the CLEF Viewer log store.
const createAppLogsTable = '''
CREATE TABLE IF NOT EXISTS app_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    level TEXT NOT NULL,
    message_template TEXT,
    rendered_message TEXT,
    exception TEXT,
    event_id TEXT,
    device_id TEXT,
    properties TEXT NOT NULL DEFAULT '{}'
);
''';

const createIndexes = '''
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON app_logs (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_logs_level ON app_logs (level);
CREATE INDEX IF NOT EXISTS idx_logs_device ON app_logs (device_id);
CREATE INDEX IF NOT EXISTS idx_logs_event_id ON app_logs (event_id);
''';