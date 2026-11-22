# Rendimiento de balas (pq-385)

Prueba de rendimiento de la arena del jefe Router con **100 balas enemigas + 30
balas de Byte (jugador)** activas a la vez, en headless (Godot 4.7.2).

## Criterio

| Métrica | Límite |
|---|---|
| Media por frame de física | `< 8 ms` |
| Pico por frame de física | `≤ 16 ms` (ninguno) |

## Metodología

`tests/test_performance.gd` instancia un escenario equivalente con la clase real
`ProjectilePool`, activa 130 balas y mide durante 300 frames de física con dos
instrumentos:

- **`Time.get_ticks_usec`** — wall-clock del paso de física (desde la señal
  `physics_frame` hasta `process_frame`). Es el instrumento fiable en headless.
- **`Performance.TIME_PHYSICS_PROCESS`** — monitor del motor. En headless queda
  inflado por las pausas del recolector de basura de GDScript, así que se registra
  como referencia pero el criterio se evalúa sobre el wall-clock.

## Resultados (medición aislada, misma metodología)

| | Media | Pico | Frames > 16 ms |
|---|---|---|---|
| **Antes** (código original) | 5,22 ms | 17,83 ms | 60 / 300 |
| **Después** (optimizado) | 2,27 ms | 6,66 ms | 0 / 300 |

En el runner (`tools/run-tests.sh --integration`), la medición wall-clock del paso
de física queda en **media 1,26 ms / pico 4,70 ms** (0 picos), cumpliendo
holgadamente el criterio.

## Causa raíz y optimización

El perfilado de la distribución de tiempos mostró ~60 picos periódicos (~35–60 ms)
sobre una base de 1–3 ms, patrón de pausas de GC causadas por dos problemas en
`scripts/player/projectile.gd` (el hot path de cada bala):

1. **`VisibleOnScreenNotifier2D` por bala** — cada `Projectile` creaba un notifier
   en `_ready()` que nunca se conectaba a ninguna señal (código muerto). El tracking
   de visibilidad de 130 notifiers por frame disparaba las pausas de GC. **Fix:
   eliminado.**
2. **Asignaciones por frame** — `PhysicsRayQueryParameters2D.create()` y un `Rect2`
   nuevo por bala por frame. **Fix: el `PhysicsRayQueryParameters2D` y el `Rect2`
   de culling se crean una vez en `_ready()` y se reutilizan** (`ray` y `cull_rect`).

## Capacidad del pool

El pool precarga todas las balas en `_ready()` y `fire()` nunca instancia en
caliente. La capacidad de jugador era de **24**, insuficiente para las 30 balas de
Byte; se amplió a **32** (`player_capacity`). La capacidad enemiga (128) ya cubría
las 100 balas. La prueba comprueba que `fire()` devuelve bala para las 130 peticiones
sin quedarse corto y sin crecer el pool en caliente.

## Conclusión

Con el notifier eliminado y las asignaciones del hot path cacheadas, el escenario de
130 balas pasa el criterio (media < 8 ms y ningún pico > 16 ms) con margen.
