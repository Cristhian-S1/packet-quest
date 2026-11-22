## Hallazgos
No he encontrado errores **Critical**. Las 5 comprobaciones del "Review Focus" están correctamente implementadas y cubiertas por tests (`test_buy_exact_and_insufficient`, `test_player_falls_back_to_packet`, `test_cannot_unequip_last_weapon`, `test_steer_without_target`, `test_swap_with_single_weapon`), y los datos de las `.tres` coinciden con la spec (costes, tipos de `Kind`, stats de armas, orden del catálogo).
### Important
1. **`player.gd:160` — El Ralentizador expira durante la pausa y el hit-stop**
   `get_tree().create_timer(3.0, true, false, true)` usa `process_always=true` e `ignore_time_scale=true`, es decir, cuenta en tiempo real. Escenario: el jugador queda a 1 PV (se activa el 50 % de velocidad) y pausa (Esc) o sufre el *hit-stop* de 0,05 s; la ventana de 3 s se agota sin que el juego avance, malgastando la pasiva que solo se puede usar una vez por nivel. Corrección: crear el temporizador con `process_always=false` (o `get_tree().create_timer(3.0)` a secas) y restaurar `enemy_time_scale` en `_process` cuando el nivel no esté pausado, de modo que la duración sea en tiempo de juego.
2. **`progression.gd:872, 907, 922` — Acceso inseguro e inconsistente al Dictionary de guardado**
   `buy()`, `set_passive()` y `_set_weapons()` hacen `data["owned_upgrades"] as Array` y `data["equipped"] as Dictionary` sin comprobar que existan, mientras que `equipped_weapons()` sí usa `data.get("equipped", {})`. Escenario: `Progression` se presenta como módulo "puro" sobre el Dictionary; un guardado editado a mano al que se llame `buy`/`set_passive` directamente (sin pasar por la validación de `SaveManager`) rompe con error de script en lugar de degradar con gracia. Corrección: unificar con `data.get("owned_upgrades", [])`/`data.get("equipped", {})` y reasignar.
### Minor
3. **`enemy_base.gd:22` + `:87-90` — Enemigos muertos siguen en el grupo `homing_target`**
   `_die()` pone `collision_layer = 0` pero no quita el grupo ni oculta el nodo durante los 0,3 s hasta `queue_free()`. Escenario: un Ping disparado justo cuando muere un enemigo curvará hacia el cadáver, lo atravesará (capa 0) y seguirá recto, desperdiciando el teledirigido. Corrección: `remove_from_group("homing_target")` en `_die()`.
4. **`network_map.gd:529` — Condición redundante y frágil**
   `"PRÓXIMAMENTE" if float(index + 1) in unlocked or (index + 1) in unlocked else "BLOQUEADO"` duplica la misma comprobación mezclando `float` e `int`. Funciona porque GDScript trata `2.0 == 2`, pero es confuso y propenso a error si el tipo de `unlocked_worlds` cambia. Corrección: `(index + 1) in unlocked`.
5. **`player.gd:318` — Sonido de disparo fijo en `&"packet"`**
   Ráfaga triple y Ping reproducen el sonido del Paquete. No se especificaron SFX por arma en la spec, así que es un detalle de *game feel*: corregir a un sonido por arma o dejarlo como decisión explícita.
6. **`workshop.gd:1038-1043` + `progression.gd:874-876` — Comprar una pasiva requiere dos clics**
   `buy()` auto-equipa las armas pero no las pasivas; tras comprar Marcador/Ralentizador/Firewall reforzado, la fila cambia de "Comprar" a "Equipar" y exige un segundo clic. Es coherente con el plan (Task 2 solo especifica auto-equipado de armas), pero inconsistente para el usuario. Corrección (opcional): auto-equipar la pasiva al comprarla si la ranura está vacía.
7. **`workshop.gd:1029-1030` — Estado "Equipar" no refleja ranuras llenas**
   Con 2 armas ya equipadas, una tercera arma poseída muestra "Equipar", pero `toggle_weapon` devuelve `false` sin efecto ni aviso, dejando al jugador sin saber por qué no pasa nada. Corrección: mostrar un estado distinto ("Ranuras llenas") o deshabilitar la fila.
8. **`catalog.gd:435-436` — `upgrades()` devuelve el array `const` por referencia**
   Cualquier llamador puede mutar el catálogo compartido. Para un módulo de solo lectura, devolver una copia (`UPGRADES.duplicate()`) o documentar la referencia es más seguro.
9. **`player.gd:136` — `apply_progression` cura al jugador (`health.reset()`)**
   Solo es correcto porque se llama una única vez en `_ready`; es una mina latente: si en el futuro se llama a mitad de nivel (p. ej. al equipar en caliente), curaría al jugador. Ya está anotado como ruling en `progress.md`; lo dejo registrado para que no se pierda la restricción.
## Consideraciones descartadas (fuera de plan/spec)
- Sonidos distintos por arma: la spec no define audio por arma → descartado (ver #5).
- Auto-equipado de pasivas al comprar: la spec solo exige auto-equipado de armas → descartado (ver #6).
- `apply_progression` curando la vida: documentado como ruling del implementador y no alcanzable en el flujo actual → no es bug vigente (ver #9).
Veredicto: listo para merge sí
