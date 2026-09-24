# Portal de Servicios — proyecto base del curso Flutter corporativo

Este es el proyecto sobre el que se hacen todos los laboratorios del curso
**«Flutter profesional: itinerarios para desarrolladores Android, iOS y Flutter»**.
Te llega ya montado para que no tengas que construirlo: arráncalo y empieza.

```bash
flutter pub get
flutter gen-l10n
flutter run
flutter test
```

Si es tu primer día, no sigas por aquí: ve a la sección **Día 0** del manual
(`Curso_Completo_Flutter_Corporativo.md`, o el enlace de la web del curso).
Explica qué hace cada comando, qué hay en cada carpeta y cómo se traducen las
rutas y los imports desde Android o iOS.

## Qué implementa

Sesión ficticia para dos cuentas, listado de solicitudes filtrable y paginado,
detalle, creación idempotente, borrador en memoria por cuenta, textos en ES/EU,
rutas y pruebas. Funciona con datos en memoria o contra el servidor local del
apéndice B (`tool/lab_server.py`, requiere Python 3.10 o posterior).

Los datos son ficticios y la autenticación es una simulación declarada. Ninguna
credencial de este laboratorio debe usarse como mecanismo de autenticación real.

## Comprobación de calidad

```bash
bash tool/verify.sh
```

Ejecuta formato, análisis y pruebas con cobertura. Es lo que debe pasar antes de
entregar cualquier evidencia.

## De dónde sale este proyecto

Su código fuente es el **apéndice A del manual**: cada bloque marcado con una
ruta es un archivo de aquí. El manual es la fuente de verdad — si hay que
cambiar algo, se cambia allí y se regenera este proyecto con
`../sync_lab.sh`, que además comprueba que los dos no se han separado.

Usa Git desde el principio: una rama por laboratorio y un commit antes de
introducir cada defecto deliberado.
