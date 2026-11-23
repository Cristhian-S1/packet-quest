# Auditoría de diseño frente a implementación — Packet Quest

Fecha: 2026-11-23. Alcance: documentos solicitados y `game/`; arte excluido. «Hecho» cubre el comportamiento descrito en cada fila, no todos sus valores. «Cambiado» requiere una decisión explícita en `game/IMPLEMENTACION.md`. Las referencias son relativas a la raíz.

## 1. Resumen por documento

| Documento | Hecho | Parcial | Ausente | Cambiado a propósito |
|---|---|---|---|---|
| 01 GDD | Cinco mundos y bucle | Duración sin medición humana | — | — |
| 03 Mecánicas | Movimiento, armas, escudo, taller, controles | Progreso de muerte, avisos, núcleos | Remapeo | Vacíos letales posteriores |
| 04 Niveles | Cinco niveles, puzles y jefes | Recompensa y duración | — | Final a créditos |
| 05 Enemigos y jefes | Enemigos, fases y patrones principales | Avisos sonoros | — | Cancelación de ataques en algunos jefes |
| 06 Puzles | Seis mecánicas, reinicios | Pistas temporizadas | — | Puentes QoS sobre suelo |
| 09 Audio | Música por mundo y SFX | Tema individual por jefe | — | Tema compartido de jefes |
| 10 QA | 21 pruebas y prueba de integración pasan | Playtest y rendimiento no certificados | — | — |
| 13 Wi-Fi | Nivel, cobertura, Spyware, cable, Reina | Núcleo de jefe frente al GDD | — | Ciclo de onda y transición |
| 14 Firewall | Láser, blindaje, filtro, jefe | Avisos y recompensas | — | Puertos y límite del muro |
| 15 Servidor | Ventilador, ascensor, Troyano, contraseña, jefe | Pista y recompensas | — | Portal y cofre |
| 16 Centro de datos | Nubes, QoS, Bot, Malwarex, créditos | Estadística de núcleos | — | Puentes y recompensas adicionales |

## 2. Matriz de requisitos

