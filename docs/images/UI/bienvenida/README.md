# Maqueta de la bienvenida con Ulises

`ulises-te-recibe-combinada.html` es la versión combinada de «Ulises te recibe», la que el dueño
elige el 2026-09-25 para el arranque sin sesión. Es la referencia visual de RF-SPL-20 y RF-SPL-21
de `specs/features/splash/splash.spec.md` y de `specs/features/bienvenida/bienvenida.spec.md`
(RF-BIEN-19). El dueño aprueba las dos specs el 2026-09-26, y donde la maqueta y una spec
difieren, manda la spec.

- Se abre sola en un navegador. Arriba elige el recorrido («Con sesión», «Soy nuevo» y «Ya tengo
  cuenta») y la intro del splash («Al azar», Ensamble, Incremento y Código), y abajo tiene Repetir,
  «Modo oscuro» y «Reducir movimiento».
- La imagen de Ulises es `assets/images/ulises_chatbot.png` del repo, que la maqueta lee con una
  ruta relativa, así que se abre desde esta carpeta del repo.
- Con sesión, la intro termina en `/home` abierto en la pestaña Horario (RF-SPL-20). Sin sesión, la
  estrella se queda entera en el centro con sus «++», Ulises aterriza a su lado sin taparla y, al
  responder «¿Ya usas ULima++?», la estrella sube al sello junto a «ULIMA++» (RF-SPL-21 y
  RF-BIEN-2).

## Diferencias con la spec del splash

- Las tres intros son las maquetas de `docs/images/UI/splash/`, con las diferencias que lista su
  README, como los 86 dp de la estrella de Código.
- Con sesión, Ulises aparece en su burbuja con un rebote después de la salida. En la spec del
  splash aparece con la página, como hoy (decisión S-28, que el dueño aprueba junto con B-16).
- La maqueta abre Horario solo para una alumna. En la app abren en Horario todos los roles
  (decisión S-24 del splash).
- La maqueta no tiene el recorrido del alumno con sesión y sin especialidad. En la spec del splash,
  la intro hace con él el mismo relevo que sin sesión (RF-SPL-12 y decisión S-29).

## Diferencias con la spec de la bienvenida

Todo lo que pasa después del relevo lo fija la spec de la bienvenida, y en estos puntos manda ella.
Las decisiones de la bienvenida llevan el prefijo B y las del splash, el prefijo S.

- El test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos tu test de
  especialidad? Son 14 preguntas cortas.», «Prefiero esperar» y «Empezar el test». En la spec
  empieza con la cuenta ya creada, porque su contenido exige el token (decisión B-1).
- El código del authenticator se envía solo al completar las seis casillas. En la spec se envía
  con el botón «Crear mi cuenta» (decisión B-5).
- «Soy nuevo» usa blanco al 14 % sobre el naranja, con 2,59:1. En la spec va sobre `#B84A00`, con
  5,23:1 (decisión B-3). La pista de los campos usa `#8A94A6` y el foco `#FF6600`, que en la spec
  pasan a `testMuted` y a `bienvenidaFoco` (RF-BIEN-14).
- Ulises llama «Valeria» a la alumna. En la spec va sin nombre (decisión B-4).
- Mientras se crea la cuenta, Ulises dice «Tarda cerca de un minuto.». En la spec dice por
  defecto la advertencia de hoy, «Puede tomar un par de minutos: no cierres la app.», porque el
  envío puede durar hasta 120 s y el envío real todavía no tiene una medición (decisión B-17).
- Con la cuenta creada, la burbuja dice el nombre y los cursos traídos. En la spec va sin el
  nombre, en una sola burbuja, y sin las cifras de clases del horario ni de cursos del avance que
  hoy muestra la pantalla del registro (decisiones B-4 y B-31).
- Ulises mide 52 px al volar y 58 px al posarse, con su centro al 21,6 % del ancho y al 67,8 % del
  alto, y la tarjeta empieza 11 px después de su borde derecho. En la spec el dibujo se escala por
  1,2, como la estrella, así que Ulises mide 62 y 70 dp y aterriza medido desde la estrella,
  mientras la tarjeta y los botones miden en dp lo que la maqueta mide en px y se ven un poco más
  chicos frente a la estrella. La maqueta no tiene la regla «Si no cabe» (RF-BIEN-2 y decisiones
  B-27 y B-28).
- Con «Reducir movimiento», `toSeal` y `toHorario` llevan la opacidad del logo a 0 y después a 1,
  así que por un momento la pantalla queda sin logo. En la spec son fundidos cruzados, con el
  logo que llega encima del que se va, y nunca falta un logo (RF-BIEN-15).
- El turno de la contraseña de «Ya tengo cuenta» no trae «Soy nuevo», y los turnos del registro
  no traen «Volver» ni «Ya tengo cuenta». En la spec están en todos (RF-BIEN-6, RF-BIEN-7 y
  RF-BIEN-9).
- No hay turnos de error, de `incierto` ni de sesión expirada, que la spec define en RF-BIEN-8 y
  RF-BIEN-12. En la spec, `incierto` trae además «Ya tengo cuenta» (decisión B-30).
- El duelo no trae «Me gustan las dos» ni «Ninguna me llama», y el resultado dice «Elegir Software
  como principal», sin «Rehacer el test», los electivos ni «También te puede interesar». Mandan
  la spec del test y RF-BIEN-10.
- Las líneas de Ulises dentro del test, como «Primera práctica y te dejan escoger. ¿Cuál te
  pides?» o «¡Craa! Lo tuyo es esto, Valeria 👇», son ilustrativas. Mandan las del contenido.
- El marcador «12 preguntas después» es un atajo de la maqueta y no existe en la app.
- Los campos, las píldoras y los enlaces miden menos de 48 dp. En la spec miden al menos 48 dp
  (RF-BIEN-16).
- La franja mide 100 px y la cabecera 96 px. En la spec miden lo mismo (RF-BIEN-4).
- No hay llegada con la sesión de un alumno sin especialidad. En la spec, Ulises aterriza junto a
  la estrella sin la tarjeta ni los botones, la estrella sube al sello y Ulises lo invita al test,
  que termina en el horario (RF-BIEN-21 y decisión B-10).
- No hay pantallas de «¿Olvidaste tu contraseña?». En la spec son las de hoy, con el sello en su
  cabecera, en el mismo lugar que en la conversación (RF-BIEN-20 y decisión B-9).

Los datos son ficticios. El código es `20230001`, la alumna se llama Valeria, las contraseñas son
de relleno y se muestran como puntos, el código del autenticador, `482913`, es inventado, y los
cursos y las aulas también.
