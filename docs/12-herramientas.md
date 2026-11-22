# 12 · Herramientas, skills y plugins recomendados

Investigación del 2026-11-22 con Exa y Agent Reach (canal `github`). Las estrellas y fechas
de actividad se tomaron de GitHub ese día. **Nada de esto está instalado todavía**: instalar
plugins y MCP de terceros es decisión del equipo (beads `pq-4xx`).

## ¿Hace falta Blender?

**No.** *Packet Quest* es un juego 2D en pixel art: los personajes son sprites dibujados a
mano, de 16×16 a 192×192 px, y Blender no aporta nada a ese flujo. Blender solo tendría
sentido en dos casos que este proyecto no necesita:

- Renderizar modelos 3D como sprites ("pre-rendered", estilo *Donkey Kong Country*).
- Hacer animación por huesos muy compleja. Para esto Godot ya trae `Skeleton2D` y `Bone2D`
  (animación "cutout"), suficiente para jefes grandes como Malwarex.

Lo que sí hace falta para los "modelos" 2D:

| Necesidad | Herramienta | Coste | Nota |
|---|---|---|---|
| Sprites y animaciones pixel art | **Aseprite** | ~20 USD (o compilarlo gratis desde el código fuente) | Estándar de la industria; exporta sprite sheet + JSON que Godot importa |
| Alternativa gratuita | **Pixelorama** (11,1k ★, activo) | Gratis, MIT | Hecho en Godot; muy parecido a Aseprite |
| Alternativa gratuita | **LibreSprite** | Gratis, GPL | Fork libre de una versión antigua de Aseprite |
| Fondos e ilustraciones (menú, cartas de fase) | **Krita** | Gratis | Para arte no pixelado |
| Efectos de sonido | **jsfxr / Bfxr** | Gratis (web) | Sonidos retro en segundos |
| Música chiptune | **BeepBox**, **FamiStudio** o **LMMS** | Gratis | BeepBox funciona en el navegador |
| Edición de audio | **Audacity** | Gratis | Ya está en el documento original |

**Recomendación:** Pixelorama (gratis) o Aseprite (si se puede pagar), más jsfxr y BeepBox.
Si se quiere que un agente de IA dibuje sprites, el MCP de Aseprite (abajo) lo hace posible.

## MCP servers (dar a los agentes acceso al motor o al editor)

| Proyecto | ★ | Última actividad | Para qué | Recomendación |
|---|---:|---|---|---|
| **Coding-Solo/godot-mcp** | 6,7k | 2026-04 | Abrir el editor, ejecutar el proyecto y leer la salida de depuración | ✅ **Instalar primero**: el más usado y simple; encaja con Claude Code, Codex y opencode |
| **tugcantopaloglu/godot-mcp** | 521 | 2026-10 | 157 herramientas de control total (escenas, nodos, recursos); probado con Godot 4.7 | ⚠️ Probar si el anterior se queda corto; mucha superficie de herramientas |
| ee0pdt/Godot-MCP | 623 | 2025-03 | Plugin de editor + MCP | ❌ Sin mantenimiento desde 2025 |
| **diivi/aseprite-mcp** | 1,0k | 2026-11 | El agente dibuja y anima sprites en Aseprite | ✅ Para el hito M13 (arte final), si se usa Aseprite |
| abidoo22/Pixelorama-MCP | 50 | 2026-11 | Lo mismo para Pixelorama | ⚠️ Joven; evaluar si se elige Pixelorama |

## Skills y plugins para agentes

| Proyecto | ★ | Para qué | Recomendación |
|---|---:|---|---|
| **jame581/GodotPrompter** | 983 | Skills específicas de Godot 4 (escenas, señales, 2D, físicas, UI) para Claude Code, Copilot y Cursor | ✅ **Instalar**: `claude plugins marketplace add jame581/GodotPrompter` y después `claude plugins install godot-prompter@godot-prompter-marketplace` |
| Donchitos/Claude-Code-Game-Studios | 40,5k | 49 agentes y 75 skills que imitan un estudio completo | ⚠️ Muy pesado para un equipo pequeño; consume muchos tokens. Mirarlo como referencia de flujos (GDD, playtest) |
| godot-superpowers (varios forks) | < 10 | Skills tipo superpowers para Godot | ❌ Poco adoptados; ya usamos superpowers |
| **Scony/godot-gdscript-toolkit** (`gdlint`, `gdformat`) | 1,6k | Linter y formateador de GDScript | ✅ Instalar (`pip install gdtoolkit`) y engancharlo a un hook de pre-commit. Requiere Python, que hoy **no** está instalado en esta máquina |
| LSP de GDScript | — | Godot ya trae un servidor LSP en el puerto 6005 con el editor abierto | ✅ Útil desde VS Code (extensión *godot-tools*) |

## Ya en uso en este proyecto

| Herramienta | Uso |
|---|---|
| **superpowers** (Claude Code) | Plan (`docs/superpowers/plans/`), TDD, ejecución y revisión final |
| **beads** (`bd`) | Seguimiento de tareas en `.beads/` (`bd list`, `bd ready`) |
| **graphify** | Grafo de conocimiento del código y los docs en `graphify-out/` (generado con opencode) |
| **Codex CLI** | Implementación (usar `gpt-6.2-sol`, Astra agota la cuota) |
| **opencode** (DeepSeek V4 Pro) | Revisiones independientes y correcciones |
| **Exa + Agent Reach** | Investigación web y GitHub |

## Plan de adopción sugerido

1. `godot-mcp` (Coding-Solo) para que los agentes ejecuten el juego y lean errores sin scripts ad hoc.
2. GodotPrompter como skill de dominio para Claude Code.
3. Instalar Python y después `gdtoolkit`, con `gdlint` en un hook de pre-commit.
4. En M13: Pixelorama o Aseprite, más su MCP si se quiere arte asistido por IA.
