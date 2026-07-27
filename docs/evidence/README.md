# Evidence

Evidence — воспроизводимое доказательство конкретного gate, а не скриншот «у меня зелёное».

Каждый milestone artifact содержит:

- дату/timezone и environment/tool versions;
- exact command и результат/exit code;
- проверяемое требование;
- input/source checksums, если применимо;
- ограничения и `NOT_RUN` для physical/field checks;
- ссылки на code/data/decision version.

M0 startup evidence записывается в `M0-startup.md` после финального прогона. Не хранить здесь
secrets, exact GPS, invites, raw capability IDs, access tokens или personal paths вне необходимых
локальных source identifiers.
