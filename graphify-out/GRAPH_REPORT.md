# Graph Report - videogame  (2026-11-22)

## Corpus Check
- Corpus is ~16,108 words - fits in a single context window. You may not need a graph.

## Summary
- 245 nodes · 297 edges · 57 communities (14 shown, 43 thin omitted)
- Extraction: 89% EXTRACTED · 10% INFERRED · 1% AMBIGUOUS · INFERRED: 30 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Núcleo de juego (escenas y autoloads)
- Diseño del juego (mundos y enemigos)
- Documentación del proyecto
- Armas, mejoras y datos
- Combate y daño
- Taller de mejoras y progresión
- Pruebas (tests)
- Estado de juego y guardado
- Mundo 3 · Firewall
- Compra de mejoras (Progression)
- Mundo 4 · Servidor
- Mundo 5 · Nube
- Disparo de proyectiles
- Armas equipadas
- Nivel 1-1
- Arma Ping
- Arma Ráfaga triple
- EnemyBullet
- Audio del jefe
- Preview suite
- Integration suite
- AudioManager (autoload)
- Events (autoload)
- Audacity
- Freesound
- graphify
- AudioManager (autoload singleton)
- Events (autoload singleton)
- GameState (autoload singleton)
- Main scene (Main.tscn)
- SaveManager (autoload singleton)
- BossPhaseData: Sobrecarga
- BossPhaseData: Señal estable
- UpgradeData: Dash extendido
- UpgradeData: Marcador
- UpgradeData: Más vida
- UpgradeData: Ralentizador
- UpgradeData: Firewall reforzado
- WeaponData: Paquete
- World1Level1
- Checkpoint
- DataCore
- Door
- NetworkNode
- Player
- PuzzleNode
- RoutePuzzle
- HUD
- Events.player_died signal
- Events.puzzle_solved signal
- SaveManager.defaults
- RouterBoss._spawn_core
- LevelData
- integration_suite.run
- preview_suite.capture
- test_runner.run_all

## God Nodes (most connected - your core abstractions)
1. `PQStyle` - 23 edges
2. `PacketPlayer` - 21 edges
3. `GameState (autoload)` - 18 edges
4. `01 · Documento de diseño (GDD)` - 14 edges
5. `RouterBoss` - 13 edges
6. `02 · Plan de desarrollo` - 11 edges
7. `11 · Investigación` - 11 edges
8. `RoutePuzzle` - 11 edges
9. `World1Level1` - 10 edges
10. `Prompt: codex-astra-m0-m6` - 9 edges

## Surprising Connections (you probably didn't know these)
- `Player.tscn` --implements--> `Byte (protagonista)`  [INFERRED]
  docs/07-modelos.md → contexto.md
- `00 · Evaluación de contexto` --references--> `contexto.md (pitch de Packet Quest)`  [EXTRACTED]
  docs/00-evaluacion-contexto.md → contexto.md
- `IMPLEMENTACION.md (M0–M6)` --references--> `02 · Plan de desarrollo`  [EXTRACTED]
  game/IMPLEMENTACION.md → docs/02-plan-desarrollo.md
- `README.md (prototipo jugable)` --references--> `07 · Modelos`  [EXTRACTED]
  game/README.md → docs/07-modelos.md
- `opencode` --references--> `IMPLEMENTACION.md (M0–M6)`  [INFERRED]
  docs/12-herramientas.md → game/IMPLEMENTACION.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Bucle de juego principal** — docs_superpowers_plans_2026_11_22_m7_taller_mejoras_network_map, docs_04_niveles_nivel_1_1, docs_06_puzles_ruta_de_paquetes, docs_05_enemigos_y_jefes_router_furioso, docs_03_mecanicas_nucleos_de_datos, docs_03_mecanicas_taller_de_mejoras [EXTRACTED 1.00]
