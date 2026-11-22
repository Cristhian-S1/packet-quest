# 05 · Enemigos y jefes

## Reglas generales de combate

- Todo ataque sigue el ciclo **startup (aviso) → active → recovery**.
  El aviso es proporcional al peligro: ataques rápidos y pequeños con 0,3 s de aviso,
  ataques grandes que llenan la pantalla con 0,8–1,2 s.
- El aviso siempre se comunica con **forma + sonido + color**: un destello, una línea
  discontinua que marca la trayectoria o un círculo que pulsa.
- Proyectiles enemigos: rosa o magenta. Los proyectiles **destructibles** se dibujan con
  contorno blanco.
- Los enemigos solo disparan cuando están dentro de la pantalla.
- **Daño:** cada proyectil, contacto o ataque enemigo (incluidos los de los jefes) quita **1 PV** a Byte. La dificultad se regula con densidad, velocidad y aviso, nunca subiendo el daño.

## Enemigos comunes

| Enemigo | PV | Movimiento | Ataque | Aviso | Mundo |
|---|---:|---|---|---|---|
| **Pop-up** | 3 | Aparece de golpe en un punto fijo (animación de ventana que se abre) | Dispara 1 "anuncio" lento (120 px/s) hacia Byte cada 1,8 s | Su barra de título parpadea 0,4 s | 1+ |
| **Gusano de red** | 5 | Recorre un cable (`Path2D`) a 60 px/s | Al recibir daño se divide: suelta 2 paquetes en arco | Se hincha 0,3 s antes de dividirse | 1+ |
| **Spyware** | 4 | Inmóvil, disfrazado de pickup | Salta hacia Byte cuando está a < 64 px | Parpadeo con glitch durante 0,4 s | 2+ |
| **Troyano** | 8 | Camina despacio (40 px/s) | Abre un portal que genera 2 Pop-ups cada 5 s | El portal crece durante 1 s | 4+ |
| **Bot DDoS** | 2 | Vuela en formación (onda sinusoidal) | Suelta 6 balas lentas en abanico | Se ilumina 0,6 s | 5+ |

Al destruirlos: partículas de bits y, con un 10 % de probabilidad, un "fragmento de caché"
que recupera 20 de escudo.

## Jefes

Reglas de fase (todos los jefes):

- Cambio de fase al **70 %** y al **40 %** de vida en jefes de 3 fases, solo al **50 %** en jefes de 2 fases y al **75/50/25 %** en Malwarex (4 fases).
- Al cruzar el umbral el jefe termina su ataque actual y se detiene **2,4 s**: es
  invulnerable, sus balas desaparecen y aparece una tarjeta con el nombre de la fase.
- La pantalla de muerte muestra una barra con el progreso del jefe y las marcas de fase.

### 1 · Router Furioso (Mundo 1, mini-jefe del prototipo)

Un router enorme con 4 antenas y ojos de LED. Arena: suelo plano de 640 px en y = 304 y 2 plataformas-chip
flotantes a ambos lados con el borde superior en y = 256 (48 px sobre el suelo, alcanzables
con el salto de ~60 px).

| | Fase 1 "Señal estable" (100–50 %) | Fase 2 "Sobrecarga" (50–0 %) |
|---|---|---|
| PV | 60 en total | |
| Ataque A | **Anillo de señal:** 12 balas en círculo desde la antena central (150 px/s). Aviso: la antena brilla 0,6 s. Cada 3 s. | Anillo doble: 2 anillos de 12 desfasados 15°, a 0,35 s de distancia. |
| Ataque B | **Estampida de paquetes:** 4 paquetes rodando por el suelo desde un lado (200 px/s). Aviso: flechas en el borde de la pantalla durante 0,8 s. Hay que saltar o hacer dash. | La estampida llega desde ambos lados de forma alterna y la última fila salta. |
| Ataque C | — | **Ping láser:** un rayo horizontal a la altura de Byte. Aviso: línea discontinua durante 1,0 s. |
| Patrón | A, B, A, B… | A, C, B, A, C, B… (más rápido: −20 % de recovery) |
| Punto débil | El cuerpo completo (hurtbox) | Igual |

### 2 · Reina Wi-Fi (Mundo 2)

Flota en el centro y emite ondas que cambian de dirección. En la arena hay **repetidores**
que Byte puede activar (con `interact`) para crear una barrera temporal de 3 s.
- F1: ondas horizontales que rebotan en las paredes.
- F2: ondas en espiral; teletransporte entre antenas.
- F3: "Interferencia": la pantalla se divide en zonas con y sin señal; las zonas sin señal hacen daño.

### 3 · Firewall Corrupto (Mundo 3)

Un muro gigante que ocupa el lado derecho. Abre huecos (puertos) donde está su núcleo vulnerable.
- F1: dispara "reglas de bloqueo" (barras horizontales) con huecos para pasar.
- F2: los puertos se abren en secuencia; hay que disparar al puerto correcto según el color que indica.
- F3: el muro avanza hacia Byte; hay que romper sus ladrillos para hacerlo retroceder.

### 4 · Troyano Real (Mundo 4)

Se esconde dentro de un cofre digital. Solo es vulnerable cuando se abre.
- F1: el cofre salta por la arena; al aterrizar se abre 1,5 s.
- F2: invoca troyanos menores; si se eliminan rápido, el cofre se queda abierto más tiempo.
- F3: falsos cofres (mímicos); el verdadero brilla un instante al principio de cada ciclo.

### 5 · Malwarex (jefe final, Mundo 5)

Un virus con forma de núcleo glitch rodeado de ventanas emergentes y cables vivos.
- F1: remezcla de los ataques del Router y de la Reina Wi-Fi.
- F2: cables vivos que barren la arena y ventanas emergentes que bloquean la vista.
- F3: puzle en combate: conectar 3 nodos en la arena mientras esquiva para dejarlo vulnerable.
- F4: "Borrado de datos": el suelo desaparece por columnas; quedan plataformas mínimas.
