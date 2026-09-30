extends Node
## Small original synthesized effects, cached at startup. No external assets.
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var muted := false

func _ready() -> void:
	for i in range(12):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -13
		add_child(voice)
		voices.append(voice)
	sounds["shot"] = tone(0.09, 850, 220, 0.08)
	sounds["hit"] = tone(0.07, 180, 65, 0.55)
	sounds["break"] = tone(0.22, 110, 30, 0.8)
	sounds["jump"] = tone(0.1, 160, 420, 0.0)
	sounds["dash"] = tone(0.12, 380, 80, 0.5)
	sounds["hurt"] = tone(0.2, 170, 70, 0.25)
	sounds["checkpoint"] = tone(0.35, 440, 880, 0.0)

func play(effect: String) -> void:
	if muted or not sounds.has(effect):
		return
	var voice: AudioStreamPlayer = voices[cursor]
	voice.stream = sounds[effect]
	voice.play()
	cursor = (cursor + 1) % voices.size()

func tone(duration: float, start: float, finish: float, noise: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var random := RandomNumberGenerator.new()
	random.seed = int(start)
	for i in range(count):
		var t := float(i) / count
		phase += TAU * lerpf(start, finish, t) / sample_rate
		var wave := sin(phase) * (1.0 - noise) + random.randf_range(-1, 1) * noise
		var envelope := minf(1.0, float(i) / 70) * pow(1.0 - t, 2)
		bytes.encode_s16(i * 2, int(wave * envelope * 17000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
