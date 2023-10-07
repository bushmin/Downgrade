extends Node2D

onready var centerX = get_viewport_rect().size.x/2

const TILE_SIZE = 32

const initialAcc = 0.02
var initialPassed = false

const acc = 0.07
const reverseAcc = 0.2
const gravity = 0.1

onready var LEFT_LIMIT = TILE_SIZE;
onready var RIGHT_LIMIT = get_viewport_rect().size.x - TILE_SIZE;

var ELEVATION = 100
var ASS_OFFSET_LEFT = Vector2(-20, 58)
var ASS_OFFSET_RIGHT = Vector2(20, 58)

onready var HeadPos = Vector2(centerX, 100)
onready var LeftPos = Vector2(LEFT_LIMIT, 100+ELEVATION)
onready var RightPos = Vector2(RIGHT_LIMIT, 100+ELEVATION)

const SLIDE = 3
const LEG_LENGTH = 100
const SAFE_ZONE = 20
const DRAG_SPEED = 0.6

var speed = 0
var direction = 1
var leftSpeed = 0
var rightSpeed = 0

const fireProb = 0.4
const iceProb = 0.2

var leftFire = []
var leftIce = []
var rightFire = []
var rightIce = []

var score = 0

var active = false

const PATTERN_SIZE = 7
const MAX_ICE = 4
const MAX_FIRE = 2

var patternArray = []

func populate_array(start, finish):
	patternArray = []
	for i in range(PATTERN_SIZE):
		if i >= start and i <= finish:
			patternArray.append(1)
		else:
			patternArray.append(0)

func _ready():
	$START.show()
	seed(22)
	
	for i in range(2, 1000):
		if randf() < fireProb:
		
			var start = randi()%PATTERN_SIZE+1
			var finish = start + randi()%MAX_FIRE+1
			populate_array(start, finish)
			for j in range(0, PATTERN_SIZE):
				if patternArray[j] == 1:
					leftFire.append(i*PATTERN_SIZE + j)
					$WALLS.set_cell(0,i*PATTERN_SIZE + j,1)
				else:
					$WALLS.set_cell(0,i*PATTERN_SIZE + j,2)
					
		else:
			var start = randi()%PATTERN_SIZE+1
			var finish = start + randi()%MAX_ICE+1
			populate_array(start, finish)
			for j in range(0, PATTERN_SIZE):
				if patternArray[j] == 1:
					leftIce.append(i*PATTERN_SIZE + j)
					$WALLS.set_cell(0,i*PATTERN_SIZE + j,0)
				else:
					$WALLS.set_cell(0,i*PATTERN_SIZE + j,2)


	for i in range(2, 1000):
		if randf() < fireProb:
		
			var start = randi()%PATTERN_SIZE+1
			var finish = start + randi()%MAX_FIRE+1
			populate_array(start, finish)
			for j in range(0, PATTERN_SIZE):
				if patternArray[j] == 1:
					rightFire.append(i*PATTERN_SIZE + j)
					$WALLS.set_cell(11,i*PATTERN_SIZE + j,1)
				else:
					$WALLS.set_cell(11,i*PATTERN_SIZE + j,2)
					
		else:
			var start = randi()%PATTERN_SIZE+1
			var finish = start + randi()%MAX_ICE+1
			populate_array(start, finish)
			for j in range(0, PATTERN_SIZE):
				if patternArray[j] == 1:
					rightIce.append(i*PATTERN_SIZE + j)
					$WALLS.set_cell(11,i*PATTERN_SIZE + j,0)
				else:
					$WALLS.set_cell(11,i*PATTERN_SIZE + j,2)
	
func game_over():
	active = false
	Music.menu()
	$RESTART/SCORE.text = "SCORE: " + str(score)
	$RESTART.show()

func restart():
	get_tree().reload_current_scene()
	
func start():
	$START/START.release_focus()
	active = true
	$START.hide()
	Music.game()
		
func update_score():
	score = int(floor(HeadPos.y/TILE_SIZE)) - 3
	$UI/SCORE.text = str(score)
	
