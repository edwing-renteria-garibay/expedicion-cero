# Publicar Expedición Cero

En esta carpeta están el **ícono** (`icono.png`, 512×512) y la **miniatura** (`miniatura.png`,
1920×1080). Se dibujaron con `icono.html` y `miniatura.html` (las piezas comunes están en
`defs.svg.part`), así se pueden cambiar después.

## 1. Armar el archivo

En PowerShell, dentro de la carpeta del proyecto:

```powershell
git pull
rojo build -o expedicion-cero.rbxl
```

Abre `expedicion-cero.rbxl` en Studio (doble clic).

## 2. Publicar

1. Archivo > **Publicar en Roblox como...** > **Crear una experiencia nueva**.
2. Nombre: **Expedición Cero**.
3. Descripción (copia y pega):

   > ¡Explora el Archipiélago Eco con Chispa, tu dron compañero! El Óxido robó los núcleos de
   > energía de las islas: recupéralos con tu bastón de energía.
   >
   > ⚔️ Combos, giro cargado, rodar y fijar enemigos
   > 🤖 Chispa escanea enemigos y cofres escondidos y dispara su rayito
   > 🌴 Selva Brumosa: templo con puzzles y el Gusano de chatarra gigante
   > 💎 Junta cristales y mejora tu bastón y a Chispa en la tienda y el taller
   > 👥 De 1 a 4 jugadores, con salas privadas para tus amigos
   >
   > ¡Nuevas islas pronto: Volcán Brasa, Glaciar Silencio y Ruinas del Cielo!

4. Género: **Aventura**. Dispositivos: computadora, celular, tableta y consola.
5. Dale **Crear**.

## 3. Ajustes en Studio (Inicio > Configuración del juego)

- **Seguridad**: activa **Permitir que Studio acceda a los servicios de API** (para que
  funcione el guardado al probar el juego publicado).
- **Lugares** > el lugar > **Jugadores máximos: 4**.
- Guarda y vuelve a publicar: Archivo > **Publicar en Roblox** (Alt+P).

## 4. En el Creator Hub (create.roblox.com)

1. Tu experiencia > **Lugares / Información básica**: sube `icono.png` como ícono.
2. **Miniaturas**: sube `miniatura.png`.
3. **Cuestionario de madurez**: contesta con la verdad (combate de caricatura contra
   máquinas, sin sangre). Debería quedar para todas las edades o 9+.
4. **Monetización**:
   - **Pases**: crea "Cristales x2" (199 Robux) y "VIP" (299 Robux).
   - **Productos para desarrolladores**: "Bolsa de cristales" (49 Robux) y "Cofre de
     cristales" (149 Robux).
   - Copia el número de cada uno en `src/shared/Config/Store.luau` (donde dice `id = 0`),
     vuelve a armar el archivo y a publicar.
5. **Música** (opcional): busca canciones en Studio, Caja de herramientas > Audio, y pon sus
   números en `src/shared/Config/Music.luau`.
6. Cuando ya la probaste publicada, en **Acceso** ponla **Pública**.

## Cada vez que cambies algo

```powershell
git pull
rojo build -o expedicion-cero.rbxl
```

Abre el archivo nuevo y en Studio: Archivo > **Publicar en Roblox** (ya va a la misma
experiencia). Si te pregunta, elige **Actualizar la experiencia actual**.
