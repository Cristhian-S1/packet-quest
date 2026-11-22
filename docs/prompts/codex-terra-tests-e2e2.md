Eres Codex (gpt-6.1-terra, esfuerzo alto). Continúa y TERMINA el trabajo de la rama actual `test/e2e` (último commit
4e49f2b: ejecutor e2e preparado; la prueba se bloqueaba en el menú porque Input.action_press no entrega eventos a los
botones de la interfaz).

DECISIÓN DEL DIRECTOR (respuesta a tu pregunta): SÍ, usa `Input.parse_input_event` con InputEventKey/InputEventAction
reales para menús, mapa, Taller, pausa y créditos. Para mover a Byte puedes usar también `parse_input_event`
(preferible: es lo más parecido a un jugador) o `action_press`/`action_release`. Sigue prohibido teletransportar a Byte
o tocar posiciones, velocidades o PV durante el recorrido (solo se permite fijar el estado inicial y activar el modo
asistencia si existe, documentándolo).

Objetivo mínimo: menú → Jugar → mapa → Mundo 1 completo (nivel 1-1 con su puzle y el Router Furioso vencido) → vuelta al
mapa con el Mundo 2 desbloqueado → nivel 2-1 completo hasta entrar en la Reina Wi-Fi. Si sobra tiempo, amplía a más mundos.
Captura PNG en momentos clave (docs/capturas/e2e/). Si el bot no puede superar una sección por diseño (salto imposible,
ataque inesquivable), es un BUG de diseño: repórtalo con evidencia (frames, posiciones) y corrígelo en un commit `fix:`
con su prueba si la corrección es clara.
Ejecuta `bash tools/run-e2e.sh` y `bash tools/run-tests.sh --integration` al final; ambas en verde. Commits en español.
ACLARACIÓN: puede haber instancias de Godot de OTROS agentes abiertas (p. ej. la ventana del agente de interfaz). No cuentan para tu límite y no debes esperar a que terminen ni cerrarlas: tu límite es UN proceso de Godot TUYO a la vez. Empieza ejecutando ya `bash tools/run-e2e.sh`.
Estado: el último commit wip(e2e) añade eventos de teclado en pilot.gd y e2e_suite.gd, sin ejecutar todavía.
CONTEXTO ACTUALIZADO (prevalece sobre el texto de abajo):
- El juego tiene exactamente 5 mundos y TODOS existen en esta rama: Red Local (Router Furioso), Wi-Fi (Reina Wi-Fi), Firewall (Firewall Corrupto), Servidor (Troyano Real) y Centro de datos (Malwarex, jefe final de 4 fases, seguido de los créditos).
- Especificaciones: docs/13-m8-mundo-wifi.md, docs/14-m9-mundo-firewall.md, docs/15-m10-mundo-servidor.md, docs/16-m11-centro-de-datos.md, además de docs/03, 05 y 06.
- El runner (game/tests/test_runner.gd) ya marca FAIL cualquier error del motor o de GDScript durante una prueba (Logger); la salida debe quedar sin SCRIPT ERROR ni ERROR.
- La memoria del equipo es limitada: como mucho UN proceso de Godot propio a la vez (los de otros agentes no cuentan); cierra solo los tuyos.
- Tienes el MCP godot (godot-mcp) configurado y skills de Godot en C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills.
- No uses bd, no hagas push y no salgas de este worktree. Haz commits en español.

TAREA ORIGINAL:
