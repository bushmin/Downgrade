extends Node2D

var downgrade = preload("res://music/downgrade.mp3")
var lava = preload("res://music/explosion.wav")
var ankle = preload("res://music/ankle.wav")
var click = preload("res://music/click.wav")

func _ready():
	play_down()
	menu()
	

func play_down():
	$Music.set_stream(downgrade)
	$Music.play()

func menu():
	$Music.set_bus('Low_Pass')
	
func game():
	$Music.set_bus('Master')

func play_lava():
	$SFX.set_volume_db(0)
	$SFX.set_stream(lava)
	$SFX.play()

func play_ankle():
	$SFX.set_volume_db(-6)
	$SFX.set_stream(ankle)
	$SFX.play()
	
func play_click():
	$SFX.set_volume_db(0)
	$SFX.set_stream(click)
	$SFX.play()
