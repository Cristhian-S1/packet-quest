> build · deepseek-v4-pro
Voy a leer primero la estructura del proyecto y los documentos de referencia para que los nombres y valores encajen. Empiezo explorando en paralelo.
$ git -C "C:\Users\alumnos.LAPTOP-LGABPBVS\Downloads\videogame-wt\m9doc" status --short && echo "---BRANCH---" && git -C "C:\Users\alumnos.LAPTOP-LGABPBVS\Downloads\videogame-wt\m9doc" branch --show-current
At line:1 char:352
+ ... PTOP-LGABPBVS\Downloads\videogame-wt\m9doc" status --short && echo "- ...
+                                                                ~~
The token '&&' is not a valid statement separator in this version.
At line:1 char:375
+ ... \videogame-wt\m9doc" status --short && echo "---BRANCH---" && git -C  ...
+                                                                ~~
The token '&&' is not a valid statement separator in this version.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : InvalidEndOfLine
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
> build · deepseek-v4-pro
He leído toda la documentación y el código. Ahora entiendo la estructura exacta de `docs/13-m8-mundo-wifi.md` y las convenciones de nombres del código (clases, capas, `StageBuilder`, `PQStyle`, patrones de prueba, ids de núcleos, escenas). Voy a escribir el documento.
← Write docs/14-m9-mundo-firewall.md
Created file successfully: docs/14-m9-mundo-firewall.md
> build · deepseek-v4-pro
← Edit docs/01-gdd.md
Index: docs/01-gdd.md
===================================================================
--- docs/01-gdd.md
+++ docs/01-gdd.md
@@ -83,5 +83,6 @@
 | `10-qa-y-pruebas.md` | Plan de pruebas y métricas |
 | `11-investigacion.md` | Fuentes consultadas |
 | `12-herramientas.md` | Herramientas de arte/audio, MCP, skills y plugins recomendados (¿hace falta Blender?) |
 | `13-m8-mundo-wifi.md` | Especificación de implementación del Mundo 2 Wi-Fi (M8) |
+| `14-m9-mundo-firewall.md` | Especificación de implementación del Mundo 3 Firewall (M9) |
 | `superpowers/plans/` | Planes de implementación por hito (M7 en adelante) |
> build · deepseek-v4-pro
Voy a precisar la fórmula del `RuleBar.gap_lane` para que los valores de prueba sean deterministas y coherentes.
← Edit docs/14-m9-mundo-firewall.md
Index: docs/14-m9-mundo-firewall.md
===================================================================
--- docs/14-m9-mundo-firewall.md
+++ docs/14-m9-mundo-firewall.md
@@ -54,9 +54,9 @@
 - Barrera vertical de 16×360 px en una posición fija (capa 7 `hazard`) con un **hueco de 64 px**.
   El hueco cambia de altura entre 3 carriles (y = 280, 208, 136) cada **1,5 s**.
 - Tocar la parte sólida = 1 PV; pasar por el hueco es seguro. Aviso 0,4 s antes de mover el hueco
   (el hueco parpadea en blanco). Reutiliza el concepto del hueco del jefe (F1) para enseñar a leer huecos.
-- Función pura: `static func gap_lane(t: float) -> int` devuelve 0/1/2 (→ 280/208/136), determinista.
+- Función pura: `static func gap_lane(t: float) -> int` = `int(fposmod(t / 1.5, 3.0))` (0/1/2 → 280/208/136), determinista.
 ## 3 · Enemigos blindados (`scripts/enemies/armor_rule.gd`, `armored_popup.gd`, `armored_worm.gd`)
 En el Mundo 3 los enemigos comunes vuelven **blindados**: solo son vulnerables por detrás. La regla
← Edit docs/14-m9-mundo-firewall.md
Index: docs/14-m9-mundo-firewall.md
===================================================================
--- docs/14-m9-mundo-firewall.md
+++ docs/14-m9-mundo-firewall.md
@@ -129,9 +129,9 @@
 Nuevo `tests/test_world3.gd` registrado en `test_runner.gd` (con el patrón `finished` de los demás):
 1. `FirewallFilter`: `is_allowed` solo es `true` para ▲G y ▲B (con `allowed_shape = TRIANGLE`, `blocked_color = RED`); `generate_sequence(0)` da 10 paquetes con 4 permitidos y 6 bloqueados; `generate_sequence(0) == generate_sequence(0)` y `generate_sequence(0) != generate_sequence(1)`.
 2. `PortLaser.state_at`: 0,0 → blocked, 1,5 → blocked, 1,7 → open, 2,4 → open, 2,6 → warning, 3,1 → blocked.
