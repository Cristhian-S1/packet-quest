# 02 · Plan de desarrollo

## Equipo de herramientas

| Herramienta | Rol |
|---|---|
| **Claude Code** | Evaluación, investigación, documentos de diseño, orquestación y verificación |
| **Codex CLI · GPT-6 Astra** | Implementación del juego en Godot 4 / GDScript a partir de estos documentos |
| **opencode** | Revisión de código independiente (segunda opinión) y comprobación del checklist de QA |
| **Exa + Agent Reach** | Búsqueda web de buenas prácticas (Godot 4, diseño de jefes, *game feel*) |
| **Godot 4.7.2** | Motor; ejecución headless para validar escenas y pruebas |

## Hitos

| Hito | Contenido | Criterio de "terminado" |
|---|---|---|
| **M0 · Base** | `project.godot`, carpetas, InputMap, autoloads, capas de colisión | `godot --headless --quit` sin errores |
| **M1 · Byte** | Movimiento, salto variable, coyote time, jump buffer, dash, disparo en 8 direcciones, escudo, vida | Valores de `03-mecanicas.md`; pruebas de `HealthComponent` en verde |
| **M2 · Enemigos** | Pop-up y Gusano de red con aviso → ataque → recuperación; balas enemigas | Mueren, avisan y disparan solo en pantalla |
| **M3 · Nivel 1-1** | Layout de `04-niveles.md` (S1–S4), checkpoint, núcleo oculto, cámara con límites | Se puede recorrer de inicio a fin |
| **M4 · Puzle** | Ruta de paquetes de 3 nodos, puerta, reinicio | Prueba `test_route_puzzle` en verde |
| **M5 · Router Furioso** | 2 fases, ataques A/B/C, transición de fase, HUD del jefe, victoria | Prueba `test_boss_phases` en verde |
| **M6 · Bucle completo** | Menú, HUD, pausa, muerte con barra de progreso, victoria, guardado | Checklist manual de `10-qa-y-pruebas.md` |
| M7 | Taller de Mejoras + mapa de la red | Comprar y equipar 2 mejoras |
| M8–M11 | Mundos 2–5 (uno por hito) | Cada mundo cumple la estructura nivel + puzle + jefe |
| M12 | Arte final, audio, accesibilidad, exportación | Builds para Windows y Web |

**Alcance de esta entrega (prototipo vertical):** M0–M6.

## Desglose de tareas para Codex (M0–M6)

1. Crear `game/project.godot` con la configuración de `08-arquitectura-tecnica.md` (resolución, stretch, InputMap completo, nombres de las capas de colisión y autoloads).
2. Crear los autoloads `Events`, `GameState`, `SaveManager` y `AudioManager`.
3. Crear los componentes `HealthComponent`, `Hitbox` y `Hurtbox`.
4. Crear `Player.tscn` y `player.gd` (máquina de estados de `07-modelos.md`) con un visual dibujado por código.
5. Crear balas con pool: `PlayerBullet` y `EnemyBullet`.
6. Crear `EnemyBase`, `PopUp` y `NetworkWorm`.
7. Crear `World1Level1.tscn` con plataformas construidas por código o `StaticBody2D` según el layout.
8. Crear `RoutePuzzle`, `PuzzleNode` y `Door`.
9. Crear `RouterBoss` con las fases de `05-enemigos-y-jefes.md`.
10. Crear la UI: `HUD`, `DeathScreen`, `PauseMenu`, `VictoryScreen` y el menú principal `Main.tscn`.
11. Crear las pruebas headless de `10-qa-y-pruebas.md`.
12. Escribir `game/README.md` con controles y cómo ejecutar.

## Flujo de trabajo

```
Docs (Claude) ─► Implementación (Codex Astra) ─► Validación headless (Godot)
                                                       │
                     Correcciones (Codex) ◄── Revisión (opencode)
```

## Riesgos y mitigación

| Riesgo | Mitigación |
|---|---|
| Archivos `.tscn` generados a mano con errores | Construir los nodos desde código cuando sea posible; validar con `--headless` |
| Dificultad mal calibrada | Valores en `@export`; métricas de muertes por ataque |
| Alcance excesivo | Cerrar M0–M6 antes de empezar el mundo 2 |
| Falta de arte | Visuales por código con la paleta de `09-arte-y-audio.md` |
