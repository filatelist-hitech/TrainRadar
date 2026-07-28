# Commit and documentation gate

## Установка и канонические команды

```bash
make install-hooks
make docs-sync
make docs-check
make validate-m1-osm
make verify-m1-osm-runtime
make check-staged
make check-full
make ready
```

`make install-hooks` повторяемо задаёт локальный `core.hooksPath=.githooks`. Hooks не вызывают LLM,
Codex, сеть или внешние сервисы: они работают только с локальным index/worktree и доступными
инструментами. `pre-commit` materialize-ит именно repository index во временном дереве, поэтому
partial staging не проверяется случайным содержимым worktree; `pre-push` запускает полный локальный gate.
Large binary по умолчанию блокируется; единственное узкое исключение — checksum-protected canonical
master `assets/brand/trainradar/master/trainradar-icon-master-1254.png`.

## Generated и human-owned docs

`docs/DOCS_MANIFEST.yaml` — реестр владельцев, источников и правил staging. Автоматически
генерируются только `docs/PROJECT_MAP.md` и отмеченные блоки между
`<!-- BEGIN GENERATED: ... -->` / `<!-- END GENERATED: ... -->`. Генератор не меняет текст вне
этих маркеров.

`docs/PROJECT_MAP.md` обновляйте только через `make docs-sync`. Блоки в `README.md`,
`mobile/README.md` и `docs/API_CONTRACT.md` также обновляются через генератор, но не auto-stageятся:
их нужно проверить и добавить в index явно. Product copy, onboarding, ADR, privacy/security,
troubleshooting, migration guides и evidence остаются human-owned.
Generated project map перечисляет tracked internal Go package directories, поэтому новый backend
package требует синхронизации и staging `docs/PROJECT_MAP.md` в том же срезе.
Go formatter gate сравнивает байты, поэтому UTF-8 комментарии и строковые литералы не дают ложный
сигнал о неотформатированном файле.

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

CI использует Go из `backend/go.mod`, Ruby `3.3` и Flutter `3.44.0`; изменение этих версий требует
обновления workflow и этого документа в одном срезе.
