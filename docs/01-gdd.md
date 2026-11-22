# 01 · Documento de diseño (GDD) — Packet Quest: La Red Rota

## Ficha

| Campo | Valor |
|---|---|
| Género | Shooter 2D de plataformas (*run and gun*) con jefes por fases y puzles ligeros |
| Plataforma | PC (Windows/Linux); Web (HTML5) como objetivo secundario |
| Motor | Godot 4.7.2 · GDScript |
| Jugadores | 1 |
| Duración objetivo | 1,5–2 h el juego completo; 12–20 min por mundo |
| Público | 12+ años; jugadores de acción 2D; uso educativo en clases de redes |
| Resolución lógica | 640×360, escalado entero |

## Frase de venta

> "En una red infectada, cada paquete cuenta: dispara, resuelve, esquiva y restaura la conexión."

## Historia

El virus **Malwarex** ha infectado la Gran Red: corrompió routers, secuestró servidores y
bloqueó Internet. **Byte**, un pequeño paquete de datos con guantes, patas de circuito y un
cañón de energía, es el único paquete que sigue íntegro. Su misión es viajar de la red local
al centro de datos, limpiar cada segmento y restaurar el flujo de datos.

Tono: humor ligero y techno (los enemigos hablan como mensajes de error), sin violencia gráfica.

## Pilares de diseño

1. **Legible antes que difícil.** Todos los ataques tienen aviso; morir siempre se siente culpa del jugador.
2. **La red es el mundo.** Cada elemento del nivel representa un concepto de redes real.
3. **Reintento instantáneo.** Volver a intentarlo cuesta menos de un segundo.
4. **Aprender patrones.** Los jefes se dominan con práctica, no con estadísticas.

## Bucle de juego

```
Mapa de la red ─► Nivel run & gun ─► Zona de puzle ─► Jefe por fases
      ▲                                                     │
      └──────── Taller de Mejoras ◄── Núcleo de datos ◄─────┘
```

- **Micro (segundos):** moverse, saltar, disparar, esquivar avisos.
- **Medio (minutos):** superar una sección, resolver un puzle, aprender una fase del jefe.
- **Macro (horas):** reparar los 6 segmentos de la red y mejorar a Byte.

## Proporción de gameplay

| Elemento | Peso | Dónde se documenta |
|---|---:|---|
| Shooter / combate | 45 % | `03-mecanicas.md`, `05-enemigos-y-jefes.md` |
| Plataformas | 25 % | `03-mecanicas.md`, `04-niveles.md` |
| Jefes | 20 % | `05-enemigos-y-jefes.md` |
| Puzles | 10 % | `06-puzles.md` |

## Mundos (resumen)

| # | Mundo | Jefe | Concepto de red |
|---|---|---|---|
| 1 | Red Local | Router Furioso | Switches, cables Ethernet, direcciones |
| 2 | Wi-Fi | Reina Wi-Fi | Ondas, interferencia, repetidores |
| 3 | Firewall | Firewall Corrupto | Reglas de filtrado, puertos |
| 4 | Servidor | Troyano Real | Procesos, permisos, puertas traseras |
| 5 | Nube | Botnet Nimbus | Tráfico masivo (DDoS), balanceo de carga |
| 6 | Centro de datos | Malwarex | Todo lo anterior combinado |

Detalle en `04-niveles.md`.

## Índice de documentos

| Doc | Contenido |
|---|---|
| `00-evaluacion-contexto.md` | Evaluación del documento original y decisiones |
| `01-gdd.md` | Este documento |
| `02-plan-desarrollo.md` | Hitos, tareas y criterios de aceptación |
| `03-mecanicas.md` | Controles, movimiento, combate, valores numéricos |
| `04-niveles.md` | Mundos, estructura y diseño del nivel prototipo |
| `05-enemigos-y-jefes.md` | Fichas de enemigos y jefes con patrones y fases |
| `06-puzles.md` | Tipos de puzle, reglas y ejemplos |
| `07-modelos.md` | Modelos de datos, escenas, señales y modelos visuales |
| `08-arquitectura-tecnica.md` | Estructura del proyecto Godot, autoloads y capas |
| `09-arte-y-audio.md` | Dirección de arte, paleta y audio |
| `10-qa-y-pruebas.md` | Plan de pruebas y métricas |
| `11-investigacion.md` | Fuentes consultadas |
| `12-herramientas.md` | Herramientas de arte/audio, MCP, skills y plugins recomendados (¿hace falta Blender?) |
| `13-m8-mundo-wifi.md` | Especificación de implementación del Mundo 2 Wi-Fi (M8) |
| `superpowers/plans/` | Planes de implementación por hito (M7 en adelante) |
