M8 quedó implementado en `feat/m8-wifi`. La prueba de recorrido verificó la selección de Wi-Fi en el mapa, el cruce del foso, el reintento desde el checkpoint, la apertura de la compuerta con siete disparos y el regreso al mapa con Firewall desbloqueado como **PRÓXIMAMENTE**.

## Última ejecución de pruebas

`bash tools/run-tests.sh --integration` terminó con código 0.

```text
PASS test_health_component
PASS test_route_puzzle
PASS test_boss_phases
PASS test_save_manager
PASS test_scenes_load
PASS test_progression
PASS test_weapons
PASS test_world2
RESULTADO: 8/8 PASS
PASS integration: física, controles, escudo, vacío, pools, puzle, enemigos, ataques y persistencia
```

El nivel 2-1 y la arena completaron **300 frames headless cada uno** sin errores. Godot MCP ejecutó ambas escenas y solo mostró advertencias preexistentes de GDScript. Capturas: [level2.png](C:/Users/alumnos.LAPTOP-LGABPBVS/Downloads/videogame-wt/m8/docs/capturas/level2.png) y [boss2.png](C:/Users/alumnos.LAPTOP-LGABPBVS/Downloads/videogame-wt/m8/docs/capturas/boss2.png).

## Decisiones

- El ciclo de onda sigue los tiempos de la prueba obligatoria: 2 s de empuje, 0,5 s de inactividad y 0,5 s de aviso.
- S4 usa un segundo router para respetar el alcance de 160 px. El foso de 2-1 es letal.
- La victoria del Router conserva `w1_l1` y añade `w1_boss` para mantener la compatibilidad con partidas anteriores.
- La Reina limpia el pool al cruzar cada umbral. La interferencia conserva su ciclo de 4 s y la recarga del repetidor comienza cuando se cierra la cúpula.

El detalle está en [Decisiones M8](C:/Users/alumnos.LAPTOP-LGABPBVS/Downloads/videogame-wt/m8/game/IMPLEMENTACION.md).

## Commits locales

```text
e59d4e0 feat(m8): guardar la progresión por mundo
4b967d0 feat(m8): añadir ondas y plataformas de cobertura
0a6d787 feat(m8): incorporar al enemigo Spyware
17dafaf feat(m8): implementar el puzle Reparar cables
6ff673a feat(m8): construir la arena y las fases de la Reina Wi-Fi
4d3c93f feat(m8): conectar Zona de cobertura con el mapa y la Reina
287ffea feat(m8): pulir avisos visuales y estados del mapa
55ed1ac test(m8): verificar la travesía y el rebote de ondas
09aa4e7 feat(m8): documentar el mundo Wi-Fi y generar sus capturas
```

**Pendientes del hito:** ninguno.