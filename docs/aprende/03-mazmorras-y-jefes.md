# 03. Mazmorras, puzzles y jefes

## Las piezas de un puzzle

Todo puzzle se arma con piezas con **etiquetas** (CollectionService) y **atributos**.
`src/server/Puzzles.luau` revisa las placas 5 veces por segundo:

| Pieza | Etiqueta | Atributos |
| --- | --- | --- |
| Puerta | `Puerta` | `Id` (su nombre) |
| Placa | `Placa` | `Puerta` (el Id que abre), `Tiempo` (opcional, segundos abierta) |
| Bloque | `Empujable` | — |
| Pared agrietada | `Agrietado` | — |

Ejemplo: para una placa que abre la puerta "MiPuerta" por 5 segundos, en `Zones/Selva.luau`:

```lua
plate(folder, "MiPuerta", 10, -150, 5)
door(folder, "MiPuerta", 0, -170)
```

## Salas de combate

Una sala de combate es solo un contador: cada máquina se crea con `respawn = false` y una
función `onDied`. Cuando el contador llega a 0, se abre la puerta con
`Puzzles.SetDoor("SelvaSala1", true)`.

## El jefe: estados

El gusano (`src/server/Bosses/Worm.luau`) siempre está en uno de estos **estados**:

```
bajo -> subiendo -> arriba -> (aturdido) -> bajando -> bajo ...
```

- En `arriba` se lanza contra el jugador más cercano.
- Si le llega un Empuje en `arriba`, pasa a `aturdido`: se cae y quita su atributo `Blindado`.
- `StaffService` revisa `Blindado`: si lo tiene, el golpe rebota.

Pensar en estados es el truco para hacer jefes: cada estado hace UNA cosa y sabe a cuál
sigue.

## Islas lejos

Las islas están en el mismo lugar de Roblox, solo que muy lejos (la Selva está a 1500 studs).
Los portales (`PortalService`) te mueven con `character:PivotTo(destino)`. El cliente cambia la
niebla al entrar (`src/client/Zones.luau`, colores en `Config/Zones.luau`).

## Ejercicio

En `Bosses/Worm.luau` cambia `HEALTH` a 60 para vencer al gusano rápido y probar el núcleo.
Regrésalo a 360 al terminar.
