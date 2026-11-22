# Packet Quest: La Red Rota

## Descripción general

**Packet Quest: La Red Rota** es un videojuego 2D de acción, plataformas y puzles
inspirado en la estructura de *Cuphead*: niveles de *run and gun* alternados con
jefes memorables.

El jugador controla a **Byte**, un pequeño paquete de datos con guantes, patas de
circuito y un cañón de energía. Un virus llamado **Malwarex** ha infectado la Gran
Red: corrompió routers, secuestró servidores y bloqueó el acceso a Internet.

La misión es recorrer la red, eliminar virus, reparar conexiones y derrotar a los
guardianes corruptos para restaurar el flujo de datos.

## Género y temática

- **Género principal:** Shooter 2D de plataformas (*run and gun*).
- **Géneros secundarios:** Puzles, acción, aventura y jefe final por nivel.
- **Estilo visual:** 2D lateral, retro-techno, ambientado en una red informática.
- **Etiqueta corta:** Shooter 2D de plataformas y puzles.

## Proporción de gameplay

| Elemento | Peso en el juego | Ejemplo en *Packet Quest* |
|---|---:|---|
| Shooter / combate | 45% | Disparar paquetes, esquivar virus y derrotar enemigos. |
| Plataformas | 25% | Saltar entre chips, cables y servidores. |
| Jefes | 20% | Router Furioso, Firewall Corrupto y Malwarex. |
| Puzles | 10% | Conectar nodos, reparar cables u ordenar rutas de datos. |

## Estética y ambientación

- Vista lateral 2D, con plataformas, disparos y esquivas.
- Estilo retro-techno: colores neón, cables como lianas, chips como plataformas,
  ventanas emergentes como enemigos y datos como proyectiles.
- Cada nivel representa una parte distinta de una red:
  - Red local.
  - Wi-Fi.
  - Servidor.
  - Nube.
  - Firewall.
  - Centro de datos.

## Mecánicas principales

| Mecánica | Cómo funciona |
|---|---|
| Disparo de datos | Byte lanza “paquetes” de energía para destruir virus y torres corruptas. |
| Esquiva / dash | Un impulso rápido que permite atravesar brevemente zonas de peligro, como un “modo seguro”. |
| Escudo de firewall | Bloquea proyectiles durante unos segundos, pero se recarga lentamente. |
| Habilidad de red | Permite conectarse a nodos para abrir puertas, activar plataformas o revelar rutas ocultas. |
| Puzles de circuitos | El jugador debe reconectar cables, ordenar paquetes o configurar rutas para avanzar. |

## Estructura de niveles

Cada mundo tendrá tres partes:

1. **Nivel de plataformas y combate:** recorrer cables, evitar paquetes corruptos y derrotar enemigos.
2. **Zona de puzles:** resolver un problema de redes para desbloquear el acceso al jefe.
3. **Jefe final:** un combate de varias fases con patrones que el jugador debe aprender y esquivar.

## Enemigos

- **Pop-ups:** enemigos pequeños que aparecen de golpe y disparan anuncios.
- **Gusanos de red:** se mueven por cables y dividen paquetes en proyectiles.
- **Spywares:** se camuflan como objetos útiles y atacan cuando el jugador se acerca.
- **Troyanos:** abren puertas para que entren más enemigos.
- **Bots DDoS:** lanzan oleadas masivas de proyectiles lentos pero numerosos.

## Jefes por mundo

1. **Router Furioso:** lanza señales en círculos y obliga a esquivar entre antenas.
2. **Reina Wi-Fi:** controla ondas que cambian de dirección; hay que usar repetidores para bloquearlas.
3. **Firewall Corrupto:** un muro gigante que abre huecos y dispara reglas de bloqueo.
4. **Troyano Real:** se esconde dentro de un cofre digital e invoca troyanos menores.
5. **Malwarex:** jefe final; combina virus, ventanas emergentes, cables vivos y ataques de “borrado de datos”.

## Puzles de informática y redes

Los puzles deben ser comprensibles sin necesidad de saber programar:

