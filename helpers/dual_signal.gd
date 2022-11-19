class_name DualSignal extends RefCounted

signal dual_signal
func _init(a:Signal, b:Signal)->void:
	var c = emit_signal.bind(&"dual_signal")
	a.connect(c)
	b.connect(c)
