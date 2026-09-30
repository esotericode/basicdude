extends RefCounted

const COLORS := {
	"o": Color("152631"), "d": Color("277e83"), "t": Color("51c9bd"),
	"h": Color("a5f4cf"), "v": Color("e8ffe2"), "a": Color("efa35f"),
	"r": Color("a75950"), "b": Color("623f48"), "p": Color("da6f86"),
	"w": Color("ffd4b0"), "s": Color("465663"), "l": Color("718391"),
}
const HERO := [
	"....oooo....", "...otttto...", "..otthhhho..", "..otvvvvvo..",
	"..otvvvvvo..", "...otttto...", "..oodddoo...", ".ottttthto..",
	".ottttthtooo", ".odttttdaoaa", "..oddddooaaa", "..otddtooooo",
	"..otddto....", "..od..do....", "..od..do....", ".ooo..ooo...",
]
const WALKER := [
	"..............", "..oo......oo..", ".oppo....oppo.", ".opppoooopppo.",
	".oppppppppppo.", "ooppppppppppoo", "obppwwwwppppbo", "obppwwwwppppbo",
	"obppppppppppbo", ".obppppppppbo.", "..obbbbbbbbo..", "..oo......oo..",
	".opo......opo.", ".ooo......ooo.",
]
const DRONE := [
	"...ss....ss...", "..slls..slls..", ".ssllssssllss.", "sllllpppplllls",
	"sllpppppppplls", ".sppwwwwwwpps.", "..ppwwwwwwpp..", "..bppppppppb..",
	"...bbbbbbbb...", ".....pppp.....", "......ww......",
]
const CRATE := [
	"ssssssssssssssss",
	"saaaaaaaaaaaaaas",
	"sawrrrrrrrrrrwas",
	"sararrrrrrrraras",
	"sarrarrrrrrarras",
	"sarrrarrrrarrras",
	"sarrrrarrarrrras",
	"sarrrrraarrrrras",
	"sarrrrraarrrrras",
	"sarrrrarrarrrras",
	"sarrrarrrrarrras",
	"sarrarrrrrrarras",
	"sararrrrrrrraras",
	"sawrrrrrrrrrrwas",
	"saaaaaaaaaaaaaas",
	"ssssssssssssssss",
]
const CORE := [
	"....ssssssss....", "..ssllllllllss..", ".sllsssssssslls.", "slssppppppppssls",
	"slspwwwwwwwwpsls", "slspwppppppwpsls", "slspwpwwwwpwpsls", "slspwpwvvwpwpsls",
	"slspwpwvvwpwpsls", "slspwpwwwwpwpsls", "slspwppppppwpsls", "slspwwwwwwwwpsls",
	"slssppppppppssls", ".sllsssssssslls.", "..ssllllllllss..", "....ssssssss....",
]

static func draw_hero(canvas: CanvasItem, facing: int, frame: int, airborne: bool, flash: bool) -> void:
	for y in range(HERO.size()):
		for x in range(HERO[y].length()):
			var cell: String = HERO[y][x]
			if cell == ".":
				continue
			var offset := Vector2(x * 2 - 12, y * 2 - 32)
			if y >= 13:
				if airborne:
					offset.y -= 2
					offset.x += -2 if x < 5 else 2
				elif frame % 2 == 1:
					offset.x += -2 if x < 5 else 2
			if facing < 0:
				offset.x = -offset.x - 2
			canvas.draw_rect(Rect2(offset, Vector2(2, 2)), Color("ffffff") if flash else COLORS[cell])

static func shadow(canvas: CanvasItem, width: float) -> void:
	canvas.draw_rect(Rect2(-width / 2, -1, width, 2), Color(0, 0, 0, 0.28))