- **Autoloads (singletons)** — docs_08_arquitectura_tecnica_events, docs_08_arquitectura_tecnica_game_state, docs_08_arquitectura_tecnica_save_manager, docs_08_arquitectura_tecnica_audio_manager [EXTRACTED 1.00]
- **Enemigos comunes** — docs_05_enemigos_y_jefes_popup, docs_05_enemigos_y_jefes_gusano_de_red, docs_05_enemigos_y_jefes_spyware, docs_05_enemigos_y_jefes_troyano, docs_05_enemigos_y_jefes_bot_ddos [EXTRACTED 1.00]
- **Autoload event bus (Events signal emitters)** — game_scripts_autoload_events_events, game_scripts_autoload_game_state_game_state, game_scripts_bosses_router_boss_router_boss, game_scripts_enemies_enemy_base_enemy_base [INFERRED 0.75]
- **Combat component system (health/hit/hurt/projectile)** — game_scripts_components_health_component_health_component, game_scripts_components_hitbox_hitbox, game_scripts_components_hurtbox_hurtbox, game_scripts_components_projectile_pool_projectile_pool [INFERRED 0.75]
- **Data-driven Resource catalog (weapon/upgrade/phase/level)** — game_scripts_data_catalog_catalog, game_scripts_data_weapon_data_weapon_data, game_scripts_data_upgrade_data_upgrade_data, game_scripts_data_boss_phase_data_boss_phase_data, game_scripts_data_level_data_level_data [INFERRED 0.75]
- **Interactable group interaction (E prompt) pattern** — game_scripts_player_player_packetplayer, game_scripts_objects_network_node_networknode, game_scripts_puzzles_puzzle_node_puzzlenode [EXTRACTED 1.00]
- **PacketScreen UI screen subclasses** — game_scripts_ui_screen_base_packetscreen, game_scripts_ui_death_screen_death_screen, game_scripts_ui_pause_menu_pause_menu, game_scripts_ui_victory_screen_victory_screen, game_scripts_ui_workshop_workshop [EXTRACTED 1.00]
- **StageBuilder scene factory consumers** — game_scripts_levels_stage_builder_stagebuilder, game_scripts_levels_world1_level1_world1level1, game_scripts_main_main_main, game_scripts_main_network_map_network_map [EXTRACTED 1.00]
- **Passive upgrade resources (kind=1)** — game_resources_upgrades_marker, game_resources_upgrades_slowdown, game_resources_upgrades_strong_firewall [INFERRED 0.75]
- **WeaponData resource definitions** — game_resources_weapons_packet, game_resources_weapons_ping, game_resources_weapons_triple [EXTRACTED 1.00]
- **Weapon-unlock upgrades mapped to weapon resources** — game_resources_upgrades_ping, game_resources_weapons_ping, game_resources_upgrades_triple, game_resources_weapons_triple [INFERRED 0.75]

## Communities (57 total, 43 thin omitted)

### Community 0 - "Núcleo de juego (escenas y autoloads)"
Cohesion: 0.07
Nodes (57): RouterBoss, NetworkWorm, PopUp, Main, NetworkMap, PlayerBullet, DeathScreen, PauseMenu (+49 more)

### Community 1 - "Diseño del juego (mundos y enemigos)"
Cohesion: 0.07
Nodes (32): Byte (protagonista), La Gran Red (mundo), Malwarex (virus / jefe final), Packet Quest: La Red Rota, Dash (Modo seguro), Dash extendido, Habilidad de red (Nodo de red), Movimiento de Byte (+24 more)

### Community 2 - "Documentación del proyecto"
Cohesion: 0.14
Nodes (29): contexto.md (pitch de Packet Quest), 00 · Evaluación de contexto, 01 · Documento de diseño (GDD), 02 · Plan de desarrollo, 03 · Mecánicas, 04 · Niveles, 05 · Enemigos y jefes, 06 · Puzles (+21 more)

