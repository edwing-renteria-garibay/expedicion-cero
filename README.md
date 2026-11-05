# Expedición Cero

Aventura de acción en tercera persona para Roblox, de 1 a 4 jugadores. Eres un explorador del
Cuerpo Cero y, con tu dron compañero **Chispa** y tu bastón de energía, recuperas los cuatro
núcleos que el Óxido robó del Archipiélago Eco. Es el tercer juego de la serie "Cero", después
de Escuadrón Cero y Frecuencia Cero.

Documento de diseño: https://claude.ai/artifact/GYB3zhAxfYH2UVzHY8XDz4

## Qué hay

- **Puerto Eco**, la isla central en estilo caricatura: mar, playa, palmeras, la plaza con el
  pedestal vacío de los núcleos, cuatro portales apagados (Selva Brumosa, Volcán Brasa, Glaciar
  Silencio, Ruinas del Cielo), la tienda y el taller de Chispa (cerrados por ahora) y el
  **campo de práctica** con muñecos (`src/server/World.luau`, `src/server/Dummies.luau`)
- **Bastón de energía** en la mano de cada jugador (`src/shared/StaffModel.luau`):
  - **Clic**: golpe. Tres clics seguidos hacen el combo; el tercero es un remate que pega más
  - **Mantén el clic y suelta**: giro que pega a todo lo de alrededor (el cristal brilla cuando
    está cargado)
  - **Shift**: rodar (por un momento nada te hace daño)
  - **F**: fijar al enemigo más cercano; tus golpes van hacia él
  - Daños, alcances y tiempos en `src/shared/Config/Staff.luau`
- **Chispa**, el dron compañero (`src/client/Drones.luau`, `src/client/Chispa.luau`):
  - te sigue flotando junto al hombro (todos ven el dron de todos)
  - habla abajo en la pantalla: te saluda y comenta cada lugar la primera vez que llegas
  - **R**: escanea y marca a los enemigos cercanos a través de las paredes
  - le dispara un rayito a lo que golpeas
  - frases y números en `src/shared/Config/Drone.luau`
- **Máquinas del Óxido** en la **Chatarrería** (al suroeste de la plaza) (`src/server/Services/EnemyService.luau`, números en `src/shared/Config/Enemies.luau`):
  - **Rastreador**: chico y rápido, te persigue y muerde
  - **Escudero**: grande y con escudo; de frente tus golpes rebotan. Pégale por la espalda o
    usa el remate o el giro
  - **Torreta**: no camina; dispara bolas de óxido lentas que puedes esquivar
  - Antes de atacar, su ojo se pone **rojo**: es tu momento para rodar
  - Al romperse sueltan **cristales** y a veces un **corazón**, que se van hacia ti solos
- **Corazones** (arriba a la izquierda) en vez de barra de vida: empiezas con 3, no se curan
  solos (`src/server/Services/HealthService.luau`, `src/shared/Config/Settings.luau`)
- **Cofres escondidos**: 4 en la isla, cada uno se abre una vez por jugador. El de la
  chatarrería da un corazón más. Chispa los marca en dorado al escanear
  (`src/server/Services/ChestService.luau`)
- **Guardado**: cristales, corazones y cofres abiertos (en Studio no se guarda nada)
  (`src/server/Services/DataService.luau`)
- Con control: R2 golpear, B rodar, R3 fijar, Y escanear
- En celular: botones GOLPEAR (déjalo apretado para el giro), Rodar, Fijar y Escanear junto
  al de saltar (`src/client/UI/TouchButtons.luau`)
- Sonidos vacíos en `src/shared/Config/Sounds.luau`, para que pongas los que te gusten

- **Selva Brumosa**, la primera isla (`src/server/Zones/Selva.luau`): su portal en Puerto Eco ya
  tiene energía. Camino de lodo con máquinas, niebla verde y el **Templo de raíces**:
  1. Sala de combate: la puerta se abre al romper todas las máquinas
  2. Placa con tiempo: párate en ella y corre a la puerta en 7 segundos
  3. Gran cofre con el poder de **Empuje** (E / L2 / botón "Empuje") y un bloque que hay que
     empujar sobre la placa (si se atora, la palanca dorada lo regresa)
  4. Pared agrietada (rómpela con Empuje) que esconde la llave del jefe
  5. **Gusano de chatarra gigante** (`src/server/Bosses/Worm.luau`): sale de la tierra donde
     ves el círculo café y se lanza contra ti. Su armadura aguanta el bastón: túmbalo con
     Empuje y pégale mientras está en el piso. Suelta el **núcleo de la selva** y un portal de
     regreso
  - El templo se vuelve a cerrar si nadie está en la selva por un minuto
- El **pedestal** de la plaza enciende un hueco por cada núcleo que tengas
- Puertas, placas, bloques y paredes agrietadas: `src/server/Puzzles.luau`

Lo que sigue: tienda y taller de Chispa (gastar cristales), revivir a un amigo en co-op y la
segunda isla, el Volcán Brasa.

## Cómo probarlo

En PowerShell, dentro de la carpeta del proyecto:

```powershell
rokit install
rojo serve
```

En Roblox Studio abre un lugar vacío (Baseplate), y en el plugin de Rojo dale **Connect**. Borra
el Baseplate de Workspace y dale **Play** (F5).

Para publicar:

```powershell
rojo build -o expedicion-cero.rbxl
```

Abre `expedicion-cero.rbxl` en Studio y publícalo.

Guía para aprender cómo funciona el código: `docs/aprende/01-como-funciona.md`.
