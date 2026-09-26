# Maquetas del splash animado

Estas maquetas son la referencia visual de `specs/features/splash/splash.spec.md`, que el dueño
aprueba el 2026-09-26. Donde una maqueta y la spec difieren, manda la spec.

- `splash-conceptos.html` es la página que ve el dueño el 2026-09-25, con los tres conceptos y el
  diagnóstico. Queda como constancia y no se corrige.
- `ensamble.html`, `incremento.html` y `codigo.html` son los tres conceptos de esa página, con
  Repetir, carga lenta y sin movimiento.
- `ensamble-adaptada.html` es Ensamble con el arranque de la spec (RF-SPL-7), desde la estrella
  completa del splash nativo. Su casilla «Arranque alternativo» muestra la alternativa de la
  decisión S-3.
- `splash-actual-recorte.jpg` es el centro de la captura del splash de hoy, sin la barra de estado
  del teléfono.
- La maqueta de la bienvenida con Ulises, que usa estas tres intros para mostrar el horario con
  sesión y el relevo sin sesión (RF-SPL-20 y RF-SPL-21), está en `docs/images/UI/bienvenida/`.

Las maquetas difieren de la spec en estos puntos, y en todos manda la spec.

- El arranque de Ensamble (RF-SPL-7). `ensamble.html` parte de la estrella central sola, y
  `ensamble-adaptada.html` ya muestra el arranque de la spec.
- El tamaño de la estrella del primer cuadro, que la spec fija en 90 dp para las tres variantes
  (RF-SPL-1), mientras las maquetas originales usan 70 dp para la estrella central de Ensamble y
  86 dp en Código.
- La geometría del logo, con un solo retraimiento de 3,5 u en la spec (RF-SPL-2) y de 3,5 a 8 u
  en las maquetas.
- El destello de Ensamble, que en la spec es un degradado recortado a la silueta del logo, sin
  desenfoque (RF-SPL-7). `ensamble-adaptada.html` ya lo muestra así.
- La página de destino, que en la spec aparece entera (RF-SPL-11) y en las maquetas originales
  entra por tarjetas escalonadas. `ensamble-adaptada.html` ya la muestra entera.
- El radio de la estrella de Código, 90 dp en la spec y 86 dp en la maqueta (RF-SPL-9).
- La letra de Código, que en la spec es la monoespaciada del sistema (RF-SPL-9) y en la maqueta
  la del navegador.
- La salida de Incremento, que en la spec empieza en cuanto termina la carga, también a mitad de
  un tic (RF-SPL-10), y en la maqueta espera 700 ms desde el inicio del tic.

Las tarjetas, los cursos y las aulas de las maquetas son inventados.
