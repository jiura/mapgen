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

RL_BLUE :: rl.Color{40, 157, 235, 255}
RL_LGREEN :: rl.Color{114, 212, 145, 255}
RL_DGREEN :: rl.Color{42, 115, 15, 255}
RL_BROWN :: rl.Color{112, 73, 11, 255}

getTileRayLibColor :: proc(terrain: f32, moisture: f32) -> rl.Color {
	WATER :: 0.4
	PLAINS :: 0.6
	FOREST :: 0.9

	if (terrain < WATER) {return RL_BLUE}

	if (moisture < PLAINS) {return RL_LGREEN}
	if (moisture < FOREST) {return RL_DGREEN}

	return RL_BROWN
}

noise2d :: proc(seed: i64, x: f64, y: f64) -> f32 {
	// TODO: Check if noise_2d_improve_x() is better
	noiseVal := noise.noise_2d(seed, {x, y})
	normalized := (noiseVal + 1.0) / 2.0

	return normalized
}

main :: proc() {
	_map := terrain.Map {
		width  = 250,
		height = 250,
	}
	_map.tiles = make([dynamic]f32, 0, _map.width * _map.height)
	_map.moisture = make([dynamic]f32, 0, _map.width * _map.height)
	defer delete(_map.tiles)

	seed: i64 = rand.int64_range(min(i64), max(i64))
	seedMoisture: i64 = rand.int64_range(min(i64), max(i64))
	zoomFactor: f64 = 0.05

	for x: u64 = 0; x < _map.width; x += 1 {
		for y: u64 = 0; y < _map.height; y += 1 {
			noise :=
				1 * noise2d(seed, zoomFactor * 1 * cast(f64)x, zoomFactor * 1 * cast(f64)y) +
				0.5 * noise2d(seed, zoomFactor * 2 * cast(f64)x, zoomFactor * 2 * cast(f64)y) +
				0.25 * noise2d(seed, zoomFactor * 4 * cast(f64)x, zoomFactor * 4 * cast(f64)y)
			noise = noise / (1 + 0.5 + 0.25)
			append(&_map.tiles, noise)

			moisture :=
				1 *
					noise2d(
						seedMoisture,
						zoomFactor * 1 * cast(f64)x,
						zoomFactor * 1 * cast(f64)y,
					) +
				0.5 *
					noise2d(
						seedMoisture,
						zoomFactor * 2 * cast(f64)x,
						zoomFactor * 2 * cast(f64)y,
					) +
				0.25 *
					noise2d(seedMoisture, zoomFactor * 4 * cast(f64)x, zoomFactor * 4 * cast(f64)y)
			moisture = moisture / (1 + 0.5 + 0.25)
			append(&_map.moisture, moisture)
		}
	}

	screenWidth: c.int = 1920
	screenHeight: c.int = 1080

	tileWidth := cast(u64)math.ceil(cast(f64)screenWidth / cast(f64)_map.width)
	tileHeight := cast(u64)math.ceil(cast(f64)screenHeight / cast(f64)_map.height)

	rl.InitWindow(screenWidth, screenHeight, "raylib log callback")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		for _, i in _map.tiles {
			tileColor := getTileRayLibColor(_map.tiles[i], _map.moisture[i])

			rl.DrawRectangle(
				posX = cast(c.int)(tileWidth * (cast(u64)i % _map.width)),
				posY = cast(c.int)(tileHeight * (cast(u64)i / _map.width)),
				width = cast(c.int)tileWidth,
				height = cast(c.int)tileHeight,
				color = tileColor,
			)
		}

		rl.EndDrawing()
	}
}
