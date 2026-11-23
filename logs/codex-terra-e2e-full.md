# E2E hasta créditos: avance parcial

Fecha: 2026-11-23. No se alcanzaron los créditos; el e2e termina en FAIL.

## Cambios y límites

- El piloto envía `InputEventAction` para confirmar y seleccionar mundos en el mapa.
- El recorrido intenta el combate contra la Reina. Para las oleadas consulta `wave_lanes`; registra golpes, frame, posición y estado de Byte y de la jefa.
- Tras vencer a la Reina se deja un FAIL explícito: falta implementar mundos 3, 4 y 5 y verificar créditos. No se ha activado `assist_mode`.
- No se han obtenido capturas nuevas ni se han hecho commits.

## Ejecución e2e observada

Tiempos de reloj en ejecución headless a 60 FPS fijos, no duración jugada:

| Fase | Segundos |
| --- | ---: |
| Inicio y menú | 0,026 |
| Menú y mapa al mundo 1 | 0,029 |
| Nivel 1-1 | 1,070 |
| Router | 0,578 |
| Victoria Router y mapa | 0,012 |
| Mapa al mundo 2 | 0,062 |
| Nivel 2-1 | 0,866 |
| Reina Wi-Fi, FAIL | 0,526 |

En esa ejecución Byte recibió daño en los frames 205, 419 y 1299; el último en `(158.7658, 296.9252)`, con la Reina en fase 3 y 28 PV. La estrategia actual no demuestra que el ataque sea imposible de esquivar, por lo que no se clasifica como bug del juego. Los frames pueden variar entre ejecuciones.

El primer lanzamiento del checkout falló al no existir la caché de clases de Godot; la importación incluida en `run-tests.sh` permitió ejecutar el bot. El lanzador e2e por sí solo sigue sin importar automáticamente en un checkout sin caché.

## Validación

- `bash tools/run-e2e.sh`: FAIL en Reina; no hay victoria ni créditos verificados.
- `bash tools/run-tests.sh --integration`: `RESULTADO: 17/17 PASS` y `PASS integration`.
- Pendiente: estrategia de combate fiable, mundos 3–5, capturas de jefes vencidos y comprobación de `Núcleos de datos: N/12`.

## Continuación: banco de la Reina

- El piloto usa predicción de 12 frames de balas, anticipa teletransporte y zonas de interferencia, y conserva el hueco entre columnas del ping. Controla a Byte solo con acciones de entrada, sin assist_mode.
- Banco aislado: 10/10 victorias en 10 ejecuciones con semillas 1–10; las trayectorias observadas son similares, por lo que no prueban una cobertura exhaustiva de variaciones.
- El recorrido encadenado venció a la Reina; el runner mantiene el FAIL explícito mientras faltan mundos 3–5 y créditos.
- El lanzador importa recursos antes de ejecutar y tiene timeout de 600 s.

## Mundo 3 y Firewall Corrupto

- El recorrido encadenado atravesó 3-1, resolvió los diez paquetes mediante los terminales y venció al jefe; se comprobó el regreso al mapa y el desbloqueo del mundo 4. La travesía todavía necesita más pruebas frente a variaciones de los enemigos.
- Banco aislado del Firewall: 10/10 victorias, semillas 1–10, sin asistencia. El piloto esquiva las barras y empuja el muro con disparos antes de atacar el núcleo.
- Ejecución observada: mapa al mundo 3 0,024 s; nivel 3-1 1,092 s; Firewall y mapa 2,593 s. Los tiempos son de reloj headless.
- No se ha demostrado un bug del juego. Mundos 4–5 y créditos siguen pendientes.

## Mundo 4 y Troyano Real

- El recorrido encadenado cruzó el ascensor y el foso, resolvió las ranuras mediante interact y venció al Troyano; se verificó el desbloqueo del mundo 5.
- Banco aislado del Troyano: 10/10 victorias, semillas 1–10, sin asistencia. Se dispara desde una posición segura y se salta ante las descargas.
- Tiempos observados headless: mapa al mundo 4 0,015 s; nivel 4-1 1,172 s; Troyano y mapa 1,247 s. La fiabilidad de la travesía aún requiere más ejecuciones.
- Pendiente: mundo 5, Malwarex y créditos; no se ha demostrado un bug del juego.

## Resultado final de la continuación

Este resultado actualiza el estado parcial descrito al inicio: se alcanzaron los créditos jugando desde el menú, con controles de jugador y sin `assist_mode`. El cruce de nubes admite hasta cinco reintentos mediante la pantalla de muerte y el checkpoint del juego; la ejecución que pasó no necesitó reintento. No se escribieron posiciones, velocidades, vida ni fases de Byte o de los jefes. Los cambios de vida registrados en este informe incluyen la recuperación normal de los checkpoints.

- Bancos aislados, semillas 1–10: Router 10/10, Reina 10/10, Firewall 10/10, Troyano 10/10 y Malwarex 10/10. Los patrones observados son mayormente deterministas y estas diez ejecuciones no cubren todas las posibles condiciones de partida.
- Malwarex: se esquivan los cables con movimiento y dash, se activan los tres nodos mediante `interact` y se preserva una posición sobre el suelo que permanece. La última ejecución encadenada terminó con 1 PV.
- Créditos verificados en pantalla: `Núcleos de datos: 7/12`. El requisito es comprobar el recuento, no recoger los doce núcleos.
- Tiempos observados de la ejecución e2e aprobada, en segundos de reloj headless: inicio/menú 0,030; menú/mapa mundo 1 0,028; nivel 1-1 1,113; Router 0,596; victoria y mapa 0,013; mapa mundo 2 0,062; nivel 2-1 0,896; Reina y mapa 1,064; mapa mundo 3 0,019; nivel 3-1 0,991; Firewall y mapa 2,391; mapa mundo 4 0,017; nivel 4-1 1,156; Troyano y mapa 1,291; mapa mundo 5 0,019; nivel 5-1 1,351; Malwarex y créditos 2,580.
- `bash tools/run-e2e.sh`: `PASS e2e`.
- `bash tools/run-tests.sh --integration`: `RESULTADO: 17/17 PASS` y `PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia`.
- No se ha demostrado ningún ataque imposible ni otra falla del juego. El recorrido de los niveles 3–5 mostró variabilidad durante el desarrollo; una ejecución completa aprobada no demuestra fiabilidad estadística de toda la ruta. No se generaron capturas: el lanzador actual es headless y la captura existente espera un frame renderizado.

La primera comprobación desde una copia sin caché reimportó las clases correctamente, pero terminó en `FAIL e2e` al caer en las nubes; no se considera un bug demostrado del juego. Se ajustó la separación de entradas entre saltos, el dash del último salto y la espera del último puerto. Tras el ajuste, otra ejecución completa terminó en `PASS e2e` con `Núcleos de datos: 7/12`; la variabilidad de la ruta sigue siendo una limitación.

Verificación posterior: una segunda copia exportada del commit, sin caché `.godot`, ejecutó la importación y terminó en `PASS e2e`, con `Núcleos de datos: 7/12`. Se volvió a ejecutar la suite: `RESULTADO: 17/17 PASS` y `PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia`. La política del entorno rechazó la eliminación recursiva de las copias temporales `.e2e-clean-check` y `.e2e-clean-check2`; permanecen sin seguimiento dentro del worktree.
