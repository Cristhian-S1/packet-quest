# 00 · Evaluación de `contexto.md`

Documento evaluado: `contexto.md` (Packet Quest: La Red Rota).
Fecha: 2026-11-22.

## Veredicto

El concepto es sólido y viable para un proyecto escolar o indie pequeño. La temática
(redes informáticas) se traduce bien en mecánicas: los cables sirven de plataformas, los
paquetes de proyectiles, el firewall de escudo y el enrutado de puzle. La elección de
Godot 4 es correcta para un juego 2D de este alcance, y el primer prototipo que propone el
documento tiene un tamaño adecuado.

**Nota global: 7,5 / 10.** El documento sirve como *pitch*, pero todavía no funciona como
documento de diseño: faltan números, controles, reglas de daño y una correspondencia clara
entre mundos y jefes.

## Puntos fuertes

| Aspecto | Por qué funciona |
|---|---|
| Fantasía clara | "Eres un paquete de datos que repara Internet" se entiende en una frase. |
| Temática y mecánica alineadas | Cada concepto de red tiene una traducción jugable (DDoS = muchas balas lentas, troyano = puerta que trae enemigos). |
| Estructura de mundo en 3 partes | Combate → puzle → jefe da ritmo y descanso entre picos de tensión. |
| Proporción de gameplay explícita | 45/25/20/10 ayuda a priorizar el trabajo. |
| Prototipo acotado | Un nivel de ~2 min con 2 enemigos, 1 puzle y 1 mini-jefe permite validar la diversión pronto. |
| Motor adecuado | Godot 4: 2D nativo, gratuito, GDScript accesible. |
| Valor educativo | Los puzles enseñan conceptos de red sin exigir saber programar. |

## Problemas detectados y decisiones tomadas

| # | Problema | Impacto | Decisión (aplicada en los demás docs) |
|---|---|---|---|
| 1 | Hay **6 zonas** (Red local, Wi-Fi, Servidor, Nube, Firewall, Centro de datos) pero solo **5 jefes**, y no se dice qué jefe va en cada zona. | Alto | 6 mundos con un jefe cada uno. Se añade **Botnet Nimbus** (jefe DDoS de la Nube). Orden lógico de red: LAN → Wi-Fi → Firewall → Servidor → Nube → Centro de datos. Ver `04-niveles.md`. |
| 2 | Escudo y dash se solapan: ambos evitan daño. | Medio | El dash da i-frames cortos con enfriamiento; el escudo bloquea solo por delante, consume un medidor y no permite disparar mientras está activo. Ver `03-mecanicas.md`. |
| 3 | La "habilidad de red" no tiene botón, alcance ni reglas. | Medio | Botón `interact` cerca de un **Nodo de red**, que activa sus `targets` (puertas, plataformas, rutas). |
| 4 | No hay sistema de vida definido. | Alto | 3 puntos de vida (4 con mejora), invulnerabilidad de 1,0 s tras recibir un golpe y muerte que reinicia en el último checkpoint. |
| 5 | Faltan controles. | Alto | Mapa de entrada completo para teclado y mando en `03-mecanicas.md`. |
| 6 | Los Spywares disfrazados de objetos pueden parecer injustos. | Bajo | Siempre tienen un aviso visual (parpadeo y glitch de 0,4 s) antes de atacar. |
| 7 | La progresión ("disparo triple", etc.) no tiene coste ni reglas. | Medio | Los **núcleos de datos** son la moneda del Taller de Mejoras; las mejoras se equipan por ranuras. Ver `03-mecanicas.md`. |
| 8 | No se especifica resolución ni escala del pixel art. | Medio | 640×360 lógico, escalado entero, filtro *nearest*. Ver `09-arte-y-audio.md`. |
| 9 | Falta la experiencia de reintento (clave en un juego de jefes). | Medio | Reinicio rápido (< 1 s) y pantalla de muerte con barra de progreso del jefe. |
| 10 | La inspiración en *Cuphead* conlleva riesgo de copia visual. | Legal / identidad | Se toma solo la **estructura** (run and gun + jefes por fases). La estética es propia: neón retro-techno, sin estilo de dibujos de los años 30. |
| 11 | No hay calendario ni criterios de "terminado". | Medio | Hitos M0–M6 con criterios de aceptación en `02-plan-desarrollo.md`. |
| 12 | Accesibilidad no mencionada. | Bajo | Opciones de reducir parpadeo, sacudida de cámara y velocidad de juego (modo asistido). |

## Nota de decisión (director)

> El encargo exige exactamente **5 niveles = 5 mundos**, uno por cada jefe del documento
> original `contexto.md`. Se **revoca** la decisión del problema 1: se vuelve a los
> **5 jefes originales** (Router Furioso, Reina Wi-Fi, Firewall Corrupto, Troyano Real y
> Malwarex). Se **elimina** el mundo Nube y su jefe **Botnet Nimbus**; sus elementos — el
> enemigo Bot DDoS, las plataformas de nube que se desvanecen y el puzle "Prioridad de
> tráfico" (QoS) — pasan al **Mundo 5 · Centro de datos**. Ver `04-niveles.md` y
> `05-enemigos-y-jefes.md`.

## Riesgos

1. **Alcance:** 5 mundos × (nivel + puzle + jefe) es mucho trabajo para un equipo pequeño. Conviene cerrar primero un mundo vertical completo.
2. **Arte:** sin artista, el juego puede verse genérico. El prototipo usa gráficos dibujados por código (formas y neón) para no bloquear el desarrollo.
3. **Dificultad:** los jefes por fases necesitan pruebas con jugadores reales. Se registrarán muertes por ataque (ver `10-qa-y-pruebas.md`).

## Revisión independiente (opencode · DeepSeek V4 Pro)

Una segunda revisión de los documentos encontró 15 incoherencias, ya corregidas: daño
recibido sin definir (ahora 1 PV por golpe), plataformas del jefe fuera del alcance del salto
(ahora a 48 px), hueco de 96 px imposible con el dash base (ahora requiere salto + dash),
suelo fuera de la rejilla (ahora y = 304), checkpoints contradictorios, umbrales de Malwarex
(75/50/25 %), arma Ping más débil que la base (daño 1,3), duración total incoherente,
tipos de mejora mal etiquetados y otros detalles menores. Informe completo en
`logs/opencode-doc-review.md`.

## Recomendación

Seguir con el plan del documento original, añadiendo las decisiones de arriba. Construir el
**prototipo del Mundo 1 (Red Local + Router Furioso)** como primera entrega jugable con Codex
(GPT-6 Astra) y validarlo antes de ampliar.
