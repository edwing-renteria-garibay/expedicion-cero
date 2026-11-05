# Expedición Cero

Aventura de acción en tercera persona para Roblox, de 1 a 4 jugadores. Eres un explorador del
Cuerpo Cero y, con tu dron compañero **Chispa** y tu bastón de energía, recuperas los cuatro
núcleos que el Óxido robó del Archipiélago Eco. Es el tercer juego de la serie "Cero", después
de Escuadrón Cero y Frecuencia Cero.

Documento de diseño: https://claude.ai/artifact/GYB3zhAxfYH2UVzHY8XDz4

## Qué hay (semana 1)

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
- Con control: R2 golpear, B rodar, R3 fijar, Y escanear
- Sonidos vacíos en `src/shared/Config/Sounds.luau`, para que pongas los que te gusten

Lo que sigue (semana 2): enemigos del Óxido, cristales, corazones, guardado y botones de celular.

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
