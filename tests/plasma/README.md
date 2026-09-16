# Regresión de los parches de KWin

Compilar el cliente usando el nixpkgs fijado por el flake:

```sh
nix build --impure --file tests/plasma --out-link /tmp/plasma-lifetime-probe-result
```

Ejecutar con el binario de KWin que se desea verificar:

```sh
bash tests/plasma/run-isolated.sh \
  /nix/store/RUTA-KWIN/bin/kwin_wayland \
  /tmp/plasma-lifetime-probe-result/bin/plasma-lifetime-probe 1
```

El wrapper crea configuración, caché, socket Wayland y bus D-Bus separados,
usa renderizado virtual por software y finaliza al terminar el cliente
(límite de 45 segundos). No reinicia ni configura la sesión real. Conserva
los archivos temporales en la ruta impresa para inspeccionarlos.

El cliente comprueba la versión anunciada de `wl_fixes`, solicita blur sobre
una superficie válida, destruye la superficie y vuelve a solicitar blur.
Repite 200 veces, incluyendo nuevas superficies válidas después de la
petición obsoleta. El éxito comprueba que la conexión sigue funcionando;
no es una comprobación visual del efecto ni reproduce todos los cierres QML.

Con KWin 6.7.4 original, usar `2` como último argumento: se espera salida
10 y `tried to set blur region on destroyed surface` en la primera vuelta.
Con los dos parches se espera versión 1, salida 0 y `PASS`.