### Community 3 - "Armas, mejoras y datos"
Cohesion: 0.11
Nodes (21): Disparo de datos, Marcador, Más vida, Modo asistido (accesibilidad), Núcleos de datos, Paquete (arma base), Ping (arma teledirigida), Ráfaga triple (+13 more)

### Community 4 - "Combate y daño"
Cohesion: 0.22
Nodes (9): Events.boss_defeated signal, Events.impact signal, RouterBoss._defeat, RouterBoss.take_damage, HealthComponent.damage, HealthComponent.depleted signal, Hurtbox.hit signal, EnemyBase._die (+1 more)

### Community 5 - "Taller de mejoras y progresión"
Cohesion: 0.32
Nodes (8): Workshop, AudioManager (autoload), SaveManager (autoload), Catalog, UpgradeData, WeaponData, Progression, Workshop

### Community 6 - "Pruebas (tests)"
Cohesion: 0.29
Nodes (8): test_boss_phases, test_health_component, test_progression, test_route_puzzle, test_runner, test_save_manager, test_scenes_load, test_weapons

### Community 7 - "Estado de juego y guardado"
Cohesion: 0.29
Nodes (7): Events.core_collected signal, GameState.collect_core, GameState.record_death, GameState.save, GameState.win, SaveManager.save_game, RouterBoss._finish

### Community 8 - "Mundo 3 · Firewall"
Cohesion: 0.40
Nodes (5): Escudo de firewall, Firewall reforzado, Mundo 3 · Firewall, Firewall Corrupto, Firewall (puzle)

### Community 9 - "Compra de mejoras (Progression)"
Cohesion: 0.40
Nodes (5): Catalog.upgrade, Progression.buy, Progression.can_buy, Progression.has_effect, Progression.set_passive

### Community 10 - "Mundo 4 · Servidor"
Cohesion: 0.50
Nodes (4): Mundo 4 · Servidor, Troyano, Troyano Real, Contraseñas lógicas (puzle)

### Community 11 - "Mundo 5 · Nube"
Cohesion: 0.50
Nodes (4): Mundo 5 · Nube, Bot DDoS, Botnet Nimbus, Prioridad de tráfico (puzle)

### Community 12 - "Disparo de proyectiles"
Cohesion: 1.00
Nodes (3): ProjectilePool.fire, EnemyBase.fire, NetworkWorm.fire

### Community 13 - "Armas equipadas"
Cohesion: 0.67
Nodes (3): Catalog.weapon, Progression.equipped_weapons, Progression.toggle_weapon

## Ambiguous Edges - Review These
- `Modo asistido (accesibilidad)` → `Ralentizador`  [AMBIGUOUS]
  docs/03-mecanicas.md · relation: conceptually_related_to
- `PacketDoor` → `NetworkNode`  [AMBIGUOUS]
  game/scripts/objects/network_node.gd · relation: calls

## Knowledge Gaps
- **134 isolated node(s):** `contexto.md (pitch de Packet Quest)`, `12 · Herramientas, skills y plugins`, `README.md (prototipo jugable)`, `Firewall Corrupto`, `Troyano Real` (+129 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 135 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Byte (protagonista)` connect `Diseño del juego (mundos y enemigos)` to `Mundo 3 · Firewall`, `Armas, mejoras y datos`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `GameState (autoload)` (e.g. with `SaveManager (autoload)` and `Progression`) actually correct?**
  _`GameState (autoload)` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `contexto.md (pitch de Packet Quest)`, `12 · Herramientas, skills y plugins`, `README.md (prototipo jugable)` to the rest of the system?**
  _134 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Núcleo de juego (escenas y autoloads)` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._
- **Why does `PQStyle` connect `Núcleo de juego (escenas y autoloads)` to `Taller de mejoras y progresión`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Modo asistido (accesibilidad)` and `Ralentizador`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `PacketDoor` and `NetworkNode`?**
  _Edge tagged AMBIGUOUS (relation: calls) - confidence is low._