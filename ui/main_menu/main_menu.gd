# Menú principal: punto de entrada al juego, da acceso al Workshop, Codex y selector de clase.
extends Control

func _ready() -> void:
	get_tree().paused = false
	update_ui()
	
	%Workshop.hide()
	%Codex.hide()
	%ClassSelector.hide()

func update_ui() -> void:
	%CurrencyLabel.text = "Ether: %d" % GlobalData.save_file.ether

func _on_btn_expedition_pressed() -> void:
	UIFeedback.play_confirm(%BtnExpedition)
	%ClassSelector.show()

func _on_btn_workshop_pressed() -> void:
	UIFeedback.play_confirm(%BtnWorkshop)
	%Workshop.show()

func _on_btn_codex_pressed() -> void:
	UIFeedback.play_confirm(%BtnCodex)
	%Codex.update_ui()
	%Codex.show()

func _on_btn_quit_pressed() -> void:
	UIFeedback.play_back(%BtnQuit)
	get_tree().quit()
