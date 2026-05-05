# HUD de tensión: actualiza la viñeta de peligro y sincroniza el latido con el nivel de clank.
extends CanvasLayer

const SHADER_PARAM_INTENSITY: String = "intensity"
const HAZARD_INTENSITY_MIN: float = 0.5
const HAZARD_INTENSITY_MAX: float = 2.0
const HAZARD_INTENSITY_CLAMP: float = 5.0
const HAZARD_LERP_SPEED: float = 0.05

const BPM_LERP_SPEED: float = 0.1
const BEAT_PITCH_MIN: float = 0.8
const BEAT_PITCH_MAX: float = 1.4
const BEAT_VOLUME_MIN: float = 9.0
const BEAT_VOLUME_MAX: float = 12.0
const BEAT_PULSE_ALPHA_MIN: float = 0.05
const BEAT_PULSE_ALPHA_MAX: float = 0.3
const BEAT_PULSE_IN: float = 0.1
const BEAT_PULSE_OUT: float = 0.4

@export var max_hazard_level_visual: int = 10 # Nivel de hazard al que la viñeta alcanza su máximo
@export var min_bpm: float = 30.0
@export var max_bpm: float = 150.0

@onready var _hazard_rect: ColorRect = $AtmosphereLayer/HazardVignette
@onready var _clank_pulse: ColorRect = $AtmosphereLayer/ClankPulse
@onready var _heartbeat_audio: AudioStreamPlayer = $HeartbeatAudio

var _clank_system: ClankManager
var _hazard_system: HazardManager
var _current_bpm: float = 0.0
var _time_since_beat: float = 0.0
var _ready_to_process: bool = false

func _ready() -> void:
	await get_tree().process_frame

	var rm: RunManager = get_tree().get_first_node_in_group("RunManager")
	if rm:
		_clank_system = rm.clank_system
		_hazard_system = rm.hazard_system
		_ready_to_process = true

	_shader_material().set_shader_parameter(SHADER_PARAM_INTENSITY, 0.0)
	_current_bpm = min_bpm

func _process(delta: float) -> void:
	if not _ready_to_process:
		return

	_update_hazard_visuals()
	_process_heartbeat(delta)

func _update_hazard_visuals() -> void:
	if not _hazard_system:
		return
	
	# Remapeamos el hazard actual al rango de intensidad del shader
	var level: float = float(_hazard_system.current_hazard)
	var target: float = clampf(
		remap(level, 1.0, float(max_hazard_level_visual), HAZARD_INTENSITY_MIN, HAZARD_INTENSITY_MAX), 0.0, HAZARD_INTENSITY_CLAMP
	)
	
	var mat: ShaderMaterial = _shader_material()
	mat.set_shader_parameter(SHADER_PARAM_INTENSITY, lerpf(mat.get_shader_parameter(SHADER_PARAM_INTENSITY), target, HAZARD_LERP_SPEED))

func _process_heartbeat(delta: float) -> void:
	if not _clank_system:
		return

	# El BPM sube proporcionalmente al clank acumulado
	var clank_ratio: float = float(_clank_system.current_clank) / float(_clank_system.max_clank)
	_current_bpm = lerpf(_current_bpm, lerpf(min_bpm, max_bpm, clank_ratio), BPM_LERP_SPEED)

	_time_since_beat += delta
	if _time_since_beat >= 60.0 / _current_bpm:
		_time_since_beat = 0.0
		_trigger_beat(clank_ratio)

func _trigger_beat(intensity: float) -> void:
	# El tono y volumen del latido escalan con la intensidad del clank
	_heartbeat_audio.pitch_scale = lerpf(BEAT_PITCH_MIN, BEAT_PITCH_MAX, intensity)
	_heartbeat_audio.volume_db   = lerpf(BEAT_VOLUME_MIN, BEAT_VOLUME_MAX, intensity)
	_heartbeat_audio.play()

	var pulse_alpha: float = lerpf(BEAT_PULSE_ALPHA_MIN, BEAT_PULSE_ALPHA_MAX, intensity)
	var tween: Tween = create_tween()
	tween.tween_property(_clank_pulse, "modulate:a", pulse_alpha, BEAT_PULSE_IN).set_trans(Tween.TRANS_QUART)
	tween.tween_property(_clank_pulse, "modulate:a", 0.0, BEAT_PULSE_OUT)

func _shader_material() -> ShaderMaterial:
	return _hazard_rect.material as ShaderMaterial