| Requisito | Estado | Diseño → implementación y límite |
|---|---|---|
| Cinco mundos y bucle mapa → nivel → puzle → jefe | Hecho | `docs/01-gdd.md:35`, `docs/04-niveles.md:3` → `game/scripts/autoload/game_state.gd:5`, `game/scripts/levels/world1_level1.gd:63`, `game/scripts/levels/world2_level1.gd:112`, `game/scripts/levels/world3_level1.gd:91`, `game/scripts/levels/world4_level1.gd:85`, `game/scripts/levels/world5_level1.gd:149`. |
| Movimiento, salto variable, coyote/buffer, dash y apuntado | Hecho | `docs/03-mecanicas.md:22`, `docs/03-mecanicas.md:34`, `docs/03-mecanicas.md:54` → `game/scripts/player/player.gd:8`, `game/scripts/player/player.gd:185`, `game/scripts/player/player.gd:197`, `game/scripts/player/player.gd:253`; integración aprobada. |
| Paquete, triple, Ping y escudo | Hecho | `docs/03-mecanicas.md:46`, `docs/03-mecanicas.md:57` → `game/scripts/data/catalog.gd:5`, `game/scripts/player/player.gd:209`, `game/scripts/player/player.gd:267`; pruebas de armas e integración aprobadas. |
| Vida, retroceso, invulnerabilidad y hit-stop | Hecho | `docs/03-mecanicas.md:71` → `game/scripts/player/player.gd:291`, `game/tests/test_hit_stop.gd:1`. |
| Caída al vacío cuesta 1 PV y reaparece | Cambiado a propósito | `docs/03-mecanicas.md:75` → `game/scripts/player/player.gd:308`; mundos con `fatal_pits` matan directamente. Decisión `game/IMPLEMENTACION.md:55`; las specs posteriores también exigen muerte, por ejemplo `docs/15-m10-mundo-servidor.md:41`. |
| Pantalla de muerte con progreso, marcas y reintento | Parcial | `docs/03-mecanicas.md:76`, `docs/05-enemigos-y-jefes.md:35` → `game/scripts/ui/death_screen.gd:8`; progreso de jefe y marcas existen, pero progreso de niveles 1–4 queda en cero (B1). |
| Checkpoints y reintento desde inicio de jefe | Parcial | `docs/03-mecanicas.md:77`, `docs/04-niveles.md:45` → `game/scripts/objects/checkpoint.gd:18`, `game/scripts/autoload/game_state.gd:98`; se probó Router y checkpoints de niveles 2–4, no muerte y reintento de cada jefe. |
| Controles teclado y mando | Hecho (mapa) | `docs/03-mecanicas.md:7` → `game/project.godot:42`: doce acciones con eventos de teclado y mando especificados. Se comprobó InputMap, no mando físico ni todos los eventos durante una partida. |
| Remapeo completo | Ausente | `docs/03-mecanicas.md:115` → `game/scripts/ui/options_menu.gd:22` ofrece sacudida, destellos, asistencia y volúmenes, sin captura ni reasignación. |
| Asistencia, menos destellos y sacudida | Hecho | `docs/03-mecanicas.md:111` → `game/scripts/ui/options_menu.gd:22`, `game/scripts/autoload/game_state.gd:66`, `game/scripts/player/player.gd:120`; `game/tests/test_options.gd:1` aprobado. |
| Catálogo, precios, dos armas y una pasiva | Hecho | `docs/03-mecanicas.md:86` → `game/scripts/data/catalog.gd:12`, `game/scripts/ui/workshop.gd:14`, `game/scripts/progression/progression.gd:6`. La prueba temporal enumeró 2/2/2/1/1/2/3 para vida/triple/Ping/dash/firewall/marcador/ralentizador. |
| Núcleo por jefe y dos ocultos por mundo | Parcial | `docs/03-mecanicas.md:88`, `docs/04-niveles.md:9` → Router genera núcleo (`game/scripts/bosses/router_boss.gd:220`); Firewall y Troyano lo abonan (`game/scripts/bosses/firewall_boss.gd:288`, `game/scripts/bosses/trojan_boss.gd:223`); Reina y Malwarex no (`game/scripts/bosses/wifi_queen_boss.gd:263`, `game/scripts/bosses/malwarex_boss.gd:339`). Specs sitúan dos en niveles 2 y 5 y excluyen el de Malwarex (`docs/13-m8-mundo-wifi.md:40`, `docs/16-m11-centro-de-datos.md:187`): conflicto de diseño. |
| Guardado, desbloqueo y evitar duplicados | Hecho | `docs/13-m8-mundo-wifi.md:17`, `docs/16-m11-centro-de-datos.md:27` → `game/scripts/autoload/game_state.gd:114`, `game/scripts/autoload/game_state.gd:130`, `game/scripts/autoload/save_manager.gd:1`; pruebas de guardado, progresión e integración aprobadas. |
| Pop-up y Gusano, fragmento de caché | Parcial | `docs/05-enemigos-y-jefes.md:17`, `docs/05-enemigos-y-jefes.md:25` → `game/scripts/enemies/enemy_base.gd:61`, `game/scripts/enemies/network_worm.gd:29`, `game/scripts/objects/data_core.gd:1`; ataques y fragmento presentes; véase avisos sonoros. |
| Spyware, blindados, Troyano y Bot | Parcial | `docs/05-enemigos-y-jefes.md:21`, `docs/14-m9-mundo-firewall.md:64`, `docs/15-m10-mundo-servidor.md:84`, `docs/16-m11-centro-de-datos.md:92` → `game/scripts/enemies/spyware.gd:28`, `game/scripts/enemies/armor_rule.gd:4`, `game/scripts/enemies/trojan.gd:25`, `game/scripts/enemies/bot_ddos.gd:29`; comportamiento principal probado en suites; avisos sonoros no universales. |
| Router: anillos, estampida, láser y dos fases | Hecho | `docs/05-enemigos-y-jefes.md:37` → `game/scripts/bosses/router_boss.gd:140`, `game/tests/integration_suite.gd:243`; integración aprobada. |
| Reina: ondas, ping, espiral, teletransporte, interferencia y repetidores | Hecho | `docs/13-m8-mundo-wifi.md:88` → `game/scripts/bosses/wifi_queen_boss.gd:153`, `game/scripts/objects/wifi_repeater.gd:1`, `game/tests/test_world2.gd:104`. |
| Firewall: reglas, láser, puertos y avance | Hecho | `docs/14-m9-mundo-firewall.md:106` → `game/scripts/bosses/firewall_boss.gd:150`, `game/scripts/bosses/firewall_boss.gd:181`, `game/tests/test_world3.gd:1`. |
| Troyano Real: salto, descarga, invocación y mímicos | Hecho | `docs/15-m10-mundo-servidor.md:141` → `game/scripts/bosses/trojan_boss.gd:141`, `game/tests/test_world4.gd:173`. |
| Malwarex: anillos/ondas, cables/ventanas, nodos y borrado | Hecho | `docs/16-m11-centro-de-datos.md:149` → `game/scripts/bosses/malwarex_boss.gd:189`, `game/scripts/bosses/malwarex_boss.gd:270`, `game/scripts/bosses/malwarex_boss.gd:322`, `game/tests/test_world5.gd:160`. |
| Fases: terminar ataque, limpiar balas, pausa y tarjeta | Cambiado a propósito | `docs/05-enemigos-y-jefes.md:30` → Router espera en `game/IMPLEMENTACION.md:26`; Reina y Troyano cancelan según `game/IMPLEMENTACION.md:59` y `game/IMPLEMENTACION.md:85`. No extrapolar esta decisión a todos. |
| Avisos de ataque con forma, sonido y color | Parcial | `docs/05-enemigos-y-jefes.md:5`, `docs/03-mecanicas.md:116` → jefes llaman avisos (`game/scripts/bosses/wifi_queen_boss.gd:158`); `game/scripts/enemies/enemy_base.gd:61`, `game/scripts/enemies/network_worm.gd:29` y `game/scripts/enemies/spyware.gd:59` tienen estados de aviso sin llamada sonora equivalente. No se auditó perceptibilidad de cada aviso con audio real. |
| Ruta, cable, firewall, contraseña, QoS y nodos de combate | Hecho | `docs/06-puzles.md:13` → `game/scripts/puzzles/route_puzzle.gd:42`, `game/scripts/puzzles/cable_puzzle.gd:45`, `game/scripts/puzzles/firewall_puzzle.gd:70`, `game/scripts/puzzles/password_puzzle.gd:61`, `game/scripts/puzzles/qos_room.gd:50`, `game/scripts/bosses/malwarex_boss.gd:322`. Suites de mundos y ruta aprobadas. |
| Pistas a los 60 s cada 10 s | Parcial | `docs/06-puzles.md:55` → implementadas en `game/scripts/puzzles/route_puzzle.gd:76`, `game/scripts/puzzles/firewall_puzzle.gd:129`, `game/scripts/puzzles/qos_room.gd:95`; cable y contraseña carecen de temporizador equivalente (`game/scripts/puzzles/cable_puzzle.gd:18`, `game/scripts/puzzles/password_puzzle.gd:50`). |
| Puzle QoS con puentes y reintento sin daño | Cambiado a propósito | `docs/16-m11-centro-de-datos.md:136` → puentes sobre suelo firme, `game/IMPLEMENTACION.md:94`; reintento probado en `game/tests/test_world5.gd:142`. |
| Música y efectos | Parcial / cambiado | `docs/09-arte-y-audio.md:33` → cinco temas `game/scripts/audio/music_catalog.gd:18` y uno común de jefe `game/scripts/audio/music_catalog.gd:33`; decisión explícita `game/IMPLEMENTACION.md:108`. No se verificó a oído normalización ni licencia externa. |
| Créditos, estadísticas y final | Parcial | `docs/16-m11-centro-de-datos.md:195` pide saldo X/10; `game/scripts/ui/credits_screen.gd:8` muestra identificadores únicos recogidos /12. Las recompensas adicionales están decididas en `game/IMPLEMENTACION.md:93`; usar recogidos en vez de saldo es una diferencia adicional no documentada expresamente allí. |
| Pruebas automáticas y con jugadores | Parcial | `docs/10-qa-y-pruebas.md:3`, `docs/10-qa-y-pruebas.md:33` → `game/tests/test_runner.gd:3`: 21/21 y test de integración aprobados; sin evidencia actual de cinco participantes ni del criterio ≥4/5. |

