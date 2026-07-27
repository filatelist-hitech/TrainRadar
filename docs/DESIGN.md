# Design

## Source of truth

- Status: Active for M0, implementation values subject to later visual approval.
- Last refreshed: 2026-07-27.
- Primary product surfaces: Flutter iOS/Android; web later.
- Evidence reviewed: утверждённое ТЗ, `docs/PRODUCT.md`, `docs/MVP_SCOPE.md`, platform location guidance.

## Brand

- Personality: спокойный диспетчер — точный, человечный, без «магии AI».
- Trust signals: источник, возраст, confidence, contributors и диапазон всегда рядом с позицией.
- Avoid: авиационная метафора точности, мигающие тревоги, цвет как единственный носитель смысла,
  скрытый fallback, рейтинги при малой выборке.

## Product goals

- Goals: дать быстрое понимание «где поезд и можно ли этому верить».
- Non-goals: трекинг друзей, публичные пассажирские точки, продажа билетов, операторская аналитика.
- Success signals: пользователь различает факт/расчёт/stale без обучения и может мгновенно выключить GPS.

## Personas and jobs

- Primary personas: ежедневный пассажир и приглашённый участник личного пилота.
- User jobs: проверить покрытие, выбрать рейс, включить активную поездку, понять следующую остановку,
  отключить sharing.
- Key contexts: одной рукой, в движении, плохая сеть, яркое солнце, ограниченное внимание.

## Information architecture

- Primary navigation: Карта, Моя поездка, Настройки/privacy.
- Core screens: corridor overview, trip detail, active-trip consent/control, own trip history.
- Content hierarchy: state → freshness → next stop/ETA range → provenance details.
- M0 shell показывает только pending registry и выключенный GPS; карта отсутствует.

## Design principles

1. Truth before beauty: визуальное состояние никогда не делает estimate похожим на actual.
2. Progressive disclosure: причина confidence доступна, но главное состояние читается за секунду.
3. Consent is a control: включение, индикатор и выключение находятся в одном потоке активной поездки.
4. Degrade loudly: offline/stale сохраняет последний контекст, но убирает live semantics.

## Visual language

- Color: четыре состояния имеют разные цвет, иконку и текст; palette/contrast утверждаются позже.
- Typography: системный Flutter stack, минимум 16sp для основной информации.
- Spacing/layout rhythm: базовый шаг 8dp, touch targets не меньше 48×48dp.
- Shape/radius/elevation: спокойные карточки; elevation не кодирует достоверность.
- Motion: короткая и функциональная; stale transition не пульсирует, reduced motion обязателен.
- Imagery/iconography: нейтральная железнодорожная символика, без изображения пассажира на карте.

## Components

- Existing components to reuse: Material 3 primitives из Flutter.
- New/changed components: `PositionTruthBadge`, `FreshnessLabel`, `ConfidenceDetails`,
  `ActiveTripConsent`, `LocationKillSwitch`, `EtaRange`, `OfflineBanner`.
- Variants and states: loading, pending, actual, confirmed, estimated, stale, unavailable, denied.
- Token/component ownership: mobile module; токены появятся только с утверждённым visual baseline.

## Accessibility

- Target standard: WCAG 2.2 AA как проверяемая цель для общих interaction patterns.
- Keyboard/focus behavior: логичный traversal; web/assistive input позже не блокируется.
- Contrast/readability: 4.5:1 для текста, состояние дублируется словами и иконкой.
- Screen-reader semantics: state, age и confidence читаются одной осмысленной фразой.
- Reduced motion and sensory considerations: без обязательной анимации и без тревоги только цветом.

## Responsive behavior

- Supported devices: iOS/Android phones; tablets должны оставаться usable, но не оптимизированы в M0.
- Layout adaptations: карточки переходят в одну колонку; landscape не обрезает primary state.
- Touch/hover differences: все важные действия доступны touch; hover не содержит уникальной информации.

## Interaction states

- Loading: skeleton без фиктивной позиции.
- Empty: «Для этого рейса нет наблюдений», а не нулевая координата.
- Error: причина и безопасный retry; предыдущие данные явно stale.
- Success: подтверждается тип источника и время.
- Disabled: объясняет, что нужно и какое privacy-последствие.
- Offline/slow network: последний state с фиксированным timestamp, live coverage выключено после TTL.

## Content voice

- Tone: коротко, спокойно, конкретно.
- Terminology: «официальная», «подтверждена группой», «расчётная», «связь потеряна».
- Microcopy rules: не писать «точно», «онлайн» или «сейчас» без freshness evidence; ETA всегда диапазон.

## Implementation constraints

- Framework/styling system: Flutter Material 3, без дополнительного design-system package в M0.
- Design-token constraints: semantic state tokens before raw colors.
- Performance constraints: карта и обновления не должны блокировать consent/kill switch.
- Compatibility constraints: iOS/Android; web позже.
- Test expectations: widget semantics, text/state mapping, large text, reduced motion, offline/error.

## Open questions

- [ ] Утвердить visual palette и icon set / owner / блокирует M1 visual baseline.
- [ ] Зафиксировать минимальные версии iOS/Android / owner / влияет на accessibility и background APIs.
- [ ] Провести тест понятности четырёх truth states с 5–15 участниками / owner / блокирует M4.
