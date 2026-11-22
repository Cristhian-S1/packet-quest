# 11 · Investigación

Búsquedas realizadas el 2026-11-22 con **Exa** (MCP) y **Agent Reach** (canales `web`, que
usa Exa por debajo, y `github`).

## Hallazgos aplicados

| Hallazgo | Dónde se aplica |
|---|---|
| Coyote time y jump buffer de ~0,1 s, salto variable cortando la velocidad al soltar | `03-mecanicas.md` |
| El dash con i-frames y enfriamiento no debe tapar un movimiento lento: primero se ajusta la velocidad base | `03-mecanicas.md` |
| Los ataques siguen startup → active → recovery; el aviso es más largo cuanto más peligroso es el ataque | `05-enemigos-y-jefes.md` |
| Fases del jefe al 70 % y al 40 %; pausa de 2,4 s, invulnerable, balas borradas y tarjeta con el nombre de la fase | `05-enemigos-y-jefes.md` |
| Los jefes de *Cuphead* tienen pocos ataques y muy telegrafiados; la pantalla de muerte muestra lo cerca que estuvo el jugador | `03-mecanicas.md` (pantalla "Conexión perdida") |
| Máquina de estados compartida para enemigos (IDLE, TELEGRAPH, ACTIVE, RECOVERY, DEAD; la fuente lo llama ATTACK) y "enrage" con menos aviso y más balas | `07-modelos.md` |
| Godot 4.7.2 es la versión estable actual | `08-arquitectura-tecnica.md` |

## Fuentes

- Cobo Makes Games — *Boss fight design: five bosses and what each one tests*. https://cobomakesgames.com/blog/boss-fight-design/
- Game Developer — *Opinion: Boss Design – Tips From A Combat Designer* (Mike Birkhead). https://www.gamedeveloper.com/design/opinion-boss-design---tips-from-a-combat-designer
- Ludonauta — *Hollow Knight Inspired Boss Fight in Godot 4*. https://ludonauta.itch.io/platformer-essentials/devlog/1089921/hollow-knight-inspired-boss-fight-in-godot-4
- Godot Asset Store — *Enemy AI* (codingquests), referencia de la estructura de estados y avisos. https://store.godotengine.org/asset/codingquests/enemy-ai/
- Tutoriales de controlador de plataformas para Godot 4 (CharacterBody2D, coyote time, jump buffer) encontrados en la búsqueda con Exa.
