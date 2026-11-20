# Expedición Cero

Aventura de acción en tercera persona para Roblox, de 1 a 4 jugadores, en un **mundo de
portales**. Desde el Nexo saltas a mundos de distintos tipos de juego con tu dron compañero
**Chispa** y tu bastón de energía, buscando las **7 llaves** que cambian de lugar cada temporada
(2 semanas). Quien junta las 7 es **Leyenda**. Es el tercer juego de la serie "Cero", después
de Escuadrón Cero y Frecuencia Cero.

Diseño (mundo de portales): https://claude.ai/artifact/QMSP35w4wRHy4pg7s1S5eV
(el primero, de cuando eran 4 islas: https://claude.ai/artifact/GYB3zhAxfYH2UVzHY8XDz4)

## Qué hay

- **El Nexo**, la isla central en estilo caricatura: mar, playa, palmeras, la plaza con el
  pedestal de las 7 llaves y el tablero de la temporada, un anillo de **9 portales** (por ahora
  solo abre la Selva Brumosa), el **Salón de Leyendas**, la tienda y el taller de Chispa y el
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
     Empuje y pégale mientras está en el piso. Suelta muchos cristales y un portal de regreso
  - El templo se vuelve a cerrar si nadie está en la selva por un minuto
- **Las 7 llaves** (`src/server/Services/KeyService.luau`, `src/shared/Config/Keys.luau`):
  - cada temporada de 2 semanas cambian de mundo y de escondite (igual en todos los servidores)
  - **R**: Chispa dice si hay una llave cerca (frío, tibio o caliente; con el escáner del
    taller, también hacia dónde)
  - el pedestal del Nexo enciende un hueco por cada llave tuya
  - con las 7 eres **Leyenda**: nombre en el Salón de Leyendas (los 3 primeros con estatua),
    título y aura dorada
  - en Studio, Output dice dónde quedó cada llave (para probar)
- Puertas, placas, bloques y paredes agrietadas: `src/server/Puzzles.luau`

- **Tienda** (B, o el aviso de su puerta) y **Taller de Chispa** (T) para gastar cristales
  (`src/client/UI/Shop.luau`, `src/server/Services/ShopService.luau`, precios en
  `src/shared/Config/Shop.luau`):
  - Tienda: **bastón reforzado** (3 niveles, +15% de daño cada uno) y **contenedores de
    corazón** (2)
  - Taller: **rayito** más fuerte, **recarga** más rápida, **imán** de cristales y
    **escáner** de largo alcance
- **Robux** (pestaña de la tienda, `src/server/Services/StoreService.luau`,
  `src/shared/Config/Store.luau`): pases **Cristales x2** y **VIP** (Chispa y el bastón
  dorados, un corazón extra) y bolsas de cristales. Hasta que pongas los números (id), dicen
  "Pronto"; en Studio sale "Probar" para dártelos gratis
- **Salas privadas** (botón SALAS, `src/server/Services/RoomService.luau`): crea una sala y
  pásale el código de 6 números a tus amigos. Tu progreso va contigo. Solo funciona en el juego
  publicado
- **Música** por lugar (Puerto Eco, la selva y el jefe) en `src/shared/Config/Music.luau`
  (0 = sin música) (`src/client/Music.luau`)
- En celular, la tienda, el taller y las salas están en el botón MENÚ de arriba a la derecha

Lo que sigue (semanas 6 a 8): Volcán Brasa y Arena del Óxido, Pista Neón y Mansión Eco, y
Glaciar, Ruinas, Laberinto, Píxel y el mundo secreto. Luego publicar.

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

Abre `expedicion-cero.rbxl` en Studio y publícalo. Pasos completos, ícono y miniatura en `docs/publicar/`.

Guía para aprender cómo funciona el código: `docs/aprende/01-como-funciona.md`.
