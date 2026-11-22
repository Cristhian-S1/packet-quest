# Prueba de interfaz real — Codex

Fecha: 22-11-2026. Godot 4.7.2, Windows, ventana de 1302 × 776, `--accessibility always`; control mediante Orca y árbol de accesibilidad. La partida original se respaldó; se usó otra con cinco mundos desbloqueados y 99 núcleos. Se restauró el original y se verificó SHA-256 `6346EC7849630C2E5F74EF0F555DB4B31E0D8C9E04A1181205FF7695D370ABA3` antes y después. El guardado es compartido con otros worktrees. Se cerraron solamente los procesos gráficos lanzados para esta prueba.

| Paso | Esperado | Obtenido | Estado |
|---|---|---|---|
| Menú principal | Jugar, opciones y salir | Jugar y Salir tienen nombre accesible; no aparece Opciones. Jugar abre el mapa. Salir no se activó en esta sesión. | FALLO: falta Opciones; Salir pendiente |
| Mapa original | Red Local disponible; mundos restantes bloqueados | Cinco mundos, Red Local disponible y cuatro BLOQUEADO. Sin PRÓXIMAMENTE. | OK |
| Mapa desbloqueado | Seleccionar cinco mundos con izquierda/derecha | Los cinco figuran disponibles; el botón muestra Red Local, Wi-Fi, Firewall, Servidor y Centro de datos. Izquierda desde el primero llega al último y derecha avanza. | OK |
| Taller sin núcleos | Mostrar Sin núcleos | Observado en captura y reporte anterior del agente; no repetido en esta sesión. | OK anterior |
| Taller con núcleos | Comprar, descontar y reflejar estados | 99 → 97 por Más vida, Instalada; 97 → 95 por Ráfaga triple, Equipada; al quitarla, Equipar; compra de Ping 95 → 93, Ping Equipada y Ráfaga triple Ranuras llenas. Comprar visible antes de comprar. | OK |
| Taller → Volver al mapa | Volver al mapa | Mapa visible con 93 núcleos. | OK |
| Entrar a Red Local | Abrir 1-1 | Instrucciones y HUD del nivel; posterior pantalla Conexión perdida con Reintentar y Menú principal. | OK |
| Entrar a Wi-Fi | Abrir 2-1 | Aparecen Zona de cobertura, puzle y Reina Wi-Fi en el árbol. | OK |
| Entrar a Firewall | Abrir 3-1 | Aparecen Muro de reglas, filtro y Firewall Corrupto. | OK |
| Entrar a Servidor | Abrir 4-1 | Aparecen Sala de servidores, contraseñas y Troyano. | OK |
| Entrar a Centro de datos | Abrir 5-1 | Primera ejecución: pantalla vacía y errores de clases no encontradas en caché; tras `--import`, se abre 05-1 con prioridad de tráfico y HUD. | OK tras importar; incidencia de entorno inicial |
| Escape, pausa y continuar | Menú de pausa y reanudación | En Red Local, Wi-Fi y Centro de datos, `press-key Escape` no produjo el menú observable. Orca indicó `synthetic_input` sin verificar; no se puede determinar si la causa es el juego o la inyección. Continuar y volver al menú desde pausa quedan pendientes. | PENDIENTE |
| Volver al menú desde cada nivel | Menú principal | Se vio Menú principal en muerte de Red Local; los demás niveles se cerraron por PID para continuar al no poder abrir pausa. No se verificó el retorno desde cada nivel. | PENDIENTE |
| Créditos | Pantalla accesible tras Malwarex | Escena abierta directamente: epílogo, estadísticas, créditos y botones Menú principal y Nueva partida; Menú principal funcionó. Acceso directo no prueba la victoria, transición ni las estadísticas de una partida real. | PARCIAL |
| Mando y navegación completa por teclado | Foco y acciones disponibles | Flechas del mapa verificadas. El árbol informó `focusedElementId: null`; no se comprobó mando ni navegación completa por teclado. | PENDIENTE |

## Hallazgos y límites

- `game/scripts/main/main.gd:12`: el menú crea Jugar y Salir, pero no ofrece Opciones. No se modificó el juego: se documenta como ausencia de la interfaz solicitada, sin prescribir un diseño.
- `game/scripts/ui/hud.gd:54` y `game/project.godot:65`: Escape no abrió una pausa observable con Orca. La herramienta solo certificó una inyección sintética; esto no prueba por sí mismo un defecto del juego ni que una tecla física falle.
- Caché inicial obsoleta: en `game/scripts/levels/world5_level1.gd:18` y otras dependencias hubo errores de tipos globales no encontrados; después de importar Godot registró las clases y el nivel abrió. No se modificó código y no se atribuye la causa a un bug confirmado del juego.
- No se verificaron recortes de texto de manera exhaustiva ni nombres accesibles de todos los controles; los botones observados en menú, mapa, Taller, muerte y créditos sí tenían nombre. El foco de mando y el recorrido completo con teclado siguen pendientes.
- Las capturas de esta sesión están en `docs/capturas/gui/06-*` a `30-*`; las capturas 01–05 proceden del agente anterior. `10` y `29` documentan la carga fallida antes de importar; `11` muestra la carga posterior. `12` es acceso directo a créditos, no victoria de Malwarex.

## Suite automatizada

`bash tools/run-tests.sh --integration` terminó con código 0. Salida final literal:

```text
RESULTADO: 17/17 PASS
PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia
```

La salida filtrada de la suite no mostró `SCRIPT ERROR` ni `ERROR`. No se añadieron pruebas automatizadas ni se alteró el código del juego.
