# Packet Quest: plan de implementación M0–M6

Fuente: los doce documentos de `../docs/`, leídos antes de crear código.
Arquitectura: escenas de una raíz y componentes tipados; hijos creados en `_ready`.
Godot 4.7.2, Compatibility, 640×360, escala entera, física 60 Hz; sin assets externos.
El diseño y la ejecución ya están autorizados por la solicitud de implementación.

## Las doce tareas

- [x] 1. M0: proyecto, InputMap completo y ocho capas.
- [x] 2. M0: Events, GameState, SaveManager y AudioManager.
- [x] 3. M1: HealthComponent.damage/heal, Hitbox y Hurtbox; probar límites y señales.
- [x] 4. M1: Byte, estados, movimiento, salto, dash, escudo e interacción.
- [x] 5. M1: pools de 24 balas de jugador y 128 enemigas.
- [x] 6. M2: Pop-up y Gusano; aviso, actividad, recuperación y control de visibilidad.
- [x] 7. M3: nivel de 2720 px, S1–S4, plataformas, checkpoints y núcleo oculto.
- [x] 8. M4: RoutePuzzle.check_solution/reset_puzzle, nodos y Door; probar solución y reinicio.
- [x] 9. M5: RouterBoss, fases y ataques; probar umbral, invulnerabilidad y fin de transición.
- [x] 10. M6: menú, HUD, pausa, muerte, victoria y persistencia.
- [x] 11. Cinco pruebas obligatorias, prueba de integración y cuatro comandos headless limpios.
- [x] 12. README en español con controles, ejecución, estructura y límites verificados.

## Decisiones y revisión

- Las direcciones de puzle son derecha=0, abajo=1, izquierda=2, arriba=3.
- Al cruzar el 50 % en ACTIVE se termina ese ataque; fuera de ACTIVE la transición comienza inmediatamente.
- La arena ocupa una escena independiente de 640×360; el acceso está en x=2720.
- Audio silencioso permitido por la solicitud; fuente incorporada de Godot.
- Valores no especificados: duración de láser 0,45 s; estampida 0,84 s; recuperación base 0,20 s.
- Revisar especialmente: reintento en jefe, núcleo no duplicable, guardado corrupto,
  bala contra escudo por detrás, puzle reiniciable y plataforma móvil con pasajero.
- Pruebas no deben escribir en la partida real: usar `user://test_save.json`.

## Registro

Inicio: no existe proyecto previo ni índice `.codegraph/`. No se modifica documentación fuente.

Se releen los documentos actualizados durante la ejecución: suelo y=304, plataformas de
jefe y=256, contacto enemigo de 1 PV y nivel de 2720 px (el jefe es una escena aparte).
Puerta y transición coinciden en x=2720, con checkpoints en 1760, 2240 y el inicio de la arena.

Revisión independiente: se corrigen flechas físicas, disparo desde el suelo, cadencia,
contacto de jefe, plataformas alcanzables, periodo del anillo, esquema de guardado anidado
y geometría del hueco. Cada defecto reproducido tiene comprobación de regresión.

La integración verifica también coyote/buffer, cable móvil, interacción real del puzle,
cambio de escena, muerte/reintento y recogida del núcleo final hasta victoria guardada.
Las cinco pruebas obligatorias y la integración han pasado antes de la validación final.
No se certifican pruebas con cinco personas ni rendimiento de GPU en hardware objetivo.

