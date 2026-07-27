# ADR 0005: Versioned OSM geometry and explicit tile backend

- Status: Accepted
- Date: 2026-07-27

## Context

OSM подходит для rail geometry, но данные под ODbL требуют attribution/share-alike analysis, а
community tile servers имеют отдельную usage policy и не дают production SLA. Геометрия должна
быть воспроизводима для matching и ETA evaluation.

## Decision

- использовать только versioned corridor extract с timestamp/replication ID/checksum;
- хранить source/provenance и показывать требуемое OSM attribution;
- не считать public `tile.openstreetmap.org` production backend;
- tile provider/self-hosting выбирать позже по terms, cost, residency and offline needs;
- не копировать geometry из Tutu или других источников без прав.

## Consequences

M1 блокируется до воспроизводимого OSM extract и licence review. MapLibre остаётся client renderer
candidate; он не решает tile hosting и licensing автоматически.
