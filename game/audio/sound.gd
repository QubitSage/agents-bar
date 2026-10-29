extends AudioStreamPlayer

func play_cue(kind: String) -> void:
	var frequencies: Array=[440.0,554.37,659.25] if kind=="victory" else ([330.0,220.0] if kind=="defeat" else [330.0,440.0])
	var samples_per_note:=2400
	var data:=PackedByteArray()
	data.resize(frequencies.size()*samples_per_note*2)
	for note in range(frequencies.size()):
		for sample in range(samples_per_note):
			var envelope: float=sin(PI*float(sample)/samples_per_note)
			var value:=int(sin(TAU*frequencies[note]*sample/24000.0)*envelope*1900)
			data.encode_s16((note*samples_per_note+sample)*2,value)
	var tone:=AudioStreamWAV.new()
	tone.format=AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate=24000
	tone.stereo=false
	tone.data=data
	stream=tone
	play()