Validación final: import, inicio, cinco pruebas y 300 frames: exit=0, sin errores ni advertencias. Integración adicional: PASS, exit=0. Salidas en validation/*.log. Capturas renderizadas y revisadas con Compatibility.

## Decisiones M8

- **Ciclo de onda.** La tabla de pruebas de la especificación fija un ciclo de 3 s. La onda empuja de 0 a 2 s, queda inactiva de 2 a 2,5 s y avisa de 2,5 a 3 s.
- **Cobertura y foso.** S4 tiene un segundo router porque queda fuera del alcance de 160 px del router de S2. El foso letal de 2-1 agota la vida de Byte al caer. Los ataques conservan el daño de 1 PV y Red Local conserva su recuperación al caer.
- **Guardado.** La victoria registra `w<N>_boss`. Para el Router también se conserva `w1_l1`, el identificador que usaban las partidas del Mundo 1. Los mundos desbloqueados sin escenas aparecen en ámbar como PRÓXIMAMENTE.
- **Reparar cables.** La disposición requiere siete giros para la ruta indicada. Las piezas dejan de interceptar disparos al resolver el tablero y el reinicio las reactiva. El sonido de conexión se sintetiza con tres notas.
- **Jefe.** Al cruzar cada umbral se cancela el ataque en curso y se limpia el pool enemigo. La recuperación de Itinerancia sigue al teletransporte. El ping se desplaza lo necesario cerca de las paredes para conservar las cinco marcas separadas 32 px.
- **Interferencia.** El reloj de 4 s es independiente de los proyectiles. El ping y la espiral se alternan al terminar las franjas activas. La espiral puede coincidir con el aviso del ciclo siguiente.
- **Repetidores.** Los seis segundos de recarga empiezan al cerrarse la cúpula. La victoria devuelve al mapa tras mostrar la tarjeta de segmento restaurado durante 0,8 s.

## Decisiones M9

- **Altura de los carriles.** El centro de y = 184 está 72 px por encima del chip de y = 256.
  El hueco mide 64 px y admite el cuerpo de Byte (10 × 14 px) a partir de un salto de 40 px
  desde ese chip. La prueba mide el espacio que necesita todo el colisionador y cruza los tres
  carriles con entradas reales.
- **Puertos.** El puerto central está en y = 176 en F1 y F3. En F2, los puertos alto, medio y
  bajo están en y = 184, 240 y 288. El láser toma la altura de Byte al iniciar el aviso y se
  conecta al puerto abierto sin interrumpir el ciclo de puertos de 1,2 s.
- **Tope de avance.** El muro descarta el avance que excede x = 160. Así, una bala a un ladrillo
  todavía lo empuja 8 px desde ese tope. Si el láser está activo al cruzar un umbral de PV,
  se termina el disparo antes de la pausa invulnerable de 2,4 s.
- **Puzle.** La semilla 0 conserva el orden especificado. Las demás semillas reordenan el mismo
  lote para mantener cuatro paquetes permitidos y seis bloqueados.
- **Victoria y salida.** La compuerta de 3-1 coincide con el umbral de salida en x = 3040. La
  prueba cruza desde el último terminal caminando con `move_right`. El núcleo del jefe se abona
  al vencerlo y la tarjeta precede al regreso al mapa.

## Decisiones M10

- **Cronología del portal.** Los 5 s corresponden al ciclo completo, que incluye el aviso de 1 s. El Troyano patrulla durante la recuperación y conserva el portal en el lugar donde lo abrió. El ciclo sigue fuera de cámara, con tope de cuatro Pop-ups vivos por portal.
- **Anclaje del ascensor.** `ChipPlatform` toma la esquina superior izquierda como origen. En 4-1 se coloca a x = 720 y x = 2120 para que los centros queden en x = 760 y x = 2160. Los bordes superiores mantienen los 280 y 216 px de altura previstos.
- **Cronología del cofre.** La sombra avisa durante 0,6 s y el salto dura otros 0,6 s. Al aterrizar comienza la apertura de 1,5 s y, dentro de ella, el aviso de descarga de 0,6 s. La dirección se fija al iniciar el aviso. Un cambio de fase cancela el ataque y comienza la pausa invulnerable de 2,4 s.
- **Descarga y chips.** El carril de y = 256 coincide con el borde superior de los chips y la consulta de impacto absorbía el disparo al nacer sobre ellos. Las balas de la descarga excluyen esos dos cuerpos de su consulta, con las demás colisiones del pool activas.
- **Invocación y mímicos.** Los minions de F2 duran hasta el cierre del cofre. En F3, el cofre real se distingue durante los primeros 0,4 s del aviso. Los mímicos pueden hacer daño al terminar el aviso de 0,6 s.
- **Revelación y victoria.** Los pósteres muestran las pistas cuando Byte se acerca. El núcleo de S4 aparece por proximidad. La victoria abona el núcleo del jefe y muestra la tarjeta durante 0,8 s antes de volver al mapa.

## Decisiones M11

- **Cinco mundos.** M10 ya limitaba los guardados a cinco mundos y el mapa ya mostraba los cinco nombres. Se conservó esa migración y se registraron las escenas de Centro de datos en la lista de GameState.
- **Estadísticas de núcleos.** El denominador incluye los diez núcleos enumerados en M11. El numerador usa el saldo del guardado, tal como pide la especificación. Firewall Corrupto y Troyano Real ya otorgaban recompensas adicionales en M9 y M10. Se conservaron ambas, de modo que el saldo baja al comprar mejoras y puede llegar a 12 si se recogen todos los núcleos y se guardan ambas recompensas.
- **Sala QoS.** Los interruptores se repartieron en un orden distinto del de urgencia para que los bloques guíen la solución. Los puentes son plataformas de un sentido sobre suelo firme. Al caer, permiten volver a intentar la secuencia sin daño.
- **Arena.** Las ventanas tienen un aviso de 0,6 s. El daño al núcleo se detiene en el siguiente umbral de fase para preservar el puzle incluso con impactos simultáneos. El doble anillo mantiene un ciclo de 2 s con 0,8 s de recuperación y una espera de 0,25 s. El borrado de suelo conserva su propio reloj.
- **Nueva partida.** Inicia 1-1 con progreso y estadísticas nuevos y conserva los ajustes de la partida anterior.
- **Reloj de pruebas.** La suite principal usa un paso fijo de 60 Hz para completar la simulación headless sin depender del tiempo de pared. La suite de integración conserva el reloj del motor.

## Decisiones Opciones

- **Guardado.** Cada cambio válido actualiza `settings` en la partida activa y se escribe mediante SaveManager. Si falla la escritura, el control recupera el valor anterior y muestra un aviso.
- **Audio.** Música y Efectos usan pasos de 10 % y buses independientes. El cero activa el silencio del bus y los valores positivos se convierten a dB. El proyecto aún carece de una pista de música. Los efectos existentes se reproducen por SFX.
- **Accesibilidad.** Desactivar la sacudida limpia el desplazamiento actual de la cámara. Reducir destellos atenúa el parpadeo y conserva las señales de aviso. La asistencia aplica velocidad ×0,8 y un PV adicional. Si se activa durante una partida, añade ese PV sin curar el daño previo.
- **Navegación.** Arriba y abajo recorren los ajustes. Izquierda y derecha cambian el volumen del control enfocado. Volver, Escape o Start cierran la pantalla y devuelven el foco a Opciones. Al regresar al menú de pausa, el nivel sigue pausado.
