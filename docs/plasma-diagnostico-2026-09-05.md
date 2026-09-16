# Diagnóstico de Zen y KDE Plasma

Fecha: 2026-09-05. Horarios locales de America/Tijuana (UTC−07:00).
Inspección de `/home/armanix/Dotfiles`, journal persistente desde agosto,
volcados de systemd, un volcado abierto en GDB y paquetes Nix instalados.
Esta primera sección registra la fase de diagnóstico, anterior a los cambios.
En esa fase no se modificó la configuración ni se reiniciaron servicios.
La intervención posterior y sus comprobaciones se documentan al final.

## Resultado

Hay varios fallos de software, con evidencia distinta. El principal cierre de
Zen y al menos un cierre de Plasma comparten un error de KWin/Wayland. Plasma
además presenta un error fatal del protocolo de desenfoque y fallos de Qt/QML
durante interacciones con el escritorio. Las actualizaciones en caliente
produjeron también incompatibilidad temporal entre las bibliotecas y el módulo
NVIDIA. No hay evidencia suficiente para atribuir todos los síntomas a NVIDIA,
al flake de Zen, a falta de RAM o a archivos de configuración dañados.

## Zen: error de KWin/Wayland confirmado

El journal contiene 14 anotaciones de cierre del proceso principal, desde el
9 de agosto hasta el 5 de septiembre, con esta misma firma:

```text
(kde) Wayland protocol error: wl_fixes#68: error 0:
the given registry did not announce global 76
```

Los identificadores numéricos cambian. La firma aparece en `zen-beta` 1.21.12b
y 1.21.15b y en `zen` 1.21.15b después del cambio de empaquetado. Los volcados
de los PID 2598 y 293593 muestran el hilo Renderer recibiendo el error en
`display_handle_error` → `wl_log` → `libxul.so`, mientras atendía eventos de
Wayland desde la creación de una superficie EGL. Esto no demuestra un fallo
de Mesa: las llamadas EGL son el contexto en que se recibe el error.

