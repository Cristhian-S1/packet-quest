# Codex (gpt-6.1-terra) — Auditoría: diseño (docs) frente a juego implementado

Worktree del repo Packet Quest (Godot 4.7.2). **Solo lectura del código**: no cambies nada del juego.

## Tarea
Compara lo que piden los documentos de diseño con lo que hace el juego y entrega una lista priorizada de huecos.
Documentos: `docs/01-gdd.md`, `03-mecanicas.md`, `04-niveles.md`, `05-enemigos-y-jefes.md`, `06-puzles.md`,
`09-arte-y-audio.md` (ignora el arte: está en curso en otra rama), `10-qa-y-pruebas.md`, y las specs por mundo
`13`–`16`. Código en `game/`.

Para cada requisito concreto (mecánica, enemigo, ataque, fase, puzle, recompensa, pantalla, opción, control,
accesibilidad, progresión, guardado), clasifica: **hecho**, **parcial** (qué falta), **ausente**, o **cambiado a
propósito** (si `game/IMPLEMENTACION.md` lo documenta como decisión). Cita fichero:línea en ambos lados.

Comprueba además, ejecutando el juego en headless o con pruebas cortas que crees en `tests/tmp_audit_*.gd` (bórralas
al terminar; no las registres en el runner):
- Que cada mundo cumple "nivel + puzle + jefe + segmento restaurado + núcleo + siguiente nodo desbloqueado".
- Que el Taller ofrece todo el catálogo y los precios del doc.
- Que todos los controles del doc existen (teclado y mando).
- Que la pantalla de muerte, reintento desde el inicio del jefe y checkpoints funcionan como dice el doc.

## Entrega
`logs/codex-terra-auditoria-gdd.md` con:
1. Tabla resumen (hecho / parcial / ausente / cambiado) por documento.
2. Lista de huecos ordenada por impacto para quien juega (P1 primero), cada uno con estimación (S/M/L) y propuesta de
   cambio mínimo.
3. Bugs encontrados (si los hay) con reproducción.
Haz un único commit con el informe. Sin `bd`, sin push. UN Godot propio a la vez; los de otros no cuentan ni se cierran.
No borres directorios con rm -rf. Sé eficiente: lee los docs completos, pero en el código usa grep y lee solo lo necesario.
