extends SceneTree
## project.godot ayarlarını (girdi haritası dahil) Godot'un kendi biçimiyle yazar.
##   godot --headless --path . -s res://tools/proje_ayarla.gd


func _initialize() -> void:
	var ps := ProjectSettings
	ps.set_setting("display/window/size/viewport_width", 640)
	ps.set_setting("display/window/size/viewport_height", 360)
	ps.set_setting("display/window/size/window_width_override", 1280)
	ps.set_setting("display/window/size/window_height_override", 720)
	ps.set_setting("display/window/stretch/mode", "canvas_items")
	ps.set_setting("display/window/stretch/aspect", "keep")
	ps.set_setting("display/window/handheld/orientation", 0)  # yatay
	ps.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	ps.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	ps.set_setting("rendering/textures/canvas_textures/default_texture_filter", 0)
	ps.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	ps.set_setting("rendering/environment/defaults/default_clear_color", Color("222034"))
	ps.set_setting("physics/common/physics_ticks_per_second", 60)
	ps.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	# Web'de ses "Sample" oynatma türüyle (itch.io'da çıtırtı olmasın); Android'de çevik girdi.
	ps.set_setting("audio/general/default_playback_type.web", 1)
	ps.set_setting("input_devices/buffering/agile_event_flushing", true)
	ps.set_setting("application/run/max_fps", 0)
	ps.set_setting("layer_names/2d_physics/layer_1", "dunya")
	ps.set_setting("layer_names/2d_physics/layer_2", "oyuncu")
	ps.set_setting("layer_names/2d_physics/layer_3", "tehlike_ve_altin")

	ps.set_setting("input/zipla", {"deadzone": 0.2, "events": [
		_tus(KEY_SPACE), _tus(KEY_W), _tus(KEY_UP), _joy(JOY_BUTTON_A), _joy(JOY_BUTTON_B)]})
	ps.set_setting("input/duraklat", {"deadzone": 0.2, "events": [
		_tus(KEY_ESCAPE), _tus(KEY_P), _joy(JOY_BUTTON_START)]})

	var e := ps.save()
	print("project.godot kaydedildi: ", e)
	quit(e)


func _tus(kod: Key) -> InputEventKey:
	var k := InputEventKey.new()
	k.physical_keycode = kod
	return k


func _joy(b: JoyButton) -> InputEventJoypadButton:
	var j := InputEventJoypadButton.new()
	j.button_index = b
	return j
