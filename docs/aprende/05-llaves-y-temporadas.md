# 05. Las 7 llaves y las temporadas

## Una temporada = 2 semanas

`src/shared/Config/Keys.luau` dice cuándo empieza la temporada 2 (`epoch`, en segundos desde
1970) y cuántos días dura (`seasonDays = 14`). `Keys.Season()` hace la cuenta:

```lua
local length = Keys.seasonDays * 24 * 60 * 60
return math.max(1, math.floor((os.time() - Keys.epoch) / length) + 2)
```

Todos los servidores tienen la misma hora, así que todos saben qué temporada es.

## Dónde quedan las llaves: una semilla

Cada mundo dice dónde **puede** haber una llave (sus escondites):

```lua
Selva.keySpots = {
	{ name = "Arena", position = S + Vector3.new(-38, GROUND, -350) },
	...
}
```

`KeyService` junta todos y los revuelve con `Random.new(semilla)`. La semilla sale del número
de temporada y una clave (`SALT`). Con la misma semilla, `Random` da siempre los mismos
números: por eso todos los servidores ponen las llaves en el mismo lugar, y la siguiente
temporada (otra semilla) quedan en otro.

Para agregar escondites a un mundo nuevo: haz su lista `keySpots` y en `init.server.luau`:

```lua
KeyService.AddSpots("Volcan", Volcan.keySpots)
```

Mientras haya menos de 7 mundos, las llaves también se esconden en el Nexo. Cuando haya 7 o
más mundos, solo en los mundos (una por mundo).

## Cada quien su llave

La llave es una sola en el mapa, pero cada jugador la toma para sí mismo
(`DataService.GiveKey`). Su aviso tiene `OcultarSi = "Llave_3"`: en cuanto tienes ese atributo,
tu pantalla la esconde (`client/Prompts`), pero tus amigos todavía la ven.

## Leyendas

Con las 7, `DataService.CompleteSeason` suma una temporada de Leyenda (atributo `Leyenda`), y
`KeyService` guarda tu hora de llegada en un **OrderedDataStore** (`LeyendasT<temporada>`), que
sabe ordenar: así el Salón muestra quién llegó primero. El título y el aura los pone el
servidor en tu personaje para que todos los vean.

## Probar en Studio

En Studio no se guarda nada y en Output sale dónde quedó cada llave:

```
[Llaves] Temporada 1: llave 1 en Selva / SalaPlaca
```