- **Ruta de paquetes:** conectar nodos para que un paquete llegue del emisor al receptor.
- **Reparar cables:** girar tuberías o cables para restaurar la conexión.
- **Contraseñas lógicas:** elegir la secuencia correcta según pistas visuales.
- **Prioridad de tráfico:** activar interruptores en el orden correcto para abrir puentes.
- **Firewall:** bloquear ciertos tipos de paquetes y dejar pasar otros.

## Progresión y mejoras

Al derrotar jefes, el jugador obtiene **núcleos de datos**, que permiten mejorar a Byte:

- Más vida.
- Disparo triple.
- Dash más largo.
- Escudo más resistente.
- Habilidad para marcar enemigos o ralentizar proyectiles.

El jugador avanza al siguiente servidor solo tras vencer al jefe del mundo actual,
creando una progresión clara de dificultad y aprendizaje.

## Frase de venta

> “En una red infectada, cada paquete cuenta: dispara, resuelve, esquiva y restaura la conexión.”

## Versión corta para presentación

**Packet Quest: La Red Rota** es un juego 2D de acción y puzles donde encarnas a
Byte, un paquete de datos que debe salvar Internet de un virus llamado Malwarex.

Recorrerás servidores, eliminarás malware, resolverás puzles de redes y enfrentarás
jefes como el Router Furioso o el Firewall Corrupto. Cada nivel combina plataformas,
disparos y desafíos de lógica; al vencer a cada jefe, reparas una parte de la red y
desbloqueas el siguiente mundo.

# Herramientas de desarrollo recomendadas

## Motor principal: Godot

**Recomendación principal:** usar **Godot 4**.

Godot es gratuito, de código abierto bajo licencia MIT y cuenta con un sistema 2D
dedicado: renderizado, física, tilemaps, animación de sprites, partículas,
iluminación y shaders. Es ideal para un juego de plataformas, disparos, puzles y
jefes.

## Por qué Godot encaja

- **Pipeline 2D nativo:** permite trabajar directamente con píxeles y coordenadas de pantalla.
- **Herramientas listas para el juego:** TileMap para niveles, AnimatedSprite2D para personajes y enemigos, física 2D para colisiones y partículas para efectos.
- **GDScript es fácil de aprender:** su sintaxis se parece a Python y sirve para programar movimiento, disparos, patrones de jefes y puzles.
- **Sin coste ni regalías:** es conveniente para proyectos escolares, personales o indie.
- **Exportación flexible:** permite apuntar a PC y, más adelante, explorar web o móvil.

## Alternativas de motor

| Motor | Recomendación para este juego | Motivo |
|---|---|---|
| **Godot** | Mejor opción general | 2D dedicado, gratuito, ligero, GDScript accesible y suficiente para jefes, puzles y niveles. |
| **GameMaker** | Buena si se quiere aprender rápido | Muy enfocado en 2D, con editor de rooms y sprites intuitivo; usa GML o herramientas visuales. |
| **Unity** | Buena si ya se sabe C# o se planea hacer 3D después | Popular y con mucho material, pero su 2D no es tan directo como el de Godot para un proyecto puramente 2D. |
| **Unreal Engine** | No recomendada para este proyecto | Es potente, pero está más orientada a 3D y sería excesiva para un juego 2D de este estilo. |

## Herramientas recomendadas

- **Motor:** Godot 4.
- **Lenguaje:** GDScript.
- **Arte y animación:** Aseprite, para crear sprites y animaciones en pixel art.
- **Edición de audio:** Audacity.
- **Efectos de sonido y música:** bibliotecas gratuitas como Freesound.
- **Diseño de niveles:** prototipar primero un nivel corto antes de crear mundos completos.
- **Organización del proyecto:** crear escenas separadas para `Player`, `Enemy`, `Bullet`, `Puzzle`, `Level` y `Boss`.

## Primer prototipo recomendado

Crear primero un nivel de aproximadamente 2 minutos que incluya:

1. Movimiento, salto y dash de Byte.
2. Disparo de paquetes.
3. Dos enemigos: un pop-up y un gusano de red.
4. Un puzle simple: conectar tres nodos para abrir una puerta.
5. Un mini-jefe con dos ataques: proyectiles en círculo y una estampida por el suelo.

Si ese prototipo resulta divertido, se puede ampliar con más jefes, mejoras, mapas,
efectos y mundos sin cambiar de motor.