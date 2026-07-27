FROM ghcr.io/pglayers/pgx-postgis:17@sha256:26cb63c99367fb65920b1337a69753772dfd71d432af79a179de1d5a88994d43 AS postgis

FROM postgres:17-trixie@sha256:a426e44bac0b759c95894d68e1a0ac03ecc20b619f498a91aae373bf06d8508d

COPY --from=postgis / /

LABEL org.opencontainers.image.title="TrainRadar M0 operational PostGIS"
LABEL org.opencontainers.image.description="Official PostgreSQL 17 Trixie plus multi-arch pglayers PostGIS layer"
