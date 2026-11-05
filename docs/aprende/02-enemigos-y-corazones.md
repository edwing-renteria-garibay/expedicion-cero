# 02. Enemigos, corazones y cristales

## Cómo piensa una máquina del Óxido

Cada máquina tiene un "cerebro": un ciclo que se repite cada 0.15 segundos
(`src/server/Services/EnemyService.luau`, funciones `walkerBrain` y `turretBrain`):

1. Busca al jugador vivo más cercano que pueda **ver** (un rayo invisible desde la máquina
   hasta ti: si choca con chatarra, no te ve).
2. Si no ve a nadie, **pasea** cerca de donde salió.
3. Si te ve y estás lejos, **camina hacia ti** (`humanoid:MoveTo`).
4. Si estás cerca, se detiene, **pone el ojo rojo** (`windup`) y después ataca. Si rodaste a
   tiempo, el servidor ve el atributo `Esquivando` y no te hace nada.
5. Si le pegas, queda **aturdida** (`Enemies.stun`) y no hace nada un instante.

Para inventar un enemigo nuevo copia uno de `Config/Enemies.luau`, cámbiale los números y
agrégalo a `World.enemySpots` en `src/server/World.luau`.

## El escudo del Escudero

En `StaffService.luau`, la función `blocked` compara hacia dónde mira el Escudero con de dónde
viene tu golpe. Si le pegas de frente con un golpe normal, rebota. `Enemies.guardBreakers`
dice qué golpes lo atraviesan (el remate y el giro).

## Corazones

La vida de Roblox sigue existiendo, pero vale **20 por corazón** (`Settings.hearts.value`).
`HealthService` pone la vida máxima según tus corazones y `UI/HUD.luau` dibuja un ♥ por cada
20. Para que no se cure sola, `src/character/Health.server.luau` reemplaza el script de Roblox
que cura con el tiempo.

## Guardado

`DataService` guarda una tabla por jugador en un DataStore:

```lua
{ crystals = 23, hearts = 4, chests = { CofrePlaya = true } }
```

En Studio no guarda (para probar sin miedo). Para que guarde en el juego publicado, en Studio
ve a Configuración del juego > Seguridad y prende "Enable Studio Access to API Services".

## Ejercicio

En `Config/Enemies.luau` cambia el `windup` del Rastreador a 1.5. Ahora tendrás mucho tiempo
para rodar cuando su ojo se ponga rojo. Regrésalo a 0.5 cuando termines.
