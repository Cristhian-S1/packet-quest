# Prueba de interfaz real (Orca computer use) — parcial

El agente opencode se cortó por el límite de uso de OpenCode Go antes de escribir el informe.
Resumen hecho por Claude a partir de su salida (`logs/opencode-gui.md`) y de las capturas.

| Paso | Esperado | Obtenido | Estado |
|---|---|---|---|
| Lanzar con `--accessibility always` | Botones visibles en el árbol de accesibilidad | "Jugar →", botones del mapa, Taller y pantalla de muerte visibles | OK |
| Menú principal → Jugar | Abre el mapa | Mapa de la red | OK |
| Mapa | Mundo 1 disponible, 2 bloqueado, resto PRÓXIMAMENTE | Correcto, pero muestra 6 mundos (Nube) | Pendiente `pq-7c4` (5 niveles) |
| Taller sin núcleos | Todas las filas "Sin núcleos", descripción visible | Correcto | OK |
| Entrar a 1-1 y morir | Pantalla "Conexión perdida" con Reintentar / Menú principal y barra de progreso | Correcto | OK |
| Pausa, opciones, compras con núcleos | — | No llegó a probarse | Pendiente |

Observaciones: la partida de desarrollo `user://save.json` es compartida por todos los worktrees
(contiene muertes de `nivel_3_1` de Codex M9): las pruebas de interfaz deben usar una copia y restaurarla.