## 3. Huecos priorizados por impacto

| Prioridad / tamaño | Hueco y propuesta mínima | Evidencia |
|---|---|---|
| P1 / M | **Remapeo ausente:** añadir captura para todas las acciones, validación de conflictos y persistencia de teclado y mando. | `docs/03-mecanicas.md:115`; `game/scripts/ui/options_menu.gd:22`, `game/project.godot:44`. |
| P1 / M | **Avisos sonoros incompletos en enemigos comunes:** añadir una señal consistente al entrar en aviso del Pop-up, Gusano, Spyware y Troyano; comprobar que no dependa del color ni se active fuera de pantalla. | `docs/05-enemigos-y-jefes.md:5`; `game/scripts/enemies/enemy_base.gd:61`, `game/scripts/enemies/network_worm.gd:29`, `game/scripts/enemies/spyware.gd:59`. |
| P2 / S | **Progreso de muerte de niveles 1–4 siempre 0 %:** actualizar el progreso en cada nivel antes de morir; ver B1. | `docs/03-mecanicas.md:76`; `game/scripts/ui/death_screen.gd:15`, `game/scripts/levels/world5_level1.gd:154`. |
| P2 / M | **Ayuda tras 60 s no disponible en cable y contraseña:** añadir indicación suave del siguiente elemento accionable, con reducción de destellos. | `docs/06-puzles.md:55`; `game/scripts/puzzles/cable_puzzle.gd:18`, `game/scripts/puzzles/password_puzzle.gd:50`. |
| P2 / S | **Recompensa tras Reina y Malwarex difiere del GDD:** acordar una única economía: ajustar el GDD a los núcleos del nivel o entregar uno por jefe y actualizar total y economía. | `docs/03-mecanicas.md:88`, `docs/16-m11-centro-de-datos.md:187`; `game/scripts/bosses/wifi_queen_boss.gd:263`, `game/scripts/bosses/malwarex_boss.gd:339`. |
| P2 / S | **Créditos 12 recogidos frente a saldo/10:** decidir si el indicador mide recogidos o saldo y actualizar especificación, etiqueta y denominador juntos. El criterio actual evita que una compra reduzca el total recogido. | `docs/16-m11-centro-de-datos.md:202`; `game/scripts/ui/credits_screen.gd:8`, `game/IMPLEMENTACION.md:93`. |
| P2 / M | **QA con personas y rendimiento sin certificar:** realizar el playtest con cinco jugadores y registrar comprensión, muertes, tiempos y deseo de repetir; medir FPS en hardware objetivo. | `docs/10-qa-y-pruebas.md:31`; `game/IMPLEMENTACION.md:49`. |
| P3 / M | **Tema por jefe:** si se mantiene el requisito original, crear temas individuales; actualmente se comparte uno por decisión documentada. | `docs/09-arte-y-audio.md:37`; `game/IMPLEMENTACION.md:109`, `game/scripts/audio/music_catalog.gd:33`. |