-3. `RuleBar.gap_lane`: 0,0 → 1, 1,6 → 2, 3,1 → 0 (determinista y solo 0/1/2).
+3. `RuleBar.gap_lane`: 0,0 → 0, 1,6 → 1, 3,1 → 2 (determinista y solo 0/1/2).
 4. `ArmorRule.blocks`: disparo por delante → `true`, por detrás → `false`. `ArmoredPopUp`: con Byte a la izquierda, una bala desde la izquierda no reduce PV; desde la derecha sí.
 5. Firewall: `phase_for(1.0) == 1`, `phase_for(0.69) == 2`, `phase_for(0.39) == 3`; `rule_gap_lane` y `correct_port` devuelven solo 0/1/2 para índices 0–20 y ciclan de forma determinista; `wall_x(0) == 640`, `wall_x(10) == 560`, `wall_x(100) == 480`.
 6. GameState: `win()` en el mundo 2 desbloquea el 3; `is_world_playable(data, 3)` falso antes de añadir la escena y verdadero después; `is_world_playable(data, 4)` falso aunque esté desbloqueado.
 7. `test_scenes_load.gd`: subir el mínimo de escenas según las nuevas (≥ 29).
> build · deepseek-v4-pro
> build · deepseek-v4-pro
$ git status --short
M docs/01-gdd.md
?? docs/14-m9-mundo-firewall.md
> build · deepseek-v4-pro
$ git add docs/01-gdd.md docs/14-m9-mundo-firewall.md; git commit -m "docs: especificación M9 Mundo 3 Firewall"
[docs/m9-firewall-spec b83f42d] docs: especificación M9 Mundo 3 Firewall
 2 files changed, 145 insertions(+)
 create mode 100644 docs/14-m9-mundo-firewall.md
> build · deepseek-v4-pro
Listo. He creado la especificación y la he commiteado (sin push).
## Qué hice
Leí los documentos de referencia (`03`, `04`, `05`, `06`, `07`, `08`, `13`) y todo el código de `game/scripts` (autoloads, `StageBuilder`, `PQStyle`, `EnemyBase`/`PopUp`/`NetworkWorm`, `RouterBoss`, puzle, componentes, pruebas y runner) para que los nombres, capas de colisión e ids encajen.
**`docs/14-m9-mundo-firewall.md`** reproduce exactamente la estructura de `docs/13-m8-mundo-wifi.md`:
1. **GameState** — amplía `WORLDS` con `World3Level1.tscn`/`FirewallBoss.tscn`; `is_world_playable` devuelve `true` para 1–3 y `false` para 4–6.
2. **Nivel 3-1 "Muro de reglas"** — 3040×360 px, tabla de secciones S1–S4 + checkpoint + puzle con rangos X, 2 núcleos (`w3_core_a`/`w3_core_b`), y dos objetos nuevos con funciones puras: `PortLaser.state_at(t)` (ritmo bloqueado/abierto/aviso) y `RuleBar.gap_lane(t)`.
3. **Enemigos blindados** — `ArmoredPopUp` (4 PV) y `ArmoredWorm` (6 PV), vulnerables solo por detrás mediante `ArmorRule.blocks(shooter, body, facing)`.
4. **Puzle Firewall** — `FirewallFilter.is_allowed` + `generate_sequence`, regla "Bloquea ROJO · Permite ▲", 10 paquetes con ≤2 fallos, secuencia fija (semilla 0).
5. **Jefe Firewall Corrupto** — 120 PV, 3 fases a 70/40 %, tabla con ataques A/B/C, velocidades, avisos en segundos, mecánica de puertos y funciones puras (`phase_for`, `rule_gap_lane`, `correct_port`, `wall_x`).
6. **Pruebas obligatorias** — `test_world3.gd` con 7 bloques y subida del mínimo de escenas a ≥ 29.
7. **Criterios de aceptación** — incluye capturas `level3.png`/`boss3.png` y actualización de `README.md`.
También añadí la fila al índice de `docs/01-gdd.md`.
**Curva de dificultad** (coherente con Mundos 1–2): nivel 3040 px (+160), jefe 120 PV (Router 60 → Reina 90 → Firewall 120), enemigos blindados más duros (4/6 PV), y el nivel enseña las dos mecánicas del jefe (ritmo con `PortLaser` y leer huecos con `RuleBar`).
Commit realizado: `b83f42d` — `docs: especificación M9 Mundo 3 Firewall` (2 archivos, sin push, como pediste).