func _physics_process(delta):
	if not active: return
	
	if Input.is_action_just_pressed("click"):
		direction *= -1
		speed *= -1
		$ROBOT.rect_scale.x *= -1
		initialPassed = true
		
	update_score()

	if speed < 0: speed +=reverseAcc
	else:
		if initialPassed:
			speed+=acc
		else:
			speed+=initialAcc
			
	HeadPos.x += speed*direction
	
	update_shoes()
	readjust_head()
	update_legs()
	update_sprites()

func update_shoes():
	LeftPos.x = max(LEFT_LIMIT, LEFT_LIMIT + (HeadPos.x - centerX-SAFE_ZONE)*DRAG_SPEED)
	RightPos.x = min(RIGHT_LIMIT, RIGHT_LIMIT - (centerX- HeadPos.x-SAFE_ZONE)*DRAG_SPEED)
	
	if LeftPos.x > LEFT_LIMIT:
		leftSpeed += gravity
		LeftPos.y += leftSpeed
	else:
		if leftSpeed != 0:
			Music.play_click()
		leftSpeed = 0
		check_left_wall()
		
	if RightPos.x < RIGHT_LIMIT:
		rightSpeed += gravity
		RightPos.y += rightSpeed
	else:
		if rightSpeed != 0:
			Music.play_click()
		rightSpeed = 0
		check_right_wall()

func check_left_wall():
	if leftFire.has(int(floor(LeftPos.y/TILE_SIZE))):
		game_over()
		Music.play_lava()
		$LEFT_LEG.default_color = Color("#f14e52")
		
	if leftIce.has(int(floor(LeftPos.y/TILE_SIZE))):
		LeftPos.y+=SLIDE
		
func check_right_wall():
	if rightFire.has(int(floor(RightPos.y/TILE_SIZE))):
		game_over()
		Music.play_lava()
		$RIGHT_LEG.default_color = Color("#f14e52")
		
	if rightIce.has(int(floor(RightPos.y/TILE_SIZE))):
		RightPos.y+=SLIDE

func readjust_head():
	HeadPos.y = (RightPos.y + LeftPos.y)/2 - ELEVATION

func update_legs():
	var halfLeftDistance = (HeadPos+ASS_OFFSET_LEFT - LeftPos).length()/2
	if halfLeftDistance>LEG_LENGTH:
		game_over()
		$LEFT_LEG.default_color = Color("#f14e52")
		Music.play_ankle()
		return
	var he = sqrt(pow(LEG_LENGTH,2) - pow(halfLeftDistance,2))
	var leftAnkle = Vector2.DOWN.rotated(Vector2.DOWN.angle_to(LeftPos-HeadPos - ASS_OFFSET_LEFT) +atan(he/halfLeftDistance))*LEG_LENGTH
	$LEFT_LEG.points = [HeadPos + ASS_OFFSET_LEFT, HeadPos + ASS_OFFSET_LEFT +leftAnkle, LeftPos]
	$LEFT.rect_rotation = rad2deg(Vector2.UP.angle_to(HeadPos + ASS_OFFSET_LEFT + leftAnkle - LeftPos))
	
	var halfRightDistance = (HeadPos+ASS_OFFSET_RIGHT - RightPos).length()/2
	if halfRightDistance>LEG_LENGTH:
		game_over()
		$RIGHT_LEG.default_color = Color("#f14e52")
		Music.play_ankle()
		return
	var he2 = sqrt(pow(LEG_LENGTH,2) - pow(halfRightDistance,2))
	var rightAnkle = Vector2.DOWN.rotated(Vector2.DOWN.angle_to(RightPos-HeadPos - ASS_OFFSET_RIGHT) -atan(he2/halfRightDistance))*LEG_LENGTH
	
	$RIGHT_LEG.points = [HeadPos + ASS_OFFSET_RIGHT, HeadPos+rightAnkle + ASS_OFFSET_RIGHT, RightPos]
	$RIGHT.rect_rotation = rad2deg(Vector2.UP.angle_to(HeadPos + ASS_OFFSET_RIGHT + rightAnkle - RightPos))
	
func update_sprites():
	$ROBOT.rect_position = HeadPos - $ROBOT.rect_size/2
	$LEFT.rect_position = LeftPos - $LEFT.rect_size + Vector2(4, 1)
	$RIGHT.rect_position = RightPos- Vector2(0, $RIGHT.rect_size.y) + Vector2(-4,1)
