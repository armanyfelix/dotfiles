# Configuración de Herdr

`config.toml` es la configuración editable de Herdr; Home Manager la enlaza en
`~/.config/herdr/config.toml` con `mkOutOfStoreSymlink`, así que los cambios se
guardan aquí sin necesidad de un rebuild. Para que Herdr los tome en caliente:
`herdr server reload-config` (o `prefix+Shift+R`).

## Los scripts de `bin/`

Herdr no genera ningún script auxiliar: en `[[keys.command]]` sólo ejecuta el
comando que le escribas y espera que exista. Estos tres son los que esta
configuración da por hechos, y por eso viven en el repo:

| Script | Qué hace | Tecla |
| --- | --- | --- |
| `herdr-split-pane <left\|down\|up\|right>` | Herdr sólo parte nativamente hacia `right` y `down`. Para `left` y `up` parte hacia el lado espejo e intercambia el panel nuevo con su vecino, de modo que aparece del lado que pediste y con el foco dentro. | `prefix+h/j/k/l` |
| `herdr-focus-or-tab <left\|down\|up\|right>` | Mueve el foco al panel vecino; si ya estás en el borde, cambia a la pestaña anterior/siguiente del mismo workspace y entra por el borde contrario. | `alt+h`, `alt+l` |
| `herdr-agent-attention` | Salta al agente que te espera: primero los `blocked` (piden permiso o preguntaron), luego los `done` (terminaron sin que los vieras); dentro de cada grupo, el que lleva más tiempo esperando. Si no hay nadie, avisa con una notificación. | `prefix+a` |

Todos hablan con el servidor por la API de socket (`herdr pane …`,
`herdr tab …`, `herdr agent …`) y necesitan `herdr` y `jq` en el `PATH`. Como
Herdr los lanza en segundo plano, sin el entorno de una sesión interactiva,
cada script rehace su propio `PATH` con las rutas de NixOS y las de una distro
tradicional.

`alt+j` y `alt+k` siguen siendo acciones nativas (`focus_pane_down/up`). Sólo el
eje horizontal pasa por el script, porque es el que salta de pestaña; por eso
`focus_pane_left` y `focus_pane_right` quedan vacíos: su valor por omisión es
`prefix+h` y `prefix+l`, que aquí ya son splits.

## En la otra máquina

`config.toml` invoca los scripts como `$HOME/.local/bin/<script>`, que es donde
los pone Home Manager en NixOS (`home/terminal.nix`) y donde ya estaban en
Fedora. Para replicarlos ahí basta con enlazarlos desde este checkout:

```sh
mkdir -p ~/.local/bin
for s in herdr-split-pane herdr-focus-or-tab herdr-agent-attention; do
  ln -sf "$PWD/config/terminal/herdr/bin/$s" ~/.local/bin/"$s"
done
```

## Diagnóstico

- `herdr config check` valida el TOML, no comprueba que los comandos existan.
- Si una tecla no hace nada, ejecuta el script a mano desde un panel de Herdr
  (`~/.local/bin/herdr-split-pane left`): ahí sí se ven los errores, porque al
  lanzarlos desde una tecla Herdr los corre en segundo plano y se traga la
  salida.
- Si una tecla se ignora por completo, mira `~/.config/herdr/herdr-client.log`.
  Cuando dos bindings chocan, Herdr desactiva uno en silencio y sólo lo anota
  ahí: `config diagnostic alt+h: kept keys.focus_pane_left, disabled
  keys.command[0].key`. La acción nativa siempre gana, y `herdr config check`
  no ve ese conflicto.
- A los comandos de tecla Herdr les exporta `HERDR_ACTIVE_PANE_ID`, no
  `HERDR_PANE_ID`. Por eso los scripts pasan `--pane` en vez de `--current`:
  esa bandera exige `HERDR_PANE_ID` y falla con `--current requires
  HERDR_PANE_ID` justo cuando la llamada viene de una tecla.
