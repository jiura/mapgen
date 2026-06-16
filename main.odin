/* TODO:
   - Generate a map with Simplex from core:math/noise - DONE
   - Draw it using simple chars first - DONE with colors :)
   - Draw it using RayLib - DONE
   - Generate random seed - DONE
   - Make map size unrelated to screen size and zoomable
   - Maybe a small squary guy that can walk around the map could be fun
   - Adapt it to use either own implementation of Perlin or Simplex from core:math/noise
*/

package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:math/rand"
import tansi "core:terminal/ansi"

import rl "vendor:raylib"

TerrainMap :: struct {
	width, height: u64,
	tiles:         [dynamic]u16,
}

AnsiConsts :: struct {
	blue, darkGreen, yellow, lightGreen, reset: string,
}

ansi :: AnsiConsts {
	blue       = tansi.CSI + tansi.FG_BLUE + tansi.SGR,
	darkGreen  = tansi.CSI + tansi.FG_COLOR_24_BIT + ";54;105;45" + tansi.SGR,
	yellow     = tansi.CSI + tansi.FG_YELLOW + tansi.SGR,
	lightGreen = tansi.CSI + tansi.FG_BRIGHT_GREEN + tansi.SGR,
	reset      = tansi.CSI + tansi.RESET + tansi.SGR,
}

drawASCII :: proc(terrain: TerrainMap) {
	for _, i in terrain.tiles {
		switch terrain.tiles[i] {
		case 0 ..= 50:
			fmt.printf(ansi.blue + "~ " + ansi.reset)

		case 51 ..= 150:
			fmt.printf(ansi.lightGreen + "= " + ansi.reset)

		case 151 ..= 200:
			fmt.printf(ansi.darkGreen + "T " + ansi.reset)

		case 201 ..= 250:
			fmt.printf(ansi.yellow + "^ " + ansi.reset)
		}

		if cast(u64)(i + 1) % terrain.width == 0 {
			fmt.printf("\n")
		}
	}
}

getTileRayLibColor :: proc(tileVal: u16) -> rl.Color {
	switch tileVal {
	case 0 ..= 149:
		// Water
		return RL_BLUE

	case 150 ..= 749:
		// Plains
		return RL_LGREEN

	case 750 ..= 874:
		// Forest
		return RL_DGREEN

	case 875 ..= 1000:
		// Mountains
		fallthrough
	case:
		return RL_BROWN
	}
}

RL_BLUE :: rl.Color{40, 157, 235, 255}
RL_LGREEN :: rl.Color{114, 212, 145, 255}
RL_DGREEN :: rl.Color{42, 115, 15, 255}
RL_BROWN :: rl.Color{112, 73, 11, 255}

main :: proc() {
	terrain := TerrainMap {
		width  = 250,
		height = 250,
	}
	terrain.tiles = make([dynamic]u16, 0, terrain.width * terrain.height)
	defer delete(terrain.tiles)

	// seed: i64 = 20_110_920
	seed: i64 = rand.int64_range(min(i64), max(i64))
	zoomFactor: f64 = 10.0

	for x: u64 = 0; x < terrain.width; x += 1 {
		for y: u64 = 0; y < terrain.height; y += 1 {
			noiseVal := noise.noise_2d_improve_x(
				seed,
				{cast(f64)x / zoomFactor, cast(f64)y / zoomFactor},
			) // TODO: Ensure I want "improve_x"

			append(&terrain.tiles, cast(u16)(((noiseVal + 1.0) / 2.0) * 1000.0))
		}
	}

	// drawASCII(terrain)

	screenWidth: c.int = 1920
	screenHeight: c.int = 1080

	tileWidth := cast(u64)math.ceil(cast(f64)screenWidth / cast(f64)terrain.width)
	tileHeight := cast(u64)math.ceil(cast(f64)screenHeight / cast(f64)terrain.height)
	// tileWidth: u64 = 32
	// tileHeight: u64 = 32

	rl.InitWindow(screenWidth, screenHeight, "raylib log callback")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		for _, i in terrain.tiles {
			tileColor := getTileRayLibColor(terrain.tiles[i])

			rl.DrawRectangle(
				posX = cast(c.int)(tileWidth * (cast(u64)i % terrain.width)),
				posY = cast(c.int)(tileHeight * (cast(u64)i / terrain.width)),
				width = cast(c.int)tileWidth,
				height = cast(c.int)tileHeight,
				color = tileColor,
			)
		}

		rl.EndDrawing()
	}
}
