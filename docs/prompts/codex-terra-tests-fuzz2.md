Eres Codex (gpt-6.1-terra, esfuerzo alto). Continúa y TERMINA el trabajo de la rama actual `test/fuzz`.
El commit anterior (wip(fuzz)) contiene un borrador de game/tests/test_fuzz.gd y tools/run-fuzz.sh escrito por otra
pasada que se detuvo sin terminar. Su informe dijo:
- "En una ejecución aislada aparecieron errores internos del motor y fallas al simular la pausa; todavía no he
  determinado si proceden de la instrumentación o del juego."
- "Se detectó una posible superposición de Byte con geometría durante el combate contra Troyano Real."
- La suite completa no llegó a imprimir `RESULTADO N/N PASS`.

Tu trabajo, en este orden:
1. Usa la skill superpowers de depuración sistemática (o, si no la tienes, este método): reproduce cada problema de
   forma aislada y determinista (semilla fija), encuentra la causa raíz y decide si es un bug del juego o de la prueba.
2. Bug del juego → corrección mínima en un commit `fix:` aparte, con una prueba que fallaba antes. Bug de la prueba →
   corrige la prueba. Nunca debilites un invariante para que pase sin explicar por qué el invariante estaba mal.
3. Deja una versión corta en la suite (`bash tools/run-tests.sh --integration` debe terminar con `RESULTADO N/N PASS`
   y `PASS integration`) y la larga en `tools/run-fuzz.sh`, y ejecuta ambas.
4. Commits en español. Al final responde con: bugs del juego encontrados (archivo:línea, síntoma, causa, corrección),
   cambios en la prueba y salida literal de ambas ejecuciones.
CONTEXTO ACTUALIZADO (prevalece sobre el texto de abajo):
- El juego tiene exactamente 5 mundos. En esta rama existen y son jugables los Mundos 1–4: Red Local (Router Furioso), Wi-Fi (Reina Wi-Fi), Firewall (Firewall Corrupto) y Servidor (Troyano Real). El Mundo 5 se desarrolla en otra rama: no lo pruebes ni lo toques.
- Especificaciones: docs/13-m8-mundo-wifi.md, docs/14-m9-mundo-firewall.md, docs/15-m10-mundo-servidor.md, además de docs/03, 05 y 06.
- El runner (game/tests/test_runner.gd) ya marca FAIL cualquier error del motor o de GDScript durante una prueba (Logger); la salida debe quedar sin SCRIPT ERROR ni ERROR.
- La memoria del equipo es limitada: no ejecutes más de un proceso de Godot a la vez y ciérralos todos al terminar.
- Tienes el MCP godot (godot-mcp) configurado y skills de Godot en C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills.
- No uses bd, no hagas push y no salgas de este worktree. Haz commits en español.

TAREA ORIGINAL:
Proyecto Godot 4.7.2 en game/ (GDScript tipado), juego 'Packet Quest' con Mundo 1 (Red Local, Router Furioso) y Mundo 2 (Wi-Fi, Reina Wi-Fi). Pruebas: bash tools/run-tests.sh --integration (debe terminar con RESULTADO N/N PASS y PASS integration; el runner está en game/tests/test_runner.gd, cada prueba es un RefCounted con run(tree)->PackedStringArray y el flag 'finished'). Tienes el MCP 'godot' (godot-mcp) y skills de Godot en markdown en C:\Users\alumnos.LAPTOP-LGABPBVS\.claude\plugins\cache\godot-prompter-marketplace\godot-prompter\1.17.0\skills (lee godot-testing y gdscript-patterns). Especificación: docs/03-mecanicas.md, 05-enemigos-y-jefes.md, 06-puzles.md, 13-m8-mundo-wifi.md. No uses bd, no hagas push, no salgas de este directorio. Commits en español con prefijo test: o fix:. REGLA: si una prueba encuentra un bug real del juego, NO cambies la prueba para que pase: corrige el código del juego con el cambio mínimo en un commit 'fix: ...' aparte y explícalo; si la corrección es de diseño (dudosa), deja la prueba marcada como pendiente con un comentario BUG: y repórtala. Al terminar responde en español: pruebas añadidas, bugs encontrados (archivo:línea, síntoma, corrección), resultado literal de la suite.
Tarea: pruebas de robustez (fuzz / monkey testing) y de invariantes. Crea game/tests/test_fuzz.gd que, con semillas fijas (RandomNumberGenerator con seed), cargue cada escena jugable (World1Level1, RouterBoss, World2Level1, WifiQueenBoss, NetworkMap, Workshop, menú) y durante 1200 frames por escena pulse/suelte acciones aleatorias (move_left/right, jump, dash, shoot, shield, aim_up/down, lock_aim, swap_weapon, interact, pause). Invariantes que se comprueban cada frame: sin errores de script (captura con el patrón del runner), posición y velocidad de Byte finitas (sin NaN/INF), Byte nunca dentro de geometría sólida más de 3 frames, PV entre 0 y el máximo, escudo entre 0 y su máximo, número de balas activas ≤ capacidad del pool, número de nodos del árbol acotado (sin fugas: compara Performance.OBJECT_NODE_COUNT al principio y al final tras liberar), Projectile.enemy_time_scale vuelve a 1.0 al salir de la escena, pausa y despausa sin perder estado. Añade también pruebas de transiciones repetidas (entrar/salir 20 veces de cada escena) para detectar fugas y señales duplicadas. Si es lento, deja una versión corta en la suite (200 frames) y la larga en tools/run-fuzz.sh.
