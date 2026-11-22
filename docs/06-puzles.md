# 06 · Puzles

Principio: cada puzle se entiende **sin saber programar ni redes**, solo mirando. Después
de resolverlo aparece una línea de "dato curioso" que explica el concepto de red real
(opcional; se puede omitir).

Reglas comunes:
- Se juegan dentro del nivel con el propio Byte (sin menús aparte), usando `interact` o disparos.
- No tienen límite de tiempo, salvo el puzle en combate del jefe final.
- Siempre hay un botón de reinicio (un nodo con el icono ↺).
- Al resolverlo: un sonido de "conexión establecida", los cables se iluminan y se abre la compuerta.

## 1 · Ruta de paquetes (Mundo 1 · prototipo)

**Concepto real:** enrutamiento. Un paquete necesita un camino completo del emisor al receptor.

**Mecánica del prototipo (3 nodos):**
- La sala tiene un **Emisor** (izquierda), un **Receptor** (derecha) y **3 nodos-switch** entre ellos.
- Cada nodo tiene una flecha que apunta en una de 4 direcciones. `interact` la gira 90° en sentido horario.
- Cuando las 3 flechas forman una cadena Emisor → N1 → N2 → N3 → Receptor, el cable se ilumina y se abre la puerta.
- Solución fija para el prototipo: N1 = derecha, N2 = arriba, N3 = derecha (el N2 está por debajo del N3).
- Estado visual: un nodo conectado correctamente se ve cian; uno sin conectar, gris.

**Modelo:** `RoutePuzzle` con `nodes: Array[PuzzleNode]` y `solution: Array[int]` (dirección
0–3 por nodo). Comprueba la solución con cada cambio y emite `solved`.

## 2 · Reparar cables (Mundo 2)

Rejilla de 4×3 tiles de cable (recto, codo, T). Se giran con disparos. Hay que conectar la
antena con el router. Inspiración: el clásico puzle de tuberías.

## 3 · Firewall (Mundo 3)

Una cinta transporta paquetes de colores y formas. Byte controla 2 compuertas: dejar pasar
o bloquear. Regla mostrada en pantalla, por ejemplo: "Bloquea ROJO · Permite ▲".
Hay que filtrar 10 paquetes con 2 fallos como máximo.

## 4 · Contraseñas lógicas (Mundo 4)

Panel de 4 símbolos. Las pistas visuales están escondidas en la sala (pósteres, LEDs). Ejemplo:
"El círculo va antes que el triángulo", "El cuadrado no va al final".
Concepto: autenticación (y por qué las contraseñas obvias son malas).

## 5 · Prioridad de tráfico (Mundo 5)

4 interruptores que activan puentes. Cada uno tiene una etiqueta (Voz, Vídeo, Correo,
Descarga). Hay que activarlos en orden de prioridad (QoS); el orden se muestra con iconos
de urgencia. Si el orden es incorrecto, los puentes se caen y se reinicia.

## 6 · Puzle en combate (Malwarex)

3 nodos en la arena. Hay que conectarlos (interact) mientras el jefe ataca; cada nodo
conectado elimina un escudo del jefe.

## Pistas

Si el jugador tarda más de 60 s, el nodo correcto parpadea suavemente una vez cada 10 s.
