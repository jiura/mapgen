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

COLOR_WARM_BEACH :: rl.Color{240, 225, 170, 255}
COLOR_COLD_BEACH :: rl.Color{180, 190, 200, 255}

COLOR_TUNDRA :: rl.Color{175, 185, 165, 255}

COLOR_GRASSLAND :: rl.Color{145, 185, 95, 255}
COLOR_FOREST :: rl.Color{55, 130, 75, 255}
COLOR_SWAMP :: rl.Color{45, 105, 95, 255}

COLOR_DESERT :: rl.Color{220, 170, 80, 255} // Maybe this could be the same as warm beach
COLOR_SAVANNA :: rl.Color{190, 165, 85, 255}
COLOR_RAINFOREST :: rl.Color{15, 95, 45, 255}

COLOR_MOUNTAIN :: rl.Color{112, 73, 11, 255}
COLOR_COLD_MOUNTAIN :: rl.Color{200, 205, 210, 255}
COLOR_WARM_MOUNTAIN :: rl.Color{140, 145, 150, 255}
COLOR_HOT_MOUNTAIN :: rl.Color{120, 90, 60, 255}

getTileRayLibColor :: proc(elevation, temperature, humidity: f32) -> rl.Color {
	DEEP := elevation < 0.25
	SEA_LEVEL := !DEEP && elevation < 0.40
	COAST := !DEEP && !SEA_LEVEL && elevation < 0.45
	HIGH := elevation >= 0.85

	COLD := temperature < 0.3
	WARM := !COLD && temperature < 0.7
	HOT := temperature >= 0.7

	DRY := humidity < 0.3
	TEMPERATE := !DRY && humidity < 0.6
	HUMID := humidity >= 0.6

	if DEEP {
		return COLOR_DEEP_OCEAN
	}

	if SEA_LEVEL {
		return COLOR_OCEAN
	}

	if COAST {
		if COLD {
			return COLOR_COLD_BEACH
		}

		return COLOR_WARM_BEACH
	}

	if HIGH {
		if COLD {
			return COLOR_COLD_MOUNTAIN
		}

		if WARM {
			return COLOR_WARM_MOUNTAIN
		}

		return COLOR_HOT_MOUNTAIN
	}

	if COLD {
		if humidity < 0.5 {
			return COLOR_TUNDRA
		}

		return COLOR_FOREST
	}

	if WARM {
		if humidity < 0.3 {
			return COLOR_GRASSLAND
		}

		if humidity < 0.8 {
			return COLOR_FOREST
		}

		return COLOR_SWAMP
	}

	if DRY {
		return COLOR_DESERT
	}

	if TEMPERATE {
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

	zoomElevation: f64 = 0.02
	zoomTemperature: f64 = 0.01
	zoomHumidity: f64 = 0.01

	for x: u64 = 0; x < _map.width; x += 1 {
		for y: u64 = 0; y < _map.height; y += 1 {
			e := getNoiseValForXY(seedElevation, zoomElevation, x, y)
			append(&_map.elevation, e)

			t := getNoiseValForXY(seedTemperature, zoomTemperature, x, y)
			append(&_map.temperature, t)

			h := getNoiseValForXY(seedHumidity, zoomHumidity, x, y)
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
				tileColor := getTileRayLibColor(
					_map.elevation[i],
					_map.temperature[i],
					_map.humidity[i],
				)

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
