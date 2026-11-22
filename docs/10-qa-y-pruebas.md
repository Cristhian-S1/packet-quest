# 10 · QA y pruebas

## Pruebas automáticas (headless)

```bash
godot --headless --path game -s res://tests/test_runner.gd
```

| Prueba | Qué verifica |
|---|---|
| `test_health_component` | Daño, curación, límites y señal `depleted` |
| `test_route_puzzle` | La solución correcta emite `solved` y una incorrecta no |
| `test_boss_phases` | Con PV ≤ 50 % se pasa a la fase 2; durante la transición el jefe es invulnerable |
| `test_save_manager` | Guardar → cargar da los mismos datos; un archivo corrupto devuelve los valores por defecto |
| `test_scenes_load` | Todas las escenas `.tscn` se instancian sin errores |

Además: `godot --headless --path game --quit` no debe mostrar errores de parseo.

## Checklist manual del prototipo

- [ ] Byte se mueve, salta (salto corto y largo), hace dash en el suelo y en el aire.
- [ ] El coyote time y el jump buffer se notan (saltar justo al salir del borde funciona).
- [ ] El disparo funciona en 8 direcciones con `lock_aim`.
- [ ] El escudo bloquea balas frontales y consume el medidor.
- [ ] Pop-up y Gusano reciben daño, mueren y muestran su aviso antes de atacar.
- [ ] El checkpoint reaparece correctamente tras morir.
- [ ] El puzle de 3 nodos se resuelve y abre la puerta.
- [ ] El Router Furioso cambia de fase al 50 % con pausa y tarjeta.
- [ ] La pantalla de muerte muestra la barra de progreso del jefe.
- [ ] Al vencer al jefe se obtiene un núcleo de datos y se guarda la partida.
- [ ] No hay caída de FPS por debajo de 60 con 100 balas en pantalla.

## Playtest

- 5 jugadores como mínimo, sin instrucciones verbales.
- Métricas: tiempo hasta terminar el nivel, muertes por sección y por ataque del jefe, y si
  el jugador entendió el puzle sin pista.
- Preguntas: ¿qué ataque te pareció injusto? ¿Qué fue lo más divertido? ¿Entendiste la "red"?
- Criterio de éxito del prototipo: ≥ 4 de 5 jugadores quieren repetir el jefe tras morir.
