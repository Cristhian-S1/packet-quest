# 03 · Mecánicas

Todos los valores son de partida y se ajustan en playtest. Unidades: píxeles lógicos
(resolución 640×360) y segundos. Todos los valores deben exponerse como `@export` en el
Inspector.

## Controles

| Acción (InputMap) | Teclado | Mando |
|---|---|---|
| `move_left` / `move_right` | A / D · ← / → | Stick izq. / D-pad |
| `aim_up` / `aim_down` | W / S · ↑ / ↓ | Stick izq. arriba/abajo |
| `jump` | Espacio · Z | A / Cruz |
| `shoot` | J · X | X / Cuadrado (mantener = automático) |
| `dash` | K · Shift | B / Círculo |
| `shield` | L · C | LB / L1 (mantener) |
| `lock_aim` | I · V | RB / R1 (mantener: Byte no se mueve y apunta en 8 direcciones) |
| `interact` | E | Y / Triángulo |
| `swap_weapon` | Q | Select / Back |
| `pause` | Esc | Start |

## Movimiento de Byte

| Parámetro | Valor | Nota |
|---|---:|---|
| Velocidad horizontal | 150 px/s | Aceleración 1200 px/s², fricción 1600 px/s² |
| Gravedad | 900 px/s² | ×1,6 al caer (caída más rápida = sensación precisa) |
| Velocidad de salto | −330 px/s | ≈ 60 px de altura máxima |
| Salto variable | Soltar `jump` en subida → velocidad × 0,45 | Toque = salto corto |
| Coyote time | 0,10 s | Saltar justo después de salir del borde |
| Jump buffer | 0,10 s | Pulsar salto justo antes de tocar el suelo |
| Velocidad máxima de caída | 420 px/s | |

## Dash ("Modo seguro")

| Parámetro | Valor |
|---|---:|
| Distancia | 72 px (96 px con mejora *Dash extendido*) |
| Duración | 0,18 s (sin gravedad) |
| Invulnerabilidad (i-frames) | 0,15 s desde el inicio |
| Enfriamiento | 0,6 s |
| Uso en el aire | 1 vez por salto (se recupera al tocar el suelo) |

Feedback: rastro de "estela de datos" (3 fantasmas cian), sonido de *whoosh* digital.

## Disparo de datos

| Arma | Daño | Cadencia | Velocidad | Notas |
|---|---:|---:|---:|---|
| **Paquete** (base) | 1 | 8 disparos/s | 480 px/s | Recto, alcance infinito hasta salir de la pantalla |
| **Ráfaga triple** (mejora) | 0,6 c/u | 5/s | 420 px/s | 3 balas en abanico de ±12° |
| **Ping** (mejora) | 1,3 | 6/s | 300 px/s | Teledirigido suave, gira 180°/s |

- 8 direcciones de apuntado con `lock_aim`; sin él, horizontal, arriba o diagonal arriba.
- Máximo de 24 balas del jugador en pantalla (pool).

## Escudo de firewall

| Parámetro | Valor |
|---|---:|
| Medidor | 100 |
| Consumo activo | 40/s |
| Coste por proyectil bloqueado | 15 |
| Recarga | 12/s tras 1,0 s sin usarlo |
| Restricciones | Solo bloquea proyectiles **frontales**; no se puede disparar mientras está activo; velocidad × 0,5 |
| Rotura | Si el medidor llega a 0, el escudo queda bloqueado 2,0 s |

Esto diferencia el escudo (defensa sostenida que cuesta un recurso) del dash (esquiva
puntual con enfriamiento).

## Vida y daño

- Byte tiene **3 PV** (4 con la mejora *Más vida*). En el HUD se muestran como "barras de señal".
- Al recibir daño: retroceso de 120 px/s, invulnerabilidad de 1,0 s con parpadeo y *hit-stop* de 0,05 s.
- Caer al vacío = −1 PV y reaparición en la última plataforma segura.
- PV = 0 → pantalla **"Conexión perdida"**, que muestra el progreso del nivel o del jefe y ofrece reintentar con un botón.
- Checkpoints ("Puntos de restauración") a mitad de nivel, al inicio del puzle y al inicio del jefe.
- **Daño recibido:** todo proyectil enemigo, contacto con un enemigo o jefe y ataque de jefe quita **1 PV**. Los peligros del escenario (láseres, pinchos) también quitan 1 PV.

## Habilidad de red (interacción)

- Los **Nodos de red** (terminales con un icono de enchufe) brillan cuando Byte está a ≤ 24 px.
- `interact` → conecta el nodo y activa sus `targets`: abrir puertas, mover plataformas, revelar rutas ocultas o iniciar un puzle.
- Algunos nodos están corruptos: hay que dispararles 3 veces para "limpiarlos" antes de usarlos.

## Progresión: núcleos de datos y mejoras

- Cada jefe da **1 núcleo de datos**. Además hay 2 núcleos ocultos por mundo, tras rutas secretas o puzles opcionales (el prototipo del Mundo 1 incluye solo 1).
- Las mejoras se compran en el **Taller de Mejoras** del mapa de la red.

| Mejora | Coste | Tipo | Efecto |
|---|---:|---|---|
| Más vida | 2 | Permanente | +1 PV |
| Ráfaga triple | 2 | Arma | Desbloquea el arma de abanico |
| Ping | 2 | Arma | Desbloquea el arma teledirigida |
| Dash extendido | 1 | Permanente | Dash de 96 px |
| Firewall reforzado | 1 | Pasiva | Escudo con medidor de 150 y recarga ×1,3 |
| Marcador | 2 | Pasiva | Los enemigos marcados reciben +25 % de daño |
| Ralentizador | 3 | Pasiva | 1 vez por nivel: los proyectiles enemigos van al 50 % durante 3 s (activación automática al quedar con 1 PV) |

- Ranuras: **2 armas** (se cambian con `swap_weapon`) + **1 pasiva** equipada.
  Más vida y Dash extendido son permanentes y no ocupan ranura.

## Sensación (*game feel*)

- Hit-stop de 0,05 s al recibir daño y de 0,03 s al destruir un enemigo.
- Sacudida de cámara: 2 px al golpear al jefe y 6 px en los cambios de fase (se puede desactivar).
- Destello blanco de 1 frame en el enemigo que recibe daño.
- Partículas de "bits" al destruir enemigos.

## Accesibilidad

- Modo asistido: velocidad del juego al 80 % y +1 PV (no bloquea logros).
- Reducir parpadeos y sacudida de cámara.
- Remapeo completo de controles.
- Avisos de ataque con forma y sonido, no solo con color.
