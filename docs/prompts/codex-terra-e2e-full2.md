# Continuación — e2e completo (bead pq-moy)

Sigue el encargo de `docs/prompts/codex-terra-e2e-full.md` (léelo: reglas de entrada no negociables). Tu pasada anterior
paró demasiado pronto: el bot muere con la Reina (fase 3, 28/90 PV) y no se hizo nada de los mundos 3–5. Está en el commit
WIP de esta rama. **No pares hasta `PASS e2e` hasta créditos o hasta probar un bug real del juego.**

## Cómo hacer que el bot sobreviva (estrategia, no trampas)
- Esquiva reactiva: cada frame, el bot lee las balas/hitboxes enemigas activas (grupo o nodos del jefe) y predice
  colisión con el hurtbox de Byte (10×14) en los próximos 6–12 frames con su velocidad. Si va a chocar: dash
  (0,15 s de invulnerabilidad, 72 px) hacia el lado libre o salto, según la geometría. El dash tiene enfriamiento: léelo.
- Ataques con telegrafía (`state == TELEGRAPH`, `attack`): elige posición segura ANTES de que se active
  (ondas: `wave_lanes(index)` dice qué carriles golpean; ping/espiral/teletransporte: ver el script del jefe).
- Dispara solo cuando es seguro; prioriza sobrevivir a hacer daño. Los jefes tienen pausa invulnerable de 2,4 s al cambiar
  de fase: no gastes ese tiempo.
- Haz un banco de pruebas por jefe: escena del jefe sola con N semillas/ejecuciones; registra % de victorias y dónde muere.
  Itera hasta que cada jefe se gane en ≥ 9/10 ejecuciones antes de encadenar el recorrido completo.
- Si tras un análisis serio un patrón concreto no deja hueco (calcula: posiciones, tiempos y tamaño de hurtbox), eso
  es un bug del juego: documéntalo con números en el informe y para ahí.
- `assist_mode` solo como último recurso y anotado; el objetivo es ganar sin él.

## Además
- `tools/run-e2e.sh` debe funcionar en un checkout limpio: añade la reimportación (`--import` o la misma que usa
  `run-tests.sh`) antes de ejecutar.
- Commits por jefe/mundo conforme pasen. Actualiza `logs/codex-terra-e2e-full.md`.
- UN Godot propio a la vez; los de otros agentes no cuentan y no se cierran. Sin `bd`, sin push.
