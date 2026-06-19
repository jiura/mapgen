/* TODO:
   - Make map size unrelated to screen size and zoomable
   - Maybe a small squary guy that can walk around the map could be fun
   - Adapt it to use either own implementation of Perlin or Simplex from core:math/noise
*/

package main

import "terrain"

import "core:c"
import "core:math"
import "core:math/noise"
import "core:math/rand"

import rl "vendor:raylib"

/* RAYLIB COLORS */
COLOR_DEEP_OCEAN :: rl.Color{20, 40, 120, 255}
COLOR_OCEAN :: rl.Color{40, 80, 180, 255}
COLOR_BEACH :: rl.Color{235, 215, 125, 255}

COLOR_TUNDRA :: rl.Color{175, 185, 165, 255}
COLOR_GRASSLAND :: rl.Color{145, 185, 95, 255}
COLOR_FOREST :: rl.Color{55, 130, 75, 255}
COLOR_SWAMP :: rl.Color{45, 105, 95, 255}

COLOR_DESERT :: rl.Color{235, 215, 125, 255}
COLOR_SAVANNA :: rl.Color{190, 165, 85, 255}
COLOR_RAINFOREST :: rl.Color{15, 95, 45, 255}

COLOR_MOUNTAIN :: rl.Color{112, 73, 11, 255}

getTileRayLibColor :: proc(elevation, temperature, humidity: f32) -> rl.Color {
	if elevation < 0.25 {
		return COLOR_DEEP_OCEAN
	}

	if elevation < 0.40 {
		return COLOR_OCEAN
	}

	if elevation < 0.45 {
		return COLOR_BEACH
	}

	if elevation > 0.85 {
		return COLOR_MOUNTAIN
	}

	/* COLD */
	if temperature < 0.3 {
		if humidity < 0.5 {
			return COLOR_TUNDRA
		}

		return COLOR_FOREST
	}

	/* MILD */
	if temperature < 0.7 {
		if humidity < 0.3 {
			return COLOR_GRASSLAND
		}

		if humidity < 0.8 {
			return COLOR_FOREST
		}

		return COLOR_SWAMP
	}

	/* BRAZIL */
	if humidity < 0.3 {
		return COLOR_DESERT
	}

	if humidity < 0.6 {
		return COLOR_SAVANNA
	}

	return COLOR_RAINFOREST
}

noise2d :: proc(seed: i64, x: f64, y: f64) -> f32 {
	// TODO: Check if noise_2d_improve_x() is better
	noiseVal := noise.noise_2d(seed, {x, y})
	normalized := (noiseVal + 1.0) / 2.0

	return normalized
}

getNoiseValForXY :: proc(seed: i64, zoomFactor: f64, x, y: u64) -> f32 {
	val :=
		1 * noise2d(seed, zoomFactor * 1 * cast(f64)x, zoomFactor * 1 * cast(f64)y) +
		0.5 * noise2d(seed, zoomFactor * 2 * cast(f64)x, zoomFactor * 2 * cast(f64)y) +
		0.25 * noise2d(seed, zoomFactor * 4 * cast(f64)x, zoomFactor * 4 * cast(f64)y)

	return val / (1 + 0.5 + 0.25)
}

main :: proc() {
	_map := terrain.Map {
		width  = 250,
		height = 250,
	}

	_map.elevation = make([dynamic]f32, 0, _map.width * _map.height)
	defer delete(_map.elevation)

	_map.temperature = make([dynamic]f32, 0, _map.width * _map.height)
	defer delete(_map.temperature)

	_map.humidity = make([dynamic]f32, 0, _map.width * _map.height)
	defer delete(_map.humidity)

	seedElevation: i64 = rand.int64_range(min(i64), max(i64))
	seedTemperature: i64 = rand.int64_range(min(i64), max(i64))
	seedHumidity: i64 = rand.int64_range(min(i64), max(i64))

	zoomFactor: f64 = 0.05

	for x: u64 = 0; x < _map.width; x += 1 {
		for y: u64 = 0; y < _map.height; y += 1 {
			e := getNoiseValForXY(seedElevation, zoomFactor, x, y)
			append(&_map.elevation, e)

			t := getNoiseValForXY(seedTemperature, zoomFactor, x, y)
			append(&_map.temperature, t)

			h := getNoiseValForXY(seedHumidity, zoomFactor, x, y)
			append(&_map.humidity, h)
		}
	}

	screenWidth: c.int = 1920
	screenHeight: c.int = 1080

	tileWidth := cast(u64)math.ceil(cast(f64)screenWidth / cast(f64)_map.width)
	tileHeight := cast(u64)math.ceil(cast(f64)screenHeight / cast(f64)_map.height)

	rl.InitWindow(screenWidth, screenHeight, "raylib log callback")
	defer rl.CloseWindow()

	DisplayMode :: enum {
		Map,
		NoiseMap,
		MoistureMap,
	}

	displayMode := DisplayMode.Map
	for !rl.WindowShouldClose() {
		/* INPUT */
		if (rl.IsKeyPressed(rl.KeyboardKey.Z)) {
			displayMode = .Map
		}
		if (rl.IsKeyPressed(rl.KeyboardKey.X)) {
			displayMode = .NoiseMap
		}
		if (rl.IsKeyPressed(rl.KeyboardKey.C)) {
			displayMode = .MoistureMap
		}

		/* DRAW */
		rl.BeginDrawing()

		switch (displayMode) {
		case .Map:
			for _, i in _map.elevation {
				tileColor := getTileRayLibColor(_map.elevation[i], _map.temperature[i], _map.humidity[i])

				rl.DrawRectangle(
					posX = cast(c.int)(tileWidth * (cast(u64)i % _map.width)),
					posY = cast(c.int)(tileHeight * (cast(u64)i / _map.width)),
					width = cast(c.int)tileWidth,
					height = cast(c.int)tileHeight,
					color = tileColor,
				)
			}

		case .NoiseMap:
			for _, i in _map.elevation {
				luminosity := cast(u8)(_map.elevation[i] * 255)
				rl.DrawRectangle(
					posX = cast(c.int)(tileWidth * (cast(u64)i % _map.width)),
					posY = cast(c.int)(tileHeight * (cast(u64)i / _map.width)),
					width = cast(c.int)tileWidth,
					height = cast(c.int)tileHeight,
					color = rl.Color{luminosity, luminosity, luminosity, 255},
				)
			}

		case .MoistureMap:
			for _, i in _map.elevation {
				luminosity := cast(u8)(_map.humidity[i] * 255)
				rl.DrawRectangle(
					posX = cast(c.int)(tileWidth * (cast(u64)i % _map.width)),
					posY = cast(c.int)(tileHeight * (cast(u64)i / _map.width)),
					width = cast(c.int)tileWidth,
					height = cast(c.int)tileHeight,
					color = rl.Color{luminosity, luminosity, luminosity, 255},
				)
			}
		}

		rl.EndDrawing()
	}
}
