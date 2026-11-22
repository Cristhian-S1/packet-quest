# 04 · Niveles

## Estructura de cada mundo

1. **Nivel run & gun** (4–6 min): recorrido lateral con 3–4 secciones y un checkpoint a mitad.
2. **Zona de puzle** (1–2 min): sala cerrada; resolver el puzle abre la compuerta del jefe.
3. **Jefe** (2–4 min): arena de una pantalla con 2–3 fases.

Tras el jefe: animación de "segmento restaurado", entrega de un núcleo de datos y vuelta al
mapa de la red con el siguiente nodo desbloqueado.

## Curva de dificultad

| Mundo | Enemigos nuevos | Puzle nuevo | Jefe | Fases | Mecánica que enseña |
|---|---|---|---|---:|---|
| 1 Red Local | Pop-up, Gusano de red | Ruta de paquetes | Router Furioso | 2 | Disparar, saltar, dash |
| 2 Wi-Fi | Spyware | Reparar cables | Reina Wi-Fi | 3 | Esquivar ondas, usar repetidores |
| 3 Firewall | — (variantes blindadas) | Firewall (filtrar paquetes) | Firewall Corrupto | 3 | Escudo, leer huecos |
| 4 Servidor | Troyano | Contraseñas lógicas | Troyano Real | 3 | Priorizar objetivos |
| 5 Centro de datos | Bot DDoS y todos los anteriores | Prioridad de tráfico y mezcla | Malwarex | 4 | Gestionar el caos, plataformas que se desvanecen |

## Mundo 1 · Red Local (nivel del prototipo)

**Ambientación:** interior de un switch. Placas verdes oscuras, cables Ethernet azules que
cuelgan como lianas, LEDs parpadeando, chips como plataformas.

**Duración objetivo del prototipo:** unos 2 minutos para un jugador nuevo.

### Mapa del nivel 1-1 "Puerto de entrada"

Tamaño: 2720×360 px (el jefe es una escena aparte). El suelo base está en y = 304
(borde superior de la fila 19 de tiles de 16 px).

```
 x:   0        480         1120          1760         2240        2720
      |  S1     |    S2      |     S3      |  CP   S4   |  CP  P    | → RouterBoss.tscn
      [inicio]  [plataformas][gusanos+pop] [checkpoint] [puzle]    [compuerta]
```

| Sección | Rango X | Contenido | Objetivo de diseño |
|---|---|---|---|
| **S1 Tutorial** | 0–480 | Suelo plano, 2 Pop-ups estáticos, letreros ("J dispara", "K dash") | Enseñar a disparar sin presión |
| **S2 Saltos** | 480–1120 | 4 plataformas-chip a alturas de 40–60 px, un hueco de 96 px (requiere salto + dash: el salto solo cubre unos 90 px) | Enseñar salto y dash en el aire |
| **S3 Combate** | 1120–1760 | 2 Gusanos de red en cables, 3 Pop-ups que aparecen al acercarse | Combinar movimiento y disparo |
| **Checkpoint** | 1760 | Punto de restauración | |
| **S4 Mezcla** | 1760–2240 | Cable-plataforma que se mueve en vertical, 1 Gusano y 2 Pop-ups | Disparar mientras se salta |
| **P Puzle** | 2240–2720 | Checkpoint al entrar. Sala cerrada: "Ruta de paquetes" de 3 nodos (ver `06-puzles.md`); la compuerta en x = 2720 lleva al jefe | Pausa de tensión |
| **Arena del jefe** | Escena aparte | `RouterBoss.tscn`, pantalla fija de 640×360. Al morir se reintenta desde el inicio del jefe | Router Furioso |

**Coleccionable oculto:** un núcleo de datos sobre la tercera plataforma de S2 (requiere
salto + dash hacia arriba en diagonal).

## Mundo 2 · Wi-Fi

Ambientación al aire libre: antenas, ondas visibles que empujan a Byte en horizontal.
Las plataformas son "zonas de cobertura" que se apagan si Byte se aleja del router.
Puzle: girar segmentos de cable para cerrar el circuito. Jefe: Reina Wi-Fi.

## Mundo 3 · Firewall

Muros rojos de reglas. Láseres de "puerto bloqueado" que se abren y cierran con ritmo.
Los enemigos llevan versiones blindadas que solo son vulnerables por detrás.
Puzle: clasificar paquetes por color y forma (permitir o bloquear). Jefe: Firewall Corrupto.

## Mundo 4 · Servidor

Racks verticales, ascensores de datos y ventiladores que empujan hacia arriba (corrientes
de aire). Los Troyanos abren portales de enemigos y deben eliminarse primero.
Puzle: contraseñas lógicas con pistas visuales. Jefe: Troyano Real.

## Mundo 5 · Centro de datos

Pasillos fríos (azul) y calientes (rojo) alternos. Remezcla de todos los peligros
anteriores. Plataformas de nube que se desvanecen y caché que aparece y desaparece.
Bots DDoS en oleadas. Puzle: prioridad de tráfico (orden de interruptores); además, el
puzle en combate forma parte del enfrentamiento contra Malwarex.

## Reglas de construcción de niveles

- La primera aparición de un peligro se hace en un lugar seguro (sin vacío debajo).
- Nunca hay un enemigo fuera de pantalla que dispare a Byte.
- Hay un checkpoint cada 90–120 s de juego.
- Las rutas secretas se insinúan con un LED que parpadea o un cable suelto.
- El tamaño de las tiles es 16×16 y todo el nivel se alinea a esa rejilla.
