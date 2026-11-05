# 04. Tienda, Robux, salas y música

## Gastar cristales: quién decide

Cuando compras en la tienda, tu pantalla (`client/UI/Shop.luau`) solo **pide** la compra:

```lua
shopRemote:FireServer("buy", "Baston")
```

El servidor (`server/Services/ShopService.luau`) revisa todo antes de dar nada: que la mejora
exista, que no esté al máximo y que te alcancen los cristales (`DataService.Spend`). Así nadie
puede hacer trampa desde su pantalla. Luego sube el nivel (`DataService.Upgrade`) y lo publica
como atributo del jugador: `Mejora_Baston = 1`.

Cada parte del juego lee ese atributo para aplicar la mejora:

| Mejora | Dónde se usa |
| --- | --- |
| `Mejora_Baston` | `StaffService` (daño del golpe) |
| `Mejora_Rayo`, `Mejora_Recarga` | `StaffService` (el rayito de Chispa) |
| `Mejora_Iman` | `Pickups` (desde qué tan lejos vienen los cristales) |
| `Mejora_Escaner` | `client/Chispa` (alcance del escaneo) |

Para cambiar precios o lo que da cada nivel, edita `src/shared/Config/Shop.luau`. Para agregar
una mejora nueva: ponla en `Shop.items`, agrégala a `Shop.order`, y lee su atributo donde
haga efecto.

## Robux

1. Publica el juego.
2. En el Creator Hub, crea los pases (Cristales x2 y VIP) y los productos (bolsas de cristales).
3. Copia cada número (id) en `src/shared/Config/Store.luau`.

Los **pases** se compran una vez: `StoreService.CheckPasses` le pregunta a Roblox al entrar y
pone `Pass_x2` o `Pass_VIP`. Los **productos** se compran muchas veces: Roblox llama a
`ProcessReceipt`, se entregan los cristales y se guarda el recibo para no darlos dos veces.

## Salas privadas

`RoomService` reserva un servidor (`TeleportService:ReserveServer`) y guarda su código de 6
números unas horas en `MemoryStoreService`. Antes de mandarte a otro servidor guarda tu
progreso (`DataService.SaveNow`), así llegas con todo. En Studio no se puede probar.

## Música

`client/Music.luau` revisa cada segundo dónde estás: Puerto Eco, una isla o cerca de un jefe.
Cuando cambia, una canción baja poco a poco y la otra sube (TweenService con `Volume`).
Busca canciones en Studio: Caja de herramientas > Audio, copia el número y ponlo en
`src/shared/Config/Music.luau`.
