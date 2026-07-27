# Commit and documentation gate

## Установка и канонические команды

```bash
make install-hooks
make docs-sync
make docs-check
make check-staged
make check-full
make ready
```

`make install-hooks` повторяемо задаёт локальный `core.hooksPath=.githooks`. Hooks не вызывают LLM,
Codex, сеть или внешние сервисы: они работают только с локальным index/worktree и доступными
инструментами. `pre-commit` проверяет staged scope; `pre-push` запускает полный локальный gate.

## Generated и human-owned docs

`docs/DOCS_MANIFEST.yaml` — реестр владельцев, источников и правил staging. Автоматически
генерируются только `docs/PROJECT_MAP.md` и отмеченные блоки между
`<!-- BEGIN GENERATED: ... -->` / `<!-- END GENERATED: ... -->`. Генератор не меняет текст вне
этих маркеров.

`docs/PROJECT_MAP.md` обновляйте только через `make docs-sync`. Блоки в `README.md`,
`mobile/README.md` и `docs/API_CONTRACT.md` также обновляются через генератор, но не auto-stageятся:
их нужно проверить и добавить в index явно. Product copy, onboarding, ADR, privacy/security,
troubleshooting, migration guides и evidence остаются human-owned.

Чтобы добавить документ, внесите его в `docs/DOCS_MANIFEST.yaml` с аудиторией, владельцем, типом,
source paths, командами и условиями обновления. Для нового класса изменения добавьте узкое правило в
`docs/CHANGE_IMPACT.yaml`: source paths и обязательные human-owned документы. Не добавляйте туда
декоративные правила для отсутствующих в M0 поверхностей.

## Диагностика и восстановление

Если hook остановил commit, сначала выполните его команду вручную:

```bash
make check-staged
make docs-sync
make docs-check
```

После конфликта в generated-файле восстановите содержимое командой `make docs-sync`, проверьте diff
и stage только нужные пути через `git add -- <path>`. `--no-verify` не является успешной проверкой:
он лишь пропускает локальный hook, а CI всё равно повторит `docs-check` и остальные gates.

`pre-push` и CI повторяют formatter, lint, unit tests, build, schema validation и `docs-check`.
Тяжёлых e2e с внешней инфраструктурой в M0 нет; physical iOS/Android/GPS evidence остаётся
`NOT_RUN` до реального запуска и отдельного разрешения.
