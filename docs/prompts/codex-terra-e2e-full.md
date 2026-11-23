# Codex (gpt-6.1-terra) — Ampliar el bot e2e hasta los créditos (bead pq-moy)

Worktree del repo Packet Quest (Godot 4.7.2). Ya existe un bot que juega solo:
`game/tests/bot/pilot.gd`, `game/tests/e2e_suite.gd`, `game/tests/test_e2e_runner.gd`, lanzador `bash tools/run-e2e.sh`.
Hoy recorre menú → mapa → 1-1 (puzle) → vence al Router → mapa → 2-1 (puzle de cables) → entra en la Reina Wi-Fi, y pasa.

## Objetivo
Que el bot llegue hasta los **créditos** jugando de verdad:
1. Vencer a la Reina Wi-Fi (`scripts/bosses/wifi_queen_boss.gd`; las ondas usan `wave_lanes`).
2. Mundos 3 (Firewall), 4 (Servidor) y 5 (Centro de datos): recorrer cada nivel, resolver su puzle, vencer a su jefe
   (Firewall Corrupto, Troyano Real, Malwarex) y volver al mapa con el siguiente mundo desbloqueado.
3. Comprobar la pantalla de créditos y la línea `Núcleos de datos: N/12`.
Specs: `docs/14-m9-mundo-firewall.md`, `docs/15-m10-mundo-servidor.md`, `docs/16-m11-centro-de-datos.md`.

## Reglas de entrada (no negociables)
- Byte se controla SOLO con `Input.action_press/action_release` (move_left/right, jump, dash, shoot…). Nada de escribir
  posición, velocidad ni vida de Byte, ni vida o fase de los jefes.
- Menús, mapa y botones: `Input.parse_input_event` con `InputEventAction`.
- El bot puede LEER el estado (posiciones, telegrafías, fase del jefe, piezas del puzle) para decidir.
- Puzles: el bot debe resolverlos con entradas del jugador (interactuar/girar), puede calcular la solución leyendo
  la lógica (`PasswordLogic`, etc.).
- Se permite activar `assist_mode` en el guardado temporal de la prueba si un combate es inviable de otro modo;
  anótalo en el informe.
- Si encuentras un ataque imposible de esquivar o una salida inalcanzable, NO lo rodees: es un bug del juego.
  Documéntalo con frame y posiciones y deja ese tramo marcado como FAIL explícito.

## Método
- Fases con nombre y puntos de control como en el bot actual; cada fase con su timeout y mensaje de FAIL claro.
- Ejecuta `bash tools/run-e2e.sh` hasta `PASS e2e`; y `bash tools/run-tests.sh --integration` en verde
  (`RESULTADO: N/N PASS` + `PASS integration`). Si el e2e completo supera el timeout del lanzador, súbelo (máx. 600 s).
- Capturas por jefe vencido en `docs/capturas/e2e/` si el método actual lo permite.
- Commits pequeños por mundo. Informe en `logs/codex-terra-e2e-full.md` (bugs encontrados, tiempos por fase).
- No uses `bd`, no hagas push, no modifiques ficheros fuera de este worktree.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran.
- El runner marca FAIL cualquier error del motor o de GDScript: no dejes `SCRIPT ERROR` ni `ERROR:`.

## Entrega
En tu respuesta final: commits, salida literal de `run-e2e.sh` y de la suite, bugs del juego encontrados y pendientes.
