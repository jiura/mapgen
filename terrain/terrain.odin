package terrain

Map :: struct {
	width, height: u64,
	elevation:     [dynamic]f32,
	temperature:   [dynamic]f32,
	humidity:      [dynamic]f32,
}
