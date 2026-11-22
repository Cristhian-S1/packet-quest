# Packet Quest: La Red Rota

Prototipo vertical jugable M0–M9 en **Godot 4.7.2**, con GDScript tipado y renderer Compatibility. Gráficos procedurales, sin recursos externos ni complementos. Resolución lógica 640×360, ventana 1280×720, escala entera y filtro nearest.

## Jugar

Importa `game/project.godot` en Godot 4.7.2 y pulsa **F6** en `Main.tscn` o **F5** para ejecutar el proyecto. En el menú, elige **Jugar**; navega los botones con flechas o cruceta y confirma con Enter o A/Cruz.

Desde la raíz del repositorio, en PowerShell:

```powershell
$godot = 'C:/Users/alumnos.LAPTOP-LGABPBVS/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
& $godot --path game
```

Recorre S1–S4, conecta la ruta de tres nodos y cruza la compuerta. Derrota al Router y recoge el núcleo ámbar para guardar y mostrar la victoria. El checkpoint de la arena permite reintentar directamente el jefe. Los checkpoints recuperan la vida; el vacío resta un PV y devuelve a la última plataforma segura.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Mover | A/D, ←/→ | Stick izquierdo, cruceta horizontal |
| Apuntar arriba/abajo | W/S, ↑/↓ | Stick izquierdo vertical |
| Saltar; soltar para salto corto | Espacio, Z | A / Cruz |
| Disparar automáticamente al mantener | J, X | X / Cuadrado |
| Dash direccional | K, Shift | B / Círculo |
| Firewall frontal | L, C | LB / L1 |
| Fijar posición y apuntar en ocho direcciones | I, V | RB / R1 |
| Interactuar a 24 px | E | Y / Triángulo |
| Cambiar arma | Q | Select / Back |
| Pausar / continuar | Esc | Start |

El dash recorre 72 px en 0,18 s, protege durante 0,15 s y se recarga en 0,6 s. Hay un dash aéreo por salto. El firewall impide disparar, reduce la velocidad a la mitad y solo bloquea proyectiles que llegan por delante. Q alterna entre las 2 armas equipadas (Paquete, Ráfaga triple o Ping).

En el puzle, E gira la flecha del nodo más cercano. El terminal verde **REINICIAR** restaura los tres nodos y cierra la puerta. La solución es **derecha, arriba, derecha**. El nodo superior se alcanza saltando; las pistas suaves se activan tras 60 segundos en la sala.

## Hitos y archivos

| Hito | Implementación |
|---|---|
| M0 | `project.godot`: 12 acciones de entrada, ocho capas, 60 Hz; cuatro autoloads en `scripts/autoload/`. |
| M1 | `Player.tscn`, `player.gd`, vida/hitbox/hurtbox, arma Resource y pools: 24 proyectiles propios + 128 enemigos. |
| M2 | `PopUp.tscn`, `NetworkWorm.tscn`, estados de aviso/ataque/recuperación, daño y fragmentos de caché. |
| M3 | `World1Level1.tscn`: 2720 px, secciones S1–S4, hueco de 96 px, cable móvil, checkpoints y núcleo oculto. |
| M4 | `RoutePuzzle.tscn`, `PuzzleNode.tscn`, `Door.tscn`, ruta visual, reinicio y puerta en x=2720. |
| M5 | `RouterBoss.tscn`: 60 PV, dos fases, anillos/estampida/láser, pausa invulnerable de 2,4 s, tarjeta y barra. |
| M6 | Menú, HUD, pausa, muerte con progreso, reintento, núcleo final, victoria y guardado validado. |

```text
game/
  project.godot
  scenes/       29 escenas con hijos construidos en _ready
  scripts/      autoload, components, data, player, enemies, levels,
                objects, puzzles, bosses, ui, main
  resources/    arma Paquete y dos fases del Router en .tres
  assets/       directorios vacíos; fuente incorporada de Godot
  tests/        runner de nueve pruebas, suite de integración y capturas
  validation/   logs y capturas generadas por el propio motor (.gdignore)
  IMPLEMENTACION.md
```

## Pruebas y validación

Desde la raíz del repositorio, con la variable `$godot` anterior:

```powershell
& $godot --headless --path game --import
& $godot --headless --path game --quit
& $godot --headless --path game -s res://tests/test_runner.gd
& $godot --headless --path game --quit-after 300
```

El runner imprime PASS/FAIL por prueba y termina con código **0** al pasar todas, o **1** ante fallos. Comprueba vida, ruta, fases, guardado válido/corrupto y carga e inicialización de todas las escenas. Usa archivos `user://test_*.json`, independientes de la partida real, y los elimina al terminar.

Prueba adicional con física y acciones de entrada:

```powershell
& $godot --headless --path game -s res://tests/test_integration.gd
```

Incluye InputMap físico, disparos reales contra un enemigo, cadencia de 8/s, distancia del dash, salto variable, coyote, buffer, hueco, escudo frontal/trasero, invulnerabilidad, vacío, reciclado del pool, transporte en plataforma móvil, interacción del puzle, transición a la arena, muerte/reintento, enemigos fuera de pantalla, ataques A/B/C, periodo del anillo y derrota → recoger núcleo → guardar → victoria.

Capturas reproducibles con ventana y renderer real (se cierra automáticamente):

```powershell
& $godot --path game -s res://tests/capture_preview.gd
```

## Guardado y decisiones del prototipo

