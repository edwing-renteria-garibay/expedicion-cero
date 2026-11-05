# 01. Cómo funciona Expedición Cero

Esta guía explica por dónde empezar a leer el código y cómo cambiar cosas sin miedo.

## Servidor y cliente

Roblox tiene dos lados:

- **El servidor** (`src/server`) es uno solo para todos los jugadores. Arma el mapa, decide
  cuánto daño hace cada golpe y lleva la vida de los enemigos. Lo que hace el servidor lo ven
  todos.
- **El cliente** (`src/client`) corre en la computadora o celular de cada jugador. Lee el
  teclado, mueve la cámara, dibuja la interfaz y anima.

Se hablan con **RemoteEvents** (están en `default.project.json`, dentro de `Remotes`):

| Remote | Quién lo manda | Para qué |
| --- | --- | --- |
| `Attack` | cliente → servidor | "golpeé con este golpe hacia esta dirección" |
| `Dodge` | cliente → servidor | "rodé" (el servidor te hace invencible un momento) |
| `Fx` | servidor → clientes | daño, golpes de otros, el rayito de Chispa, frases |

## Un golpe, paso a paso

1. Haces clic. `src/client/Staff.luau` decide qué golpe del combo toca (1, 2, 3) y voltea a
   tu personaje hacia la cámara (o hacia el enemigo fijado).
2. Tu pantalla anima el golpe al momento con `src/client/Swing.luau`, así se siente rápido.
3. Le manda al servidor `Attack` con el golpe y la dirección.
4. `src/server/Services/StaffService.luau` revisa que no estés golpeando demasiado rápido
   (para que nadie haga trampa), busca enemigos enfrente y cerca, y les quita vida.
5. El servidor avisa a todos con `Fx`: salen chispas y el número de daño, y los demás jugadores
   ven tu animación.

## Las animaciones sin subir nada

No usamos animaciones subidas a Roblox: `Swing.luau` gira el hombro del personaje (un
`Motor6D`) poco a poco cada cuadro. Cada golpe tiene una pose de inicio y una de final
(`yaw` = hacia los lados, `pitch` = hacia arriba). Cambia esos números para que el golpe se vea
distinto.

## Para cambiar cosas fáciles

| Quieres cambiar | Archivo |
| --- | --- |
| Daño, alcance o velocidad del bastón | `src/shared/Config/Staff.luau` |
| Lo que dice Chispa, el daño de su rayito, el escaneo | `src/shared/Config/Drone.luau` |
| Sonidos | `src/shared/Config/Sounds.luau` |
| El mapa: portales, casas, árboles | `src/server/World.luau` |
| Vida de los muñecos | `src/server/Dummies.luau` (`HEALTH`) |
| Colores del cielo y la luz | `default.project.json`, sección `Lighting` |

## Etiquetas

- `Enemy`: todo lo que el bastón puede golpear, lo que Chispa escanea y lo que puedes fijar.
  Los muñecos la tienen; los enemigos de la semana 2 también la tendrán.
- `Pista`: piezas invisibles que hacen hablar a Chispa al acercarte. Su atributo `Pista` es el
  nombre de la frase en `Config/Drone.luau` y `Radio` qué tan cerca hay que llegar.

## Ejercicio

Abre `Config/Staff.luau` y cambia el `damage` del "Remate" a 100. Dale Play, ve al campo de
práctica y haz el combo: el tercer golpe debe romper el muñeco casi de un solo golpe.