## 4. Bugs reproducidos

### B1 — Progreso del nivel en pantalla de muerte es 0 % en mundos 1–4

1. Iniciar cualquier nivel 1–4 y avanzar, por ejemplo, hasta x=500; morir antes del jefe.
2. La pantalla muestra «Progreso del nivel: 0 %», aunque Byte avanzó. Esperado: proporción representativa del avance (`docs/03-mecanicas.md:76`).
3. Reproducción headless: se instanciaron los cinco niveles, se colocó Byte en x=500 y se dejaron avanzar dos frames físicos. Se observó `boss_progress`: 0, 0, 0, 0 y 0,139275766 para mundos 1–5 respectivamente. La pantalla usa directamente esa variable (`game/scripts/ui/death_screen.gd:15`); solo el mundo 5 la actualiza durante el recorrido (`game/scripts/levels/world5_level1.gd:153`). La prueba no simuló visualmente la muerte para los cinco mundos; el texto mostrado se deduce del código de la pantalla.

## 5. Comprobaciones ejecutadas y límites

- Godot 4.7.2 headless. Un primer intento en checkout sin importar falló por clases globales sin registrar; `--import` terminó con código 0 y el rerun de `res://tests/test_runner.gd` terminó **21/21 PASS, código 0**. El runner aísla el guardado en `user://test_session.json` (`game/tests/test_runner.gd:26`).
- `res://tests/test_integration.gd`: **PASS, código 0**. Ejercita entrada al Router, muerte, progreso 30 %, reintento desde el inicio y restauración de vidas (`game/tests/integration_suite.gd:176`), además de victoria y núcleo (`game/tests/integration_suite.gd:314`). Usa `user://test_integration.json` (`game/tests/integration_suite.gd:17`).
- Suites de mundos aprobadas: Wi-Fi prueba puzle, checkpoint, jefe y desbloqueo (`game/tests/test_world2.gd:153`); Firewall y Servidor tienen rutas y reintentos (`game/tests/test_world3.gd:337`, `game/tests/test_world4.gd:263`); Centro de datos prueba recorrido, puzle, jefe y créditos (`game/tests/test_world5.gd:281`, `game/tests/test_world5.gd:228`). Algunas pruebas manipulan estado o daño; no prueban toda la destreza de una partida real. Las tarjetas de restauración se verificaron en código (`game/scripts/bosses/router_boss.gd:212`, `game/scripts/bosses/wifi_queen_boss.gd:270`, `game/scripts/bosses/firewall_boss.gd:296`, `game/scripts/bosses/trojan_boss.gd:231`, `game/scripts/bosses/malwarex_boss.gd:347`). El quinto mundo finaliza en créditos y no tiene nodo siguiente (`game/scripts/autoload/game_state.gd:139`).
- Prueba temporal no registrada en runner: enumeró catálogo y eventos InputMap; instanció los cinco niveles y observó el progreso. Se eliminó al terminar. No se conectó mando físico ni se certificó percepción audiovisual, duraciones objetivo, reintento de los cinco jefes, todos los checkpoints o una partida humana completa. Los tests no demuestran cada valor ni cada ruta de las specs.
- No se ejecutó `bd`, no se hizo push y no se alteraron archivos de juego versionados. Estimaciones aproximadas: S hasta medio día, M de medio día a dos días, L más de dos días.