`user://save.json` usa el esquema versión 1 de `07-modelos.md`, con escritura temporal y reemplazo. Un archivo ausente, JSON roto o estructura incompatible devuelve valores iniciales. Los núcleos tienen identificadores persistentes para impedir duplicarlos al reintentar. Los checkpoints permanecen durante la sesión; **Jugar** inicia el recorrido conservando núcleos, estadísticas y niveles completados.

El nivel 1-1 mide **2720 px** (suelo y=304, alineado a la rejilla de 16 px); el jefe es una escena aparte y la compuerta/transición están en x=2720. Hay checkpoints en x=1760, x=2240 (entrada del puzle) y el inicio de la arena del jefe. Las plataformas del jefe están en y=256. La tercera plataforma de S2 forma un desembarco elevado para que el hueco enseñe salto + dash sin alterar los valores del jugador.

Se han elegido los tiempos no fijados por el diseño: láser activo 0,45 s; estampida activa 0,84 s, paquetes cada 0,21 s; recuperación base 0,20 s, reducida un 20 % en F2. En F1 el anillo respeta tres segundos entre emisiones dentro de la precisión de un tick físico; F2 mantiene la secuencia A/C/B y sus avisos completos. Al cruzar 50 % durante ACTIVE se termina ese ataque antes de la transición.

El Gusano usa un Area2D raíz con Path2D/PathFollow2D internos. Las siluetas y animaciones se dibujan por código. Las opciones `screen_shake`, `reduce_flashes` y `assist_mode` del guardado ya se respetan.

No se ha hecho el playtest con cinco personas ni se certifican 60 FPS gráficos con 100 balas en hardware objetivo. Las pruebas automáticas y las capturas no sustituyen esa evaluación de dificultad y rendimiento.

## M7 · Taller de Mejoras y Mapa de la red

- **Menú → Mapa de la red** muestra los cinco segmentos y el progreso de la partida.
- **Taller:** gasta núcleos de datos en 7 mejoras (`resources/upgrades/*.tres`). Las armas (Ráfaga triple, Ping) se equipan en 2 ranuras; las pasivas (Firewall reforzado, Marcador, Ralentizador) en 1 ranura; Más vida y Dash extendido son permanentes.
- La lógica está en `scripts/progression/progression.gd` (pura, probada en `tests/test_progression.gd`) y los datos en `scripts/data/catalog.gd`.

## M8 · Mundo 2 Wi-Fi

Vence al Router Furioso y recoge su núcleo para desbloquear Wi-Fi. En el mapa, usa **← / →** con el foco en **Entrar** para elegir un mundo disponible. Usa **↓** para pasar a Taller y Menú.

- **Zona de cobertura (2-1).** Las ondas empujan a Byte. Salta entre plataformas sin salir del alcance del router y busca los dos núcleos de datos. El foso es letal y el recorrido tiene dos puntos de restauración.
- **Spyware.** Se camufla como núcleo, se revela cuando te acercas y avisa antes de saltar. Puedes dispararle desde que se revela.
- **Reparar cables.** Dispara a las piezas para girarlas. Ponte debajo de una pieza y salta para acertar en las filas superiores. Interactúa con **↻ Reiniciar** para restaurar la disposición original.
- **Reina Wi-Fi.** Tiene 90 PV y tres fases. Acércate a un repetidor y pulsa **E** (o **Y / Triángulo**) para activar una cúpula durante tres segundos. Al vencer a la Reina, puedes seleccionar Firewall en el mapa.

Desde la raíz del repositorio, ejecuta la suite completa y las pruebas de 300 frames:

```powershell
bash tools/run-tests.sh --integration
& $godot --headless --path game --fixed-fps 60 --quit-after 300 res://scenes/levels/World2Level1.tscn
& $godot --headless --path game --fixed-fps 60 --quit-after 300 res://scenes/bosses/WifiQueenBoss.tscn
```

Regenera ambas capturas con el renderer Compatibility:

```powershell
& $godot --path game -s res://tests/capture_preview.gd -- --m8
```

[Zona de cobertura](../docs/capturas/level2.png) · [Reina Wi-Fi](../docs/capturas/boss2.png)

## M9 · Mundo 3 Firewall

Vence a la Reina Wi-Fi y selecciona **Firewall** con **← / →** en el mapa.

- **Muro de reglas (3-1).** Rodea a los enemigos blindados para disparar por detrás. Cruza los láseres cuando se abran y usa salto con dash para superar el foso. Después del primer checkpoint, las plataformas te dan acceso a los huecos más altos de la barra.
- **Filtro de paquetes.** Acércate a **PASAR** o **BLOQUEAR** y pulsa **E** (o **Y / Triángulo**). Solo pasan los triángulos verdes y azules. Puedes cometer hasta dos fallos en diez paquetes. Usa **↺ Reiniciar** para volver a empezar.
- **Firewall Corrupto.** Tiene 120 PV. Usa las plataformas para disparar por el puerto abierto y esquiva los barridos por los huecos. En la última fase, cada disparo a un ladrillo empuja el muro hacia atrás. La victoria guarda el progreso y devuelve a Byte al mapa con **Servidor** desbloqueado y marcado **PRÓXIMAMENTE**.

```powershell
bash tools/run-tests.sh --integration
& $godot --headless --path game --fixed-fps 60 --quit-after 300 res://scenes/levels/World3Level1.tscn
& $godot --headless --path game --fixed-fps 60 --quit-after 300 res://scenes/bosses/FirewallBoss.tscn
& $godot --path game -s res://tests/capture_preview.gd -- --m9
```

[Muro de reglas](../docs/capturas/level3.png) · [Firewall Corrupto](../docs/capturas/boss3.png)
