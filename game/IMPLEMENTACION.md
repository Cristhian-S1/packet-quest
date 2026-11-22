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