La firma coincide con el [bug Mozilla 2068618](https://bugzilla.mozilla.org/show_bug.cgi?id=2068618)
y con el diagnóstico del desarrollador de KWin en el
[bug Mozilla 2064274](https://bugzilla.mozilla.org/show_bug.cgi?id=2064274).
El problema involucra la retirada de objetos globales de Wayland y sus
confirmaciones con `wl_fixes` v2. El cambio de proveedor de Zen conserva
la interacción problemática con el compositor.

Plasma también recibió `wl_fixes#46: ... did not announce global 80`
el 25 de agosto a las 22:07:02. El 29 de agosto a las 20:29:18 sufrió otro
error de registro: `global wl_output (76) is unavailable`.

Hay además un volcado de `Isolated Web Co` del 22 de agosto (PID 254225)
que corresponde a un proceso de contenido; no comparte la firma anterior
y no se atribuye aquí a la misma causa.

### Qué cambió con el reinicio de hoy

La compilación anterior de KWin 6.7.4 no tenía el parche de mitigación.
La actual sí incluye el commit
[`2d0613ac`](https://invent.kde.org/plasma/kwin/-/commit/2d0613acd044544e79b034b1cbc248664edf2884.diff),
cuyo diff se verificó: cambia un temporizador de destrucción de globales
de 300000 ms a 24 horas. Reduce la exposición; no equivale a corregir
el protocolo. Se verificaron los atributos `patches` de ambas derivaciones.

La [MR de KWin 9784](https://invent.kde.org/plasma/kwin/-/merge_requests/9784)
contiene otro cambio, también leído: anunciar `wl_fixes` v1 por defecto,
y v2 solamente si existe `KWIN_USE_FIXES_V2`. Ese cambio no está en la lista
de parches del paquete actual. El seguimiento de Mozilla apunta a Plasma
6.7.5 para su distribución; no se ha probado aquí una compilación corregida.

## Plasma: tres caminos de fallo diferenciados

| Momento | Evidencia | Conclusión y límite |
| --- | --- | --- |
| 2026-08-30 15:20:58 | PID 1972, SIGSEGV en `QSortFilterProxyModelPrivate::proxy_to_source`, después de mensajes de arrastre del gestor de tareas, Compact Pager y un tooltip | Fallo de Qt/modelo de tareas durante interacción. No identifica por sí solo al widget responsable. |
| 2026-09-05 18:04:27 | PID 36006, `ext_background_effect_surface_v1: tried to set blur region on destroyed surface`, salida 255 | Solicitud de desenfoque sobre una superficie destruida; Wayland desconecta Plasma. No genera necesariamente un coredump. |
| 2026-09-05 18:43:25 | PID 471993, SIGSEGV en `QQmlConnections::connectSignalsToMethods`, durante la carga de configuración de Panel Colorizer 8.0.0 | Fallo nativo Qt/QML confirmado; la atribución exclusiva al widget requiere aislarlo. |

En el último caso, GDB confirmó el acceso nulo: en el punto original de fallo
`rbx=0`, y la instrucción intenta leer `0x20(%rbx)`. La pila sigue por
`QQmlObjectCreator::finalize` y `QQmlComponent::createObject`.
El segundo anterior al cierre contiene múltiples errores de
`configAppearance.qml` de Panel Colorizer, propiedades `cfg_*` inexistentes
y un bucle de binding en `FormWidgetSettings.qml`.
Su código instalado crea este formulario mediante `Qt.callLater` y
`settingsComp.createObject(layout)`, consistente con la pila. Es una
localización sólida del contexto, no una reproducción que demuestre qué
línea originó el estado inválido.

El error de desenfoque coincide con el
[reporte KDE 522547, comentario de otro usuario de Plasma](https://mail-archive.com/kde-bugs-dist%40kde.org/msg1206793.html).
El journal local registra salida 255, reinicio programado y arranque de
Plasma un segundo después. Esto explica el parpadeo y recuperación automática.

Los volcados recientes corresponden a Qt 6.11.1. Tras el reinicio, el proceso
actual carga Qt 6.11.2. No se debe declarar que ese cambio arregló el fallo
sin repetir la interacción que lo dispara.

### Lentitud tras reiniciar Plasma

Durante el reinicio de las 18:43 aparecen 54 mensajes de textura QSG ausente
en aproximadamente 45 segundos, y bucles de bindings de la copia local de
Plasmusic Toolbar. Hay cuatro instancias de Panel Colorizer y Waywallen
cargado como fondo en dos contenedores. Krohnkite también registra errores
de creación QML sin padre.

Son candidatos para explicar trabajo repetido y reconstrucción defectuosa
del escritorio. No hubo una captura de rendimiento durante el episodio de
lentitud; por tanto no se atribuye definitivamente la lentitud a un plugin.
En la inspección posterior al reinicio no había servicios fallidos ni
reinicios de la unidad actual de Plasma.

## Actualizaciones Nix/NVIDIA

Hoy se activó una nueva generación con `switch` a las 18:20 manteniendo
la sesión abierta. El journal de las 18:43:37 y 18:44:39 confirma:

```text
NVRM: API mismatch
client: 595.99.02
kernel module: 595.91.07
```

El patrón también aparece el 22/23 de agosto entre 595.91.07 y 595.84.
Una activación cambia las bibliotecas disponibles sin reemplazar el módulo
NVIDIA que sigue cargado. Esto es un problema real añadido, pero los 14
errores de protocolo de Zen tienen evidencia propia.

Tras el reinicio de las 19:19, `/run/current-system` y `/run/booted-system`
coinciden. `nvidia-smi` fuera del sandbox reconoce la RTX 3060 Laptop con
595.99.02, igual que `/proc/driver/nvidia/version`.

No se encontraron mensajes de OOM killer, NVIDIA Xid, errores de E/S,
errores Btrfs ni errores de hardware en el journal de kernel consultado.
Eso no sustituye pruebas de hardware. Hay aproximadamente 19 GiB de RAM
y no hay swap, pero no hay evidencia de que estos cierres fueran por OOM.

## Los respaldos KDE aún no reproducen todo el escritorio

`home/kde.nix` instala paquetes y ejecuta la instalación de Waywallen.
No declara restauración de `kdeglobals`, `kwinrc` ni
`plasma-org.kde.plasma.desktop-appletsrc`.
Los archivos activos en `~/.config` son archivos normales y el layout activo
difiere de la copia del repositorio. Hay copias diferentes en `config/`
y `config/kde/`, y varios archivos nuevos siguen sin seguimiento en Git.

Algunos widgets se cargan de `~/.local/share/plasma/plasmoids`, aunque sus
paquetes también se instalan por Nix; el journal lo confirma para Plasmusic
Toolbar. Por ello, reconstruir el sistema no garantiza actualizar la copia
de widget que se ejecuta ni restaurar el layout guardado. Esto es un problema
de reproducibilidad independiente; no prueba corrupción de los dotfiles.

## Siguiente intervención recomendada

1. Incorporar el cambio oficial de KWin que evita `wl_fixes` v2, o una
   versión que lo incluya. Verificar construcción y versión antes de activar.
2. Repetir la configuración de Panel Colorizer con el Qt actual; si persiste,
   aislar sus instancias de forma reversible, conservando el layout y sus
   ajustes. Tratar por separado la firma del desenfoque. Para la lentitud,
   medir mientras ocurre y variar un componente a la vez.
3. Cuando se actualice NVIDIA, usar una activación al próximo arranque
   (`nixos-rebuild boot --flake .#armanix`) y reiniciar en un momento elegido.
4. Unificar el mecanismo de respaldo/restauración KDE y resolver las copias
   de widgets locales frente a las de Nix.

Estas intervenciones se describen como pasos siguientes; no se ejecutaron
como parte del diagnóstico.

## Consultas para volver a comprobar las firmas

```sh
journalctl --since '2026-08-01' --no-pager \
  --grep='Crash Annotation GraphicsCriticalError:.*the given registry did not announce global'

journalctl --since '2026-08-01' --no-pager SYSLOG_IDENTIFIER=plasmashell \
  --grep='wl_fixes|destroyed surface|crashing'

coredumpctl info 471993 --no-pager

journalctl --since '2026-09-05 18:04:20' --until '2026-09-05 18:04:30' --no-pager

journalctl _TRANSPORT=kernel --since '2026-08-01' --no-pager --grep='API mismatch'
```

## Intervención posterior: 2026-09-05/06

- `home/kde.nix` declara 18 archivos de configuración mediante enlaces
  editables al checkout y valida la existencia de las fuentes antes de
  modificar el home. Se conserva el layout activo, no la copia antigua.
- Widgets y recursos declarados se enlazan a paquetes Nix para resolver
  la precedencia de copias locales. La copia residual de Compact Pager se
  archiva fuera de las rutas de descubrimiento de KDE, sin borrarla.
- El respaldo de Home Manager usa directorios únicos bajo
  `~/.local/state/home-manager/backups/`, no extensiones junto a los widgets.
- `nrs` usa `nixos-rebuild boot --flake /home/armanix/Dotfiles#armanix`;
  `nu` actualiza el flake, no los canales.
- KWin 6.7.4 incorpora el backport oficial de `wl_fixes` v1 y una mitigación
  **local, no upstream**, que ignora peticiones cosméticas de blur sobre
  superficies destruidas. Conserva la guarda de puntero y el comportamiento
  de las superficies válidas; no arregla el origen del objeto obsoleto en
  Qt/KDE. Ambos parches dejan de aplicarse fuera de 6.7.4.

### Verificaciones realizadas

Se compiló KWin con los dos parches y se ejecutó el mismo cliente Wayland
en dos compositores virtuales aislados, sin usar el socket ni el bus de la
sesión real. El KWin original anunció `wl_fixes` v2 y desconectó al cliente
en la primera petición de blur obsoleta, con exactamente la firma del journal.
El corregido anunció v1 y completó 200 ciclos de peticiones válidas y
obsoletas, sin perder la conexión. Prueba reproducible en `tests/plasma/`.
Esto verifica los caminos de protocolo, no la apariencia visual ni todos
los fallos intermitentes de Plasma.

Una prueba real con `kwriteconfig6` confirmó que KConfig escribe a través
de la cadena de symlinks hasta el archivo editable sin romper los enlaces.
El helper de respaldo pasó `bash -n` y dos reemplazos sucesivos conservaron
ambas versiones en directorios distintos. `git diff --check` pasó.

Se descartó bloquear `ext_background_effect_manager_v1`: una prueba Qt
contra la sesión real encontró el protocolo nuevo, pero no el antiguo.
Bloquearlo habría quitado el blur; esa variable no se configura.

Los mensajes recientes de Plasmusic citaban `animationRunning`, propiedad
que ya no aparece en la copia instalada de `ScrollingText.qml`. Plasma había
arrancado a las 19:19 y ese archivo se reemplazó a las 19:20. Esto confirma
que actualizar archivos no reemplaza automáticamente el código ya cargado.

Queda por verificar en uso real el SIGSEGV de `QQmlConnections` al configurar
Panel Colorizer y la lentitud posterior. No se atribuye definitivamente al
widget ni se declara corregido por estas pruebas de protocolo.

### Activación de Home Manager: 2026-09-06 09:56

La simulación y la activación real finalizaron correctamente. Se detuvo
únicamente `plasma-plasmashell.service`, se importó la configuración activa
tras vaciar sus cambios pendientes y se reinició ese servicio. Se comprobaron
los 18 symlinks de configuración contra las rutas del checkout y los enlaces
de los widgets/efectos contra sus paquetes Nix. La caché QML anterior se
archivó para cargar nuevamente el código de los widgets.

Se sustituyeron rutas antiguas del almacén Nix en `lastPreset` de Colorizer
por el enlace estable local, y el lanzador de Waywallen por
`applications:waywallen.desktop`. Se retiró del slideshow una ruta antigua
de Breeze; se conserva `/run/current-system/sw/share/wallpapers/`.

Respaldo inmediatamente anterior del repositorio:
`.backups/plasma-migration-20260906-LU2mXVXU/repo-kde/`.
Los originales activos quedaron bajo
`~/.local/state/home-manager/backups/activation-*/`, incluyendo la copia
residual de Compact Pager (`activation-tlzqFx7H`) y la caché QML
(`activation-K6CMvJ20`). No se eliminaron permanentemente.

Plasma arrancó con PID 203178, sin reinicios automáticos en la comprobación
inmediata. Persisten avisos QSG de textura durante la reconstrucción del
escritorio; aún no se ha probado que desaparezca la lentitud en modo edición.
La activación de Home Manager no reemplaza el KWin que está ejecutándose:
las mitigaciones del compositor requieren iniciar la nueva generación.

### Generación preparada para el siguiente arranque

La construcción completa y una segunda construcción de verificación del
checkout final finalizaron con código 0. Se registró mediante
`nixos-rebuild boot --store-path ...` la generación **39**:
`/nix/store/q6i2i48wwb2xjjm3dk61nckp9dr74b0n-nixos-system-armanix-26.11.20260905.c043004`.
Su `kwin_wayland` apunta al paquete probado:
`/nix/store/zyjidvb15z21f1pz4f9si3rhk4s87s5q-kwin-6.7.4`.
La ruta de módulos del kernel es idéntica a la del sistema en ejecución.

Se verificó el perfil de sistema apuntando a la nueva generación, mientras
`/run/current-system` permanece en la anterior. No se reinició el equipo ni
se sustituyó KWin dentro de la sesión abierta. Falta el reinicio elegido por
el usuario para ejecutar los parches en el escritorio real.

También se validaron los JSON de ajustes de los widgets, la ausencia de
secciones duplicadas, los ocho presets con rutas estables y la ausencia de
Compact Pager en el layout activo. No se hicieron commits de los dotfiles.
