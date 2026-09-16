# Configuración de Plasma

Estos archivos son la configuración editable del escritorio de `armanix`.
Home Manager los enlaza desde `~/.config` usando `mkOutOfStoreSymlink`, por
lo que los cambios realizados en Preferencias del sistema y en los paneles
se guardan directamente aquí. No hace falta un rebuild para guardar esos
cambios; sí revisar `git diff` y hacer commit para conservarlos en Git.
Un rollback de NixOS cambia los paquetes, pero no revierte estos archivos
editables: su historial y restauración corresponden a Git o a los respaldos.

La importación inicial conserva la configuración que estaba activa durante
la migración. Las copias antiguas se guardaron en
`.backups/plasma-20260905-vfC4P0/` (excluida de Git).
La activación del 6 de septiembre volvió a importar los cambios más recientes;
el estado previo del repositorio está en
`.backups/plasma-migration-20260906-LU2mXVXU/repo-kde/`.

Home Manager mueve los archivos y directorios que reemplaza a
`~/.local/state/home-manager/backups/activation-*/`, conservando su ruta
relativa. Los respaldos de widgets quedan fuera de las rutas que examina KDE.
Los archivos fuente deben existir en este checkout antes de activar;
Home Manager comprueba esto antes de modificar los enlaces.

Los widgets declarados, Krohnkite, Geometry Change, Waywallen y el tema
Utterly-Nord proceden de paquetes Nix.
Sus archivos de programa son de solo lectura; sus ajustes permanecen en
estos archivos editables. Compact Pager ya no forma parte de la configuración;
su copia local se mueve al respaldo durante la activación, si todavía existe.
Los presets de Colorizer y el lanzador de Waywallen usan rutas estables,
sin depender de hashes de generaciones antiguas del almacén Nix.

No se enlaza todo `~/.config`: cachés, credenciales y estado de otras
aplicaciones siguen separados. Tampoco se versiona `kwinoutputconfig.json`
ni `session/`, que contienen estado específico de las pantallas/sesiones.
El cursor personalizado Skyrim y temas alternativos descargados manualmente
no están empaquetados aquí; se conserva su selección, pero una instalación
nueva necesita también esos recursos. No se respaldan los vídeos/fondos
descargados por Waywallen ni datos de Steam.

## Aplicar cambios de paquetes

```sh
sudo nixos-rebuild boot --flake /home/armanix/Dotfiles#armanix
```

Después, reiniciar cuando sea conveniente. `nrs` ejecuta ese mismo comando.
Así las actualizaciones del kernel/NVIDIA entran junto con el nuevo arranque.
`nu` actualiza los inputs de este flake; los canales no controlan este sistema.

El backport de KWin está en `system/patches/kwin-wl-fixes-v1.patch` y sólo se
aplica a 6.7.4. Evita anunciar `wl_fixes` v2 por defecto (KDE MR 9784).
`system/patches/kwin-ignore-stale-blur.patch` es una mitigación local para
KDE 522547: ignora solicitudes de blur sobre superficies ya destruidas sin
desconectar al cliente. Conserva la comprobación de superficie y no cambia
las solicitudes válidas. Relaja deliberadamente ese error del protocolo;
no corrige el problema de vida útil en el cliente Qt/KDE. Retirarla cuando
exista una corrección upstream. Ambos parches se limitan a KWin 6.7.4.
No se bloquea `ext_background_effect_manager_v1`: se comprobó que este KWin
ya no anuncia el protocolo antiguo, de modo que bloquearlo quitaría el blur.

Un rebuild no demuestra la desaparición de los cierres intermitentes. Tras
iniciar la nueva sesión, comprobar el modo edición y los registros de Plasma
y Zen durante el uso habitual.

La prueba de regresión aislada está documentada en `tests/plasma/README.md`.
