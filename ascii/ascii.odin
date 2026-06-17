package ascii

import "../terrain"

import "core:fmt"
import tansi "core:terminal/ansi"

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

draw :: proc(t: terrain.Map) {
	for _, i in t.tiles {
		switch t.tiles[i] {
		case 0 ..= 50:
			fmt.printf(ansi.blue + "~ " + ansi.reset)

		case 51 ..= 150:
			fmt.printf(ansi.lightGreen + "= " + ansi.reset)

		case 151 ..= 200:
			fmt.printf(ansi.darkGreen + "T " + ansi.reset)

		case 201 ..= 250:
			fmt.printf(ansi.yellow + "^ " + ansi.reset)
		}

		if cast(u64)(i + 1) % t.width == 0 {
			fmt.printf("\n")
		}
	}
}
