[0m
> build · deepseek-v4-pro
[0m✱ [0mGlob "**/*.md" [90m16 matches[0m
> build · deepseek-v4-pro
[0m→ [0mRead contexto.md 
[0m→ [0mRead docs/00-evaluacion-contexto.md 
[0m→ [0mRead docs/02-plan-desarrollo.md 
[0m→ [0mRead docs/01-gdd.md 
> build · deepseek-v4-pro
[0m→ [0mRead docs/03-mecanicas.md 
[0m→ [0mRead docs/05-enemigos-y-jefes.md 
[0m→ [0mRead docs/04-niveles.md 
[0m→ [0mRead docs/06-puzles.md 
> build · deepseek-v4-pro
[0m→ [0mRead docs/07-modelos.md 
[0m→ [0mRead docs/08-arquitectura-tecnica.md 
[0m→ [0mRead docs/09-arte-y-audio.md 
[0m→ [0mRead docs/11-investigacion.md 
[0m→ [0mRead docs/10-qa-y-pruebas.md 
> build · deepseek-v4-pro
1. **Falta todo valor de daño en el combate.** `docs/05-enemigos-y-jefes.md` no asigna daño ni a los proyectiles/contacto de los enemigos comunes (Pop-up, Gusano, Spyware, Troyano, Bot DDoS) ni a los ataques de los jefes; `docs/03-mecanicas.md` solo define el daño de las armas de Byte. Sin estos números no se puede implementar M2 ni M5 ni calibrar el daño recibido. Corrección: añadir una columna "Daño" en la tabla de enemigos (p. ej. 1 PV por proyectil y por contacto) y un valor de daño por cada ataque de cada jefe (A, B, C…).

2. **Plataformas del jefe inalcanzables con el salto definido.** `docs/05-enemigos-y-jefes.md` (arena del Router) coloca las 2 plataformas a `y=240`, es decir 72 px sobre el suelo (`y=312`); `docs/03-mecanicas.md` fija el salto en −330 px/s con gravedad 900 px/s², que da ≈60 px de altura máxima. Byte no puede subir a ellas (y no hay dash vertical), lo que rompe la esquiva de la Fase 1. Corrección: bajar las plataformas a `y≤252` (60 px sobre el suelo) o subir la velocidad de salto a ≈−360 px/s.

3. **Malwarex tiene 4 fases pero la regla solo prevé 2 umbrales.** `docs/05-enemigos-y-jefes.md` dice "cambio de fase al 70 % y al 40 % (o 50 % en jefes de 2 fases)" y `docs/04-niveles.md` lista Malwarex con 4 fases. Con 2 umbrales solo se obtienen 3 fases. Corrección: definir 3 umbrales (p. ej. 75/50/25 %) para Malwarex, o reducirlo a 3 fases.

4. **Duración total incoherente con la duración por mundo.** `docs/01-gdd.md` fija "3–4 h el juego completo; 10–15 min por mundo". Con 6 mundos eso da 60–90 min (≈1–1,5 h), la mitad del rango declarado (y `docs/04-niveles.md` da 7–12 min por mundo, aún menos). Corrección: cambiar a "1,5–2 h" o subir a "20–25 min por mundo".

5. **Ubicación de checkpoints contradictoria.** `docs/03-mecanicas.md` dice que los checkpoints están "al inicio del puzle y del jefe", pero `docs/04-niveles.md` solo coloca un checkpoint en `x=1760` (mitad del nivel, antes de S4), no al inicio del puzle (x=2240) ni del jefe (x=2720). Corrección: unificar — poner un checkpoint al inicio del puzle y otro al inicio del jefe, o reescribir `03` como "un checkpoint a mitad de nivel".

6. **Hueco de 96 px "requiere dash" pero el dash mide 72 px.** `docs/04-niveles.md` (S2) define un hueco de 96 px que "requiere dash"; `docs/03-mecanicas.md` fija el dash en 72 px (96 px solo con la mejora *Dash extendido*). Con el dash base no se cruza. Corrección: subir el dash a ≥96 px, reducir el hueco a ≤72 px, o especificar que se cruza con "salto + dash".

7. **Tipos de mejora "Pasiva" vs "Permanente" mal etiquetados.** `docs/03-mecanicas.md` marca "Más vida" y "Dash extendido" como tipo "Pasiva" en la tabla, pero el texto dice que son "permanentes y no ocupan ranura"; `docs/07-modelos.md` ya define el enum `WEAPON, PASSIVE, PERMANENT`. Corrección: usar el tipo "Permanente" para esas dos mejoras en la tabla de `03`.

8. **Faltan núcleos ocultos respecto a la regla.** `docs/03-mecanicas.md` dice "2 núcleos ocultos por mundo", pero `docs/04-niveles.md` solo coloca 1 núcleo oculto en el Mundo 1 (tercera plataforma de S2). Corrección: colocar el segundo núcleo del Mundo 1 (p. ej. tras el puzle o en S4) o cambiar la regla a "1 núcleo oculto en el prototipo".

9. **El arma "Ping" hace mucho menos daño que la base.** `docs/03-mecanicas.md`: Paquete = 8 DPS (1×8/s) frente a Ping = 4,8 DPS (0,8×6/s). La mejora teledirigida rinde ~40 % menos que el arma inicial, por lo que comprarla es una desventaja. Corrección: subir Ping a daño 1,2 o daño 1 con cadencia 6–7/s para que quede por encima del base.

10. **Orden de zonas distinto entre `contexto.md` y los docs.** `contexto.md` lista "Red local, Wi-Fi, Servidor, Nube, Firewall, Centro de datos", mientras `docs/01-gdd.md`/`docs/04-niveles.md` usan "LAN → Wi-Fi → Firewall → Servidor → Nube → Centro de datos" (cambio documentado en `00`). Corrección: unificar el orden en `contexto.md` con el de `01/04` o añadir la nota de reordenamiento allí.

11. **Versión de Godot sin unificar.** `docs/01-gdd.md` dice "Godot 4.7"; `docs/02-plan-desarrollo.md`, `docs/08-arquitectura-tecnica.md` y `docs/11-investigacion.md` dicen "4.7.2". Corrección: escribir "4.7.2" en `01`.

12. **Plataformas de destino vs exportación.** `docs/01-gdd.md` fija "PC (Windows/Linux)"; `docs/08-arquitectura-tecnica.md` solo define exportación "Windows Desktop y Web (HTML5)". Corrección: añadir el preset Linux en `08` o quitar "Linux" de `01`.

13. **Arena del jefe no cabe en su sección del mapa.** `docs/04-niveles.md` dibuja la sección BOSS en `2720–3200` (480 px) pero la arena del jefe es "pantalla fija de 640×360" (`04` y `05`). Corrección: marcar `RouterBoss` como escena aparte fuera del mapa, o ampliar la sección a 640 px (2720→3360).

14. **Nombre de estado del enemigo inconsistente.** `docs/11-investigacion.md` cita la máquina de estados con "ATTACK", mientras `docs/05-enemigos-y-jefes.md` y `docs/07-modelos.md` usan "ACTIVE". Corrección: unificar el nombre del estado a "ACTIVE" en `11`.

15. **Suelo base desalineado con la rejilla de tiles.** `docs/04-niveles.md` fija el suelo en `y=312` pero exige "tiles de 16×16 y todo alineado a esa rejilla"; 312 no es múltiplo de 16 (312/16 = 19,5). Corrección: mover el suelo a `y=304` (19×16) o `y=320`.
