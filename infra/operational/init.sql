CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS trainradar;

COMMENT ON SCHEMA trainradar IS
  'Operational/spatial M0 boundary. Exact passenger GPS is forbidden here.';
