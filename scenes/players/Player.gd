extends KinematicBody

var vfxScene = preload("res://scenes/vfx.tscn")
var projScene = preload("res://scenes/players/playerProj.tscn")

var playerNum = 1

var playerChar = "Anne"

var speed_walk = 10 #10
var speed_run = 18 #18
var speed_z = 13 #10
var force_jump = 36.0 #42
var force_jump_double = 30.0 #42
var force_jump_AH3 = 30
var force_grav = 125.0
export var comboReady = false
export var hitLanded = false

var left_button = "move_left_"# + str(playerInput)
var right_button = "move_right_"# + str(playerInput)
var up_button = "move_away_"# + str(playerInput)
var down_button = "move_in_"# + str(playerInput)
var jump_button = "jump_"# + str(playerInput)
var light_attack_button = "light_attack_"# + str(playerInput)
var heavy_attack_button = "heavy_attack_"# + str(playerInput)
var block_button = "block_"# + str(playerInput)
var run_button = "run_"# + str(playerInput)

var hp:float = 50
var hpMax:float = 100
var lives = 3
var coins = 0

var safePos = Vector3.ZERO
var deathFloorHeight = -30

var direction = Vector3.ZERO
var velocity = Vector3.ZERO
var speed = speed_walk
var lookRight = true
var wallSliding = false

var doubleJumpReady = true
var mini_jump_boost = 0
var recoilStart = false
var recoilCounter = 0
var recoilDir = 0
var forceHardLand = false
var canMove = true # true if player is not in recoil

var bouncing = false
var bounceHeight = 0

var LCancel = false
var LCancelActiveTimer = 0
var LCancelResetTimer = 0
var secondChanceTechTimer = 0
#var secondChanceTechResetTimer = 0
var lastSecondTech = false
var pressedTechMidFall = false # prevent 2 chances to life-save tech

var counterTimer = 0
var counterSpamTimer = 0
var counterMax = 10
var counterSpamMax = 30

var slideReady = true
var slideSpeed = 0
var slideDir = Vector2.ZERO

var runTimer = 0
var runTimerMax = 20

var hitDamage = 0
var hitDamageMulti = 1.0
var hurtDamageMulti = 1.0
var hitType = 0
var hitDir = Vector3.ZERO
var hitSound = ""

var justHurt = false
var hurtAgain = false
var hurtCount = 0
var invincible = false
var invincibleState = false
var invincibleGetUp = 0 # cannot be hit if this value is above 0
var hurtDamage = 0
var hurtType = 0
var hurtDir = Vector3.ZERO
var hurtPierced = false

var pogo = false
var pogoMultiplier = 1

var lastOnFloorHeight = 0
var lastOnFloorPos = Vector3.ZERO
var shadowHeight = 0 # used in camera positioning
var secondaryY = 0
var follwingAirbornePlayer = false

var nearNPCs = 0

enum printStatesEnum {IDLE, WALK, RUN, JUMP, DJUMP, RISING, FALLING, BOUNCE, LAND, LANDC, A_L1, A_L2, A_L3, A_H1, A_H2, A_H3, A_AL1, A_AL2, A_AL3, A_AH1, A_AH2, A_AH3_LAUNCH, A_AH3_RISE, A_AH3_HIT, A_AH3_LAND, A_SL, A_SH, BLOCK, COUNTER, BLOCKHIT, HURT, HURTLAUNCH, HURTRISING, HURTFALLING, HURTFLOOR, KO, WAVE}
enum {IDLE, WALK, RUN, JUMP, DJUMP, RISING, FALLING, BOUNCE, LAND, LANDC, A_L1, A_L2, A_L3, A_H1, A_H2, A_H3, A_AL1, A_AL2, A_AL3, A_AH1, A_AH2, A_AH3_LAUNCH, A_AH3_RISE, A_AH3_HIT, A_AH3_LAND, A_SL, A_SH, BLOCK, COUNTER, BLOCKHIT, HURT, HURTLAUNCH, HURTRISING, HURTFALLING, HURTFLOOR, KO, WAVE}
enum {UP, DOWN, LEFT, RIGHT, NONE}
enum {KB_WEAK, KB_STRONG, KB_ANGLED, KB_AIR, KB_STRONG_RECOIL, KB_AIR_UP, KB_WEAK_PIERCE, KB_STRONG_PIERCE, KB_ANGLED_PIERCE}
var oldInput = UP
var newInput = DOWN

var state = IDLE
var nextState = IDLE

var fps = 1

var windVect = Vector3.ZERO # "push" from wind boxes
var isInWindbox = false

var waveVect = Vector3.ZERO
var isWavedashing = false
var wavedashSpeed = 60
var airdashVect = Vector3.ZERO
var isAirdashing = false

onready var anim = $"AnimationPlayer"
onready var sprite = $"zeroPoint/AnimatedSprite3D"
onready var face = $"playerInfo/face"
var animFinished = false

#input buffer stuff
var inputBuffKey = null
var inputBuffTimer = 0
var inputBuffMax = 8

var secondCombo = false
var arrowsShot = 0


func initialize(num, pos, character):
	# adds hit box area to appropriate group so enemies can tell hitboxes apart
	$"zeroPoint/hitbox".add_to_group("player"+str(num))
	# sets up inputs
	left_button = "move_left_" + str(pg.playerInput[num])
	right_button = "move_right_" + str(pg.playerInput[num])
	up_button = "move_away_" + str(pg.playerInput[num])
	down_button = "move_in_" + str(pg.playerInput[num])
	jump_button = "jump_" + str(pg.playerInput[num])
	light_attack_button = "light_attack_" + str(pg.playerInput[num])
	heavy_attack_button = "heavy_attack_" + str(pg.playerInput[num])
	block_button = "block_" + str(pg.playerInput[num])
	run_button = "run_" + str(pg.playerInput[num])
	# positions player panel
	$playerInfo.anchor_left = 0.25 * num
	# sets player position, velocity, and starting respawn point
	translation = pos
	safePos = pos
	velocity = Vector3.ZERO
	# renames player root node
	self.name = "Player" + str(num)
	# updates lives, hp, damage
	updateStats()
	#sets player number and char
	playerNum = num
	playerChar = character
	# Positions character to the right
	lookRight = true
	sprite.set_rotation_degrees(Vector3(-15, 90, 0))
	$"zeroPoint".set_rotation_degrees(Vector3(0, 180, 0))
	# sets updated values if spawning again after karting
	if pg.karting:
		hp = pg.playerHealth[playerNum]
		lives = pg.playerLives[playerNum]
		coins = pg.playerCoins[playerNum]
		

func clearInputBuffer():
	inputBuffKey = null
	inputBuffTimer = 0
	
func updateInputBuffer(delta):
	# increments timer and resets if necessary
	if (inputBuffTimer <= 0):
		clearInputBuffer()
	else:
		inputBuffTimer -= 60 * delta
	# if a key is pressed, re-starts timer and stores key
	if (Input.is_action_just_pressed(jump_button) == true):
		inputBuffKey = jump_button
		inputBuffTimer = inputBuffMax
	elif (Input.is_action_just_pressed(light_attack_button) == true):
		inputBuffKey = light_attack_button
		inputBuffTimer = inputBuffMax
	elif (Input.is_action_just_pressed(heavy_attack_button) == true):
		inputBuffKey = heavy_attack_button
		inputBuffTimer = inputBuffMax
	elif (Input.is_action_just_pressed(block_button) == true):
		clearInputBuffer()
	
func updateStats():
	# sets lives
	if pg.hardcoreMode:
		lives = 1
	elif pg.unlimitedLives:
		lives = 99999
	else:
		lives = pg.playerStartingLives + pg.livesUpgrades
	# sets player health
	hpMax = pg.playerStartingMaxHP + (pg.healthUpgrades * pg.healthBoost)
	hp = float(hpMax)
	$playerInfo/lifeBar.margin_left = $playerInfo/lifeBar.margin_right - hpMax
	$playerInfo/lifeOutline.margin_left = $playerInfo/lifeOutline.margin_right - (hpMax + 8)
	# sets player damage multipliers
	hitDamageMulti = 1 + (pg.damageUpgrades * pg.damageBoost) 
	hurtDamageMulti = 1
	if (pg.easyMode):
		hitDamageMulti *= 1.5
		hurtDamageMulti *= 0.5
	elif (pg.hardMode):
		hurtDamageMulti *= 2
	# nerfs for multiplayer mode
	var numExtras = (pg.countPlayers() - 1)
	if (numExtras >= 1):
		hitDamageMulti  = hitDamageMulti  * pow(0.7, numExtras)
		hurtDamageMulti = hurtDamageMulti * pow(1.2, numExtras)


func isInState(list):
	var found = false
	for i in list:
		if state == i:
			found = true
	return found
		
	
func checkWalk():
	var walk = false
	if ((Input.is_action_pressed(right_button) == true) or (Input.is_action_pressed(left_button) == true) or (Input.is_action_pressed(down_button) == true) or (Input.is_action_pressed(up_button) == true)):
		walk = true
#	if isWavedashing:
#		walk = false
	return walk
	
func checkWalkJust():
	var walk = false
	if ((Input.is_action_just_pressed(right_button) == true) or (Input.is_action_just_pressed(left_button) == true) or (Input.is_action_just_pressed(down_button) == true) or (Input.is_action_just_pressed(up_button) == true)):
		walk = true
#	if isWavedashing:
#		walk = false
	return walk
	
func setHitBox(damage, type, dir, sfx = "hit1"):
	hitDamage = damage * hitDamageMulti
	hitType = type
	hitDir = dir # for direction, +x and +y means away and up. ~10 for magnitude
	hitSound = sfx
	if (lookRight == false):
		hitDir.x *= -1
		
func playSoundEffect(soundName = "hit1", pitch = null, volume = 0):
	if (pitch != null):
		soundManager.pitchSound(soundName, pitch, volume)
	soundManager.playSound(soundName)
		
func spawnProj(projVel = Vector3.ZERO, projAng = 0, addPlayerVel = false, randLoc = false):
	# sets spawn point
	var spawnLocation = get_node("zeroPoint/projSpawnPoint").global_transform.origin
	# add random offset if necessary
	if randLoc:
		spawnLocation.x += rng.rand.randf_range(-15, 15)
		spawnLocation.z += rng.rand.randf_range(-6, 8)
	# sets projectile type
	var projType = 0
	if (playerChar == "Marcy") and isInState([A_SH]) and comboReady:
		projType = 3
	elif (playerChar == "Marcy") and isInState([A_AH1, A_AH3_HIT, COUNTER]):
		projType = 3
	elif (playerChar == "Marcy"):
		projType = 1
	elif (playerChar == "Maggie"):
		projType = 2
	elif (playerChar == "Darla") and isInState([A_H1]):
		projType = 4
	elif (playerChar == "Darla") and isInState([A_AH2]):
		projType = 5
	elif (playerChar == "Darla") and isInState([A_AH3_HIT]):
		projType = 6
	# adds player velocity to projectile's (x and z for lobbed weapons)
	if addPlayerVel and lookRight:
		projVel.x += 0.75 * velocity.x
		projVel.z += velocity.z
	elif addPlayerVel and not lookRight:
		projVel.x -= 0.75 * velocity.x
		projVel.z += velocity.z
	# instances and initializes projectile scene
	var proj = projScene.instance()
	get_parent().add_child(proj)
	proj.initialize(spawnLocation, lookRight, hitDamage, hitType, hitDir, hitSound, projType, projVel, projAng, playerNum)

func addArrowCount(num):
	arrowsShot += num
	if (arrowsShot < 0):
		arrowsShot = 0
	elif (arrowsShot > 3):
		arrowsShot = 3

func forceRecoil():
	recoilStart = true
	
func forcePogo(strength):
	pogo = true
	pogoMultiplier = strength
	
func forceMiniJump():
#	if (playerChar == "Sasha") and !secondCombo:
#		return
	if (velocity.y <= 20):
		mini_jump_boost = 15
		
func fixPlayerPos():
	var cam = get_parent().get_node("camera_pivot/Camera")
	safePos = cam.findSpawnPoint(get_parent().get_node("camera_pivot").translation + Vector3(0, 0, -1 * cam.offsetZ))
	translation = safePos + Vector3(0, 5, 0)
	velocity = Vector3.ZERO + Vector3(0, 15, 0)
	state = RISING
	nextState = RISING

func respawn(dead):
	var cam = get_parent().get_node("camera_pivot/Camera")
	if (pg.countPlayers() >= 2):
		safePos = cam.findSpawnPoint(get_parent().get_node("camera_pivot").translation + Vector3(0, 0, -1 * cam.offsetZ))
	else:
		safePos = cam.findSpawnPoint(lastOnFloorPos)
	if (dead):
		lives -= 1
		state = RISING
		nextState = RISING
		hp = hpMax
		invincibleGetUp = 90
	else:
		addHealth(-10)
		state = HURTRISING
	if (lives <= 0):
		pg.playerAlive[playerNum] = false
		queue_free()
	else:
		translation = safePos + Vector3(0, 5, 0)
		velocity = Vector3.ZERO + Vector3(0, 15, 0)
		
func addHealth(amount):
	hp += amount
	if (hp <= 0):
		hp = 0
	elif (hp >= hpMax):
		hp = hpMax
		
func addLives(amount):
	lives += amount
	if (lives <= 0):
		lives = 0
	elif (lives >= 9):
		lives = 9

func startWavedash():
	waveVect = velocity.normalized() * wavedashSpeed
	isWavedashing = true
	#lookRight = !lookRight
	
func startAirdash(airdashSpeed = 30):
	isAirdashing = true
	# mirrors char if necessary, sets dash direction
	if (direction.x > 0):
		airdashVect.x = airdashSpeed
		lookRight = true
		sprite.set_rotation_degrees(Vector3(-15, 90, 0))
		$"zeroPoint".set_rotation_degrees(Vector3(0, 180, 0))
	elif (direction.x < 0):
		airdashVect.x = -1 * airdashSpeed
		lookRight = false
		sprite.set_rotation_degrees(Vector3(15, 90, 0))
		$"zeroPoint".set_rotation_degrees(Vector3(0, 0, 0))
	else: # if standing still
		if lookRight:
			airdashVect.x = airdashSpeed
		else:
			airdashVect.x = -1 * airdashSpeed
		
func endAirdash():
	airdashVect = Vector3.ZERO
	isAirdashing = false

func _physics_process(delta):
	
	direction = Vector3.ZERO
	var snapVect  = Vector3.ZERO
	
	# input buffer
	updateInputBuffer(delta)
	
	# Movement inputs
	if (canMove) and (pg.dontMove == false):
		if Input.is_action_pressed(right_button) and Input.is_action_pressed(left_button):
			direction.x = 0
		elif Input.is_action_pressed(right_button):
			direction.x = 1
		elif Input.is_action_pressed(left_button):
			direction.x = -1
		else:
			direction.x = 0
		if Input.is_action_pressed(down_button) and Input.is_action_pressed(up_button):
			direction.z = 0
		elif Input.is_action_pressed(down_button):
			direction.z = 1
		elif Input.is_action_pressed(up_button):
			direction.z = -1
		else:
			direction.z = 0
	else:
		direction.x = 0
		direction.z = 0
		
	# Double-tap checks
	if Input.is_action_just_pressed(right_button):
		runTimer = runTimerMax
		if (oldInput != RIGHT):
			oldInput = RIGHT
		else:
			newInput = RIGHT
	if Input.is_action_just_pressed(left_button):
		runTimer = runTimerMax
		if (oldInput != LEFT):
			oldInput = LEFT
		else:
			newInput = LEFT
	runTimer -= 1
	if (runTimer <= 0):
		runTimer = 0
		oldInput = NONE
		newInput = NONE
		
	# L canceling
	if (LCancelActiveTimer > 0):
		LCancelActiveTimer -= 1
	if (LCancelResetTimer > 0):
		LCancelResetTimer -= 1
	if (is_on_floor() == false) and Input.is_action_just_pressed(block_button) and (LCancelResetTimer <= 0):
		LCancel = true
		LCancelActiveTimer = 12
		LCancelResetTimer = 40
	if (LCancelActiveTimer <= 0):
		LCancel = false
	if (Input.is_action_just_pressed(light_attack_button)) or (Input.is_action_just_pressed(heavy_attack_button)):
		LCancel = false
	# tech chance after landing
	if isInState([HURTFLOOR, KO]):
		secondChanceTechTimer -= 1
		if (secondChanceTechTimer > 0) and (not pressedTechMidFall) and Input.is_action_just_pressed(block_button):
			lastSecondTech = true
	if isInState([HURTFALLING]) and (Input.is_action_just_pressed(block_button)):
		pressedTechMidFall = true
	if isInState([HURTLAUNCH, HURTRISING]):
		pressedTechMidFall = false
		lastSecondTech = false
	
	# state changes
	match state:
		IDLE:
			canMove = true
			if pg.dontMove:
				nextState = IDLE
			#elif Input.is_action_just_pressed(jump_button):
			elif (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif checkWalk() and (direction != Vector3.ZERO):
				nextState = WALK
			#elif Input.is_action_just_pressed(light_attack_button) and (nearNPCs <= 0):
			elif (inputBuffKey == light_attack_button) and (nearNPCs <= 0):
				clearInputBuffer()
				nextState = A_L1
			#elif Input.is_action_just_pressed(heavy_attack_button):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H1
			elif Input.is_action_pressed(block_button):
				nextState = BLOCK
			else:
				nextState = IDLE
		WALK:
			if (direction == Vector3.ZERO):
				nextState = IDLE
			elif Input.is_action_pressed(run_button) and (direction.x != 0):
				runTimer = 0
				nextState = RUN
			elif( (runTimer > 0) and (oldInput == newInput) and (newInput != NONE) ):
				runTimer = 0
				nextState = RUN
			#elif Input.is_action_just_pressed(jump_button):
			elif (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif (is_on_floor() == false):
				nextState = FALLING
			#elif Input.is_action_just_pressed(light_attack_button) and (nearNPCs <= 0):
			elif (inputBuffKey == light_attack_button) and (nearNPCs <= 0):
				clearInputBuffer()
				nextState = A_L1
			#elif Input.is_action_just_pressed(heavy_attack_button):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H1
			elif Input.is_action_just_pressed(block_button):
				nextState = BLOCK
			else:
				nextState = WALK
		RUN:
			if (direction == Vector3.ZERO):
				nextState = IDLE
			elif Input.is_action_just_released(run_button):
				nextState = WALK
			elif (velocity.x == 0):
				nextState = WALK
			#elif Input.is_action_just_pressed(jump_button):
			elif (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif (is_on_floor() == false):
				nextState = FALLING
			elif (Input.is_action_pressed(right_button) == false) and (Input.is_action_pressed(left_button) == false):
				nextState = WALK
			#elif Input.is_action_just_pressed(light_attack_button):
			elif (inputBuffKey == light_attack_button) and isWavedashing:
				clearInputBuffer()
				nextState = A_L1
			elif (inputBuffKey == heavy_attack_button) and isWavedashing:
				clearInputBuffer()
				nextState = A_H1
			elif (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_SL
			#elif Input.is_action_just_pressed(heavy_attack_button):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				if pg.hasSlide: # and (waveVect.length() <= 0.1*wavedashSpeed):
					nextState = A_SH
				else:
					nextState = A_H1
			elif Input.is_action_just_pressed(block_button) and (playerChar == "Marcy"):
				clearInputBuffer()
				#if pg.hasSlide and (waveVect.length() <= 0.1*wavedashSpeed):
				if (waveVect.length() <= 0.1*wavedashSpeed):
					nextState = WAVE
				else:
					nextState = RUN
			else:
				nextState = RUN
		JUMP:
			nextState = RISING
		DJUMP:
			nextState = RISING
			doubleJumpReady = false
		RISING:
			if (velocity.y <= 0):
				nextState = FALLING
			#elif doubleJumpReady and (Input.is_action_just_pressed(jump_button)) and pg.hasDJ:
			elif doubleJumpReady and (inputBuffKey == jump_button) and pg.hasDJ:
				clearInputBuffer()
				nextState = DJUMP
			#elif Input.is_action_just_pressed(light_attack_button):
			elif (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_AL1
			#elif Input.is_action_just_pressed(heavy_attack_button):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				if (speed == speed_run):
					nextState = A_AH2
				else:
					nextState = A_AH1
			else:
				nextState = RISING
		FALLING:
			if is_on_floor():
				if forceHardLand:
					forceHardLand = false
					nextState = LAND
				elif checkWalk() == false:
					nextState = IDLE
				elif (speed == speed_run):
					nextState = RUN
				elif (speed == speed_walk):
					nextState = WALK
				else:
					nextState = IDLE
			#elif doubleJumpReady and (Input.is_action_just_pressed(jump_button)) and pg.hasDJ:
			elif doubleJumpReady and (inputBuffKey == jump_button) and pg.hasDJ:
				clearInputBuffer()
				nextState = DJUMP
			#elif Input.is_action_just_pressed(light_attack_button):
			elif (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_AL1
			#elif Input.is_action_just_pressed(heavy_attack_button):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				if (speed == speed_run):
					nextState = A_AH2
				else:
					nextState = A_AH1
			else:
				nextState = FALLING
		BOUNCE:
			doubleJumpReady = true
			nextState = RISING
		LAND:
			forceHardLand = false
			if (LCancel):
				nextState = LANDC
				state = LANDC
				soundManager.playSound("counter")
			if (animFinished):
				nextState = IDLE
				animFinished = false
		LANDC:
			if (animFinished):
				nextState = IDLE
				animFinished = false
			elif checkWalk() and (direction != Vector3.ZERO):
				nextState = WALK
		A_L1:
			#if (comboReady) and (hitLanded) and (Input.is_action_just_pressed(light_attack_button)):
			if (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_L2
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H2
			elif (comboReady) and (playerChar == "Marcy") and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H2
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(jump_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif animFinished:
				nextState = IDLE
				animFinished = false
		A_L2:
			#if (comboReady) and (hitLanded) and (Input.is_action_just_pressed(light_attack_button)):
			if (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_L3
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H1
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(jump_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif animFinished:
				nextState = IDLE
				animFinished = false
		A_L3:
			#if (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)) and pg.hasSpin:
			if (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button) and pg.hasSpin:
				clearInputBuffer()
				nextState = A_H3
#			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button) and (secondCombo == false) and (playerChar == "Sasha"):
#				clearInputBuffer()
#				nextState = A_L2
#				secondCombo = true
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(jump_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif animFinished:
				nextState = IDLE
				animFinished = false
#			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
#				clearInputBuffer()
#				nextState = A_L2
		A_H1:
			if (playerChar == "Marcy") and (arrowsShot < 3) and (comboReady) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				anim.seek(0)
				nextState = A_H1
			elif animFinished:
				nextState = IDLE
				animFinished = false
		A_H2:
			if (comboReady) and (hitLanded) and (playerChar == "Marcy"):
				nextState = IDLE
				animFinished = false
			if animFinished:
				nextState = IDLE
				animFinished = false
		A_H3:
			if animFinished:
				nextState = IDLE
				animFinished = false
		A_AL1:
			if is_on_floor():
				if forceHardLand:
					forceHardLand = false
					nextState = LAND
				elif checkWalk() == false:
					nextState = IDLE
				elif (speed == speed_run):
					nextState = RUN
				elif (speed == speed_walk):
					nextState = WALK
				else:
					nextState = IDLE
			#elif (comboReady) and (hitLanded) and doubleJumpReady and (Input.is_action_just_pressed(jump_button)) and pg.hasDJ:
			elif (comboReady) and (hitLanded) and doubleJumpReady and (inputBuffKey == jump_button) and pg.hasDJ:
				clearInputBuffer()
				nextState = DJUMP
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(light_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_AL2
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_AH1
			elif animFinished and (velocity.y <= 0):
				nextState = FALLING
				animFinished = false
			elif animFinished:
				nextState = RISING
				animFinished = false
		A_AL2:
			if is_on_floor():
				if forceHardLand:
					forceHardLand = false
					nextState = LAND
				elif checkWalk() == false:
					nextState = IDLE
				elif (speed == speed_run):
					nextState = RUN
				elif (speed == speed_walk):
					nextState = WALK
				else:
					nextState = IDLE
			#elif (comboReady) and (hitLanded) and doubleJumpReady and (Input.is_action_just_pressed(jump_button)) and pg.hasDJ:
			elif (comboReady) and (hitLanded) and doubleJumpReady and (inputBuffKey == jump_button) and pg.hasDJ:
				clearInputBuffer()
				nextState = DJUMP
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(light_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_AL3
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)):
			elif (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_AH2
			elif animFinished and (velocity.y <= 0):
				nextState = FALLING
				animFinished = false
			elif animFinished:
				nextState = RISING
				animFinished = false
		A_AL3:
			if is_on_floor():
				nextState = LAND
			#elif (comboReady) and (hitLanded) and doubleJumpReady and (Input.is_action_just_pressed(jump_button)) and pg.hasDJ:
			elif (comboReady) and (hitLanded) and doubleJumpReady and (inputBuffKey == jump_button) and pg.hasDJ:
				clearInputBuffer()
				nextState = DJUMP
			#elif (comboReady) and (hitLanded) and (Input.is_action_just_pressed(heavy_attack_button)) and pg.hasAirSpin:
			elif (comboReady) and (hitLanded) and (inputBuffKey == heavy_attack_button) and pg.hasAirSpin:
				clearInputBuffer()
				nextState = A_AH3_LAUNCH
#			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button) and (secondCombo == false) and (playerChar == "Sasha"):
#				clearInputBuffer()
#				nextState = A_AL2
#				secondCombo = true
			elif animFinished and (velocity.y <= 0):
				nextState = FALLING
				animFinished = false
			elif animFinished:
				nextState = RISING
				animFinished = false
		A_AH1:
			if is_on_floor():
				nextState = LAND
			elif animFinished and (velocity.y <= 0):
				nextState = FALLING
				animFinished = false
			elif animFinished:
				nextState = RISING
				animFinished = false
		A_AH2:
			if is_on_floor():
				nextState = LAND
			elif animFinished and (velocity.y <= 0):
				nextState = FALLING
				animFinished = false
#			elif (comboReady) and (playerChar == "Darla") and (inputBuffKey == heavy_attack_button):
#				anim.seek(0, false)
			elif animFinished:
				nextState = RISING
				animFinished = false
		A_AH3_LAUNCH:
			forceHardLand = false
			nextState = A_AH3_RISE
		A_AH3_RISE:
			if is_on_floor():
				nextState = LAND
			#elif (Input.is_action_just_pressed(heavy_attack_button)):
			elif (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_AH3_HIT
			elif animFinished:
				nextState = FALLING
				animFinished = false
		A_AH3_HIT:
			if is_on_floor():
				nextState = A_AH3_LAND
			elif animFinished:
				nextState = FALLING
				animFinished = false
		A_AH3_LAND:
			#if (comboReady) and (hitLanded) and (Input.is_action_just_pressed(jump_button)):
			if (comboReady) and (hitLanded) and (inputBuffKey == jump_button):
				clearInputBuffer()
				speed = speed_walk
				nextState = JUMP
			elif (comboReady) and (hitLanded) and checkWalkJust() and (direction != Vector3.ZERO):
				nextState = WALK
			elif animFinished:
				nextState = IDLE
				animFinished = false
		A_SL:
			#if (comboReady) and (hitLanded) and (Input.is_action_just_pressed(jump_button)):
			if (comboReady) and (hitLanded) and (inputBuffKey == jump_button):
				clearInputBuffer()
				speed = speed_walk
				nextState = JUMP
			elif (comboReady) and (hitLanded) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_L1
#			elif (comboReady) and (hitLanded) and checkWalkJust() and (direction != Vector3.ZERO):
#				nextState = WALK
			elif (is_on_floor() == false):
				nextState = FALLING
			elif animFinished:
				nextState = IDLE
				animFinished = false
		A_SH:
			if (is_on_floor() == false):
				nextState = FALLING
#			elif (inputBuffKey == jump_button):
#				clearInputBuffer()
#				nextState = JUMP
			#elif Input.is_action_just_pressed(light_attack_button) and (nearNPCs <= 0):
#			elif (inputBuffKey == light_attack_button) and (nearNPCs <= 0):
#				clearInputBuffer()
#				nextState = A_L1
#			#elif Input.is_action_just_pressed(heavy_attack_button):
#			elif (inputBuffKey == heavy_attack_button):
#				clearInputBuffer()
#				nextState = A_H1
#			elif Input.is_action_just_pressed(block_button):
#				nextState = BLOCK
			elif animFinished:
				nextState = IDLE
				animFinished = false
		WAVE:
			if (is_on_floor() == false):
				nextState = FALLING
			elif animFinished:
				nextState = IDLE
				animFinished = false
		BLOCK:
			if (is_on_floor() == false):
				nextState = FALLING
			elif (Input.is_action_just_pressed(jump_button)):
				clearInputBuffer()
				nextState = JUMP
			elif (Input.is_action_pressed(block_button) == false):
				nextState = IDLE
		BLOCKHIT:
			if (is_on_floor() == false):
				nextState = FALLING
			elif (Input.is_action_pressed(block_button) == false):
				nextState = IDLE
			elif (animFinished):
				nextState = BLOCK
				animFinished = false
		COUNTER:
			if (is_on_floor() == false):
				nextState = FALLING
			#elif (comboReady) and (Input.is_action_just_pressed(jump_button)):
			elif (comboReady) and (inputBuffKey == jump_button):
				clearInputBuffer()
				nextState = JUMP
			elif (comboReady) and checkWalkJust() and (direction != Vector3.ZERO):
				nextState = WALK
			#elif (comboReady) and Input.is_action_just_pressed(light_attack_button):
			elif (comboReady) and (inputBuffKey == light_attack_button):
				clearInputBuffer()
				nextState = A_L1
			#elif (comboReady) and Input.is_action_just_pressed(heavy_attack_button):
			elif (comboReady) and (inputBuffKey == heavy_attack_button):
				clearInputBuffer()
				nextState = A_H1
			elif animFinished:
				nextState = IDLE
				animFinished = false
		HURT:
			if (animFinished):
				nextState = IDLE
				animFinished = false
		HURTLAUNCH:
			
			nextState = HURTRISING
		HURTRISING:
			if (velocity.y <= 0):
				nextState = HURTFALLING
			else:
				nextState = HURTRISING
		HURTFALLING:
			if is_on_floor():
				nextState = HURTFLOOR
				secondChanceTechTimer = 15
			else:
				nextState = HURTFALLING
		HURTFLOOR:
			#randf ( )
			if (hp <= 0) and (LCancel) and (rng.rand.randf() <= (0.50 + (pg.luckUpgrades * pg.techBoost))):
				nextState = LANDC
				state = LANDC
				soundManager.playSound("counter")
			elif (hp <= 0):
				nextState = KO
			elif (LCancel):
				soundManager.playSound("counter")
				nextState = LANDC
				state = LANDC
			elif (lastSecondTech):
				soundManager.playSound("counter")
				nextState = LANDC
				state = LANDC
			elif (animFinished):
				animFinished = false
				nextState = IDLE
			else:
				nextState = HURTFLOOR
		KO:
			if (lastSecondTech) and (rng.rand.randf() <= (0.50 + (pg.luckUpgrades * pg.techBoost))):
				soundManager.playSound("counter")
				nextState = LANDC
				state = LANDC
			elif (animFinished):
				animFinished = false
				respawn(true)
			else:
				nextState = KO
			lastSecondTech = false #prevents re-rolls every loop
			secondChanceTechTimer = -1
		_:
			pass
			#state = IDLE
			#nextState = IDLE
	# Bounce Pads
	if (bouncing) and (isInState([RISING]) == false):
		nextState = BOUNCE
		bouncing = false
	# checking for various invincibility flags
	if (isInState([KO, HURTFALLING, HURTFLOOR, A_AH3_HIT])):
		invincibleState = true
	else:
		invincibleState = false
	if isInState([HURTFLOOR, HURTRISING, HURTFALLING]):
		invincibleGetUp = 60
	elif (invincibleGetUp >= 0):
		invincibleGetUp -= 1
	# taking damage
	if (justHurt):
		justHurt = false
		#print("HIT")
		if isInState([HURTFLOOR]):
			nextState = HURTFLOOR
		elif isInState([HURTFALLING]):
			nextState = HURTFALLING
		elif isInState([COUNTER]):
			nextState = COUNTER
			hurtDamage = 0
			#hurtType
		elif isInState([BLOCK]) and (counterTimer > 0) and pg.hasCounter:
			nextState = COUNTER
			hurtDamage = 0
		elif isInState([BLOCK, BLOCKHIT]) and (hurtPierced == false):
			nextState = BLOCKHIT
			hurtDamage = 0.25 * hurtDamage
		elif (hurtType == KB_STRONG) or (hurtType == KB_ANGLED):
			nextState = HURTLAUNCH
		elif (isInState([HURT]) and hurtCount >= 2):
			hurtDir = Vector3(0, 20, 0)
			nextState = HURTLAUNCH
			hurtType = KB_ANGLED
		elif isInState([HURT]):
			hurtAgain = true
			nextState = HURT
		else:
			nextState = HURT
		hurtCount += 1
		addHealth(-1 * hurtDamage * hurtDamageMulti)
		# plays sfx
		if (nextState == COUNTER):
			soundManager.playSound("counter")
		elif (nextState == BLOCKHIT):
			soundManager.playSound("block")
		elif (hurtType == KB_WEAK):
			soundManager.playSound("hurt1")
		else:
			soundManager.playSound("hurt2")
	# tricky sfx
	if (nextState == RUN) and (state != RUN):
		soundManager.playSound("run")
	elif (nextState == BLOCK) and (state != BLOCK) and (state != BLOCKHIT):
		soundManager.playSound("shield")
	elif ((nextState == A_SL) or (nextState == A_SH) or (nextState == WAVE)) and (state != A_SL) and (state != A_SH) and (state != WAVE):
		soundManager.playSound("slide")
	elif (nextState == JUMP):
		soundManager.pitchSound("jump", 1.0)
		soundManager.playSound("jump")
	elif (nextState == DJUMP):
		soundManager.pitchSound("jump", 1.2)
		soundManager.playSound("jump")
	# sets state
	state = nextState
	
	#Sasha 5 hit combos
#	if isInState([IDLE, WALK, RUN, JUMP, BOUNCE, LAND, LANDC]):
#		secondCombo = false
	
	# Counter mechanic
	if (counterTimer > 0):
		counterTimer -= 1
	if (counterSpamTimer > 0):
		counterSpamTimer -= 1
	if (Input.is_action_just_pressed(block_button)) and (counterSpamTimer == 0):
		counterTimer = counterMax
		counterSpamTimer = counterSpamMax
	elif (Input.is_action_just_pressed(block_button)):
		counterSpamTimer = counterSpamMax
		
	# resets animFinished if in looping animation state to prevent bugs
	if (isInState([IDLE, WALK, RUN, RISING, FALLING, HURTFALLING, HURTRISING, BLOCK])):
		animFinished = false
	
	# calculates height of floor below character for the camera
	if ($RayCast.is_colliding()):
		shadowHeight = $RayCast.get_collision_point().y
	if is_on_floor():
		lastOnFloorHeight = translation.y
		lastOnFloorPos = translation
		follwingAirbornePlayer = false
	if follwingAirbornePlayer:
		secondaryY = translation.y
	elif (shadowHeight > lastOnFloorHeight): # jumped up to higher ledge
		secondaryY = shadowHeight
	elif (translation.y < lastOnFloorHeight): # jumped/fell off ledge
		if ($RayCast.is_colliding()): # not over death pit
			secondaryY = shadowHeight
		else:
			secondaryY = lastOnFloorHeight
	else:
		secondaryY = lastOnFloorHeight

	
	# mirror character if necessary
	#if(state == WALK or state == RUN or state == DJUMP) and (direction != Vector3.ZERO):
	if(isInState([IDLE, WALK, RUN, JUMP, DJUMP])) and (direction != Vector3.ZERO):
		#$"zeroPoint".look_at(translation + Vector3(direction.x, 0, 0), Vector3.UP)
		if (direction.x > 0):
			lookRight = true
			sprite.set_rotation_degrees(Vector3(-15, 90, 0))
			$"zeroPoint".set_rotation_degrees(Vector3(0, 180, 0))
			#sprite.set_translation(Vector3(0.5, 0, 0))
		elif (direction.x < 0):
			lookRight = false
			sprite.set_rotation_degrees(Vector3(15, 90, 0))
			$"zeroPoint".set_rotation_degrees(Vector3(0, 0, 0))
			#sprite.set_translation(Vector3(-0.5, 0, 0))

		
	# sets up hitbox stats
#	if   isInState([A_L1]):
#		setHitBox(5, KB_WEAK, Vector3(1, 0, 0))
#	elif isInState([A_L2]):
#		setHitBox(10, KB_WEAK, Vector3(1, 0, 0), "hit2")
#	elif isInState([A_L3]):
#		setHitBox(10, KB_WEAK, Vector3(1, 0, 0))
#	elif isInState([A_H1]):
#		setHitBox(12, KB_STRONG, Vector3(30, 25, 0), "hit3")
#	elif isInState([A_H2]):
#		setHitBox(20, KB_STRONG, Vector3(7, 50, 0), "hit3")
#	elif isInState([A_H3]):
#		if (comboReady):
#			setHitBox(15, KB_ANGLED, Vector3(15, 35, 0), "none")
#		else:
#			setHitBox(2, KB_WEAK, Vector3(1, 0, 0), "hit5")
#	elif isInState([A_AH1]):
#		setHitBox(20, KB_ANGLED, Vector3(40, 10, 0), "hit3")
#	elif isInState([A_AH2]):
#		setHitBox(35, KB_STRONG_RECOIL, Vector3(30, -70, 0), "hit4")
#	elif isInState([A_AH3_HIT]):
#		setHitBox(1, KB_STRONG, Vector3(0, -50, 0), "hit3")
#	elif isInState([A_AH3_LAND]):
#		setHitBox(35, KB_ANGLED, Vector3(5, 50, 0), "hit3")
#	elif isInState([A_AL1]):
#		setHitBox(8, KB_AIR, Vector3(1, 0, 0))
#	elif isInState([A_AL2]):
#		setHitBox(8, KB_AIR, Vector3(1, 0, 0), "hit2")
#	elif isInState([A_AL3]):
#		setHitBox(12, KB_AIR_UP, Vector3(1, 30, 0))	
#	elif isInState([A_SL]):
#		setHitBox(15, KB_STRONG, Vector3(-7, 40, 0), "hit2")
#	elif isInState([A_SH]):
#		setHitBox(20, KB_STRONG_RECOIL, Vector3(30, 25, 0), "hit3")
#	elif isInState([COUNTER]):
#		setHitBox(35, KB_ANGLED, Vector3(5, 40, 0), "hit4")
#	elif isInState([HURTFLOOR]):
#		setHitBox(1, KB_ANGLED, Vector3(5, 15, 0))
#	else:
#		pass
	
	# resets combo flag in non-battle states
	if isInState([IDLE, WALK, RUN, JUMP, DJUMP, RISING, FALLING, HURT, HURTLAUNCH]):
		comboReady = false
		
	# resets jumps
	if is_on_floor():
		doubleJumpReady = true
		
	# resets hurt counter (to prevent infinite combos)
	if (isInState([HURT]) == false):
		hurtCount = 0
	
	# Y movement
	# gravity/wind
	if (windVect.y <= 0):
		velocity.y -= force_grav * delta
	elif (velocity.y >= 0):
		velocity.y -= force_grav * delta * -0.1 * windVect.y
	else:
		velocity.y -= force_grav * delta * -0.5 * windVect.y
	# caps y speed
	if (velocity.y >= 70):
		velocity.y = 70
	# launched
	if (state == JUMP):
		velocity.y = force_jump
	elif (state == DJUMP):
		velocity.y = force_jump_double
	elif (state == A_AH3_LAUNCH):
		velocity.y = force_jump_AH3
	elif (state == BOUNCE):
		velocity.y = bounceHeight
	elif (mini_jump_boost > 0):
		velocity.y = mini_jump_boost
		mini_jump_boost = 0
	elif (pogo) and (hitLanded) and isInState([A_SL, A_SH]):
		velocity.y = force_jump_double
		state = DJUMP
		pogo = false
	elif (pogo) and (hitLanded):
		velocity.y = force_jump * pogoMultiplier
		pogo = false
		if (playerChar == "Darla"):
			state = RISING
	
	# clears pogo on miss:
	if is_on_floor() and not isInState([A_SL, A_SH]):
		pogo = false
	
	# sets X speed
	if isInState([WALK, IDLE]):
		speed = speed_walk
	elif isInState([RUN, A_SL, A_SH, WAVE]):
		speed = speed_run
		
	# X movement
	if (wallSliding):
		pass
#	elif isInState([A_AH2]) and comboReady:
		
	elif isInState([WALK, RUN, JUMP, DJUMP, RISING, FALLING, BOUNCE, A_AL1, A_AL2, A_AL3, A_AH1, A_AH2, A_AH3_LAUNCH, A_AH3_RISE]):
		canMove = true
		velocity.x = speed * direction.x
		velocity.z = speed_z * direction.z
	elif isInState([HURTLAUNCH, HURTRISING, HURTFALLING]):
		pass
	else:
		velocity.x = 0
		velocity.z = 0
		
	# recoil
	if (recoilCounter > 0): 
		recoilCounter -= 1 
	if (recoilStart):
		forceHardLand = true
		canMove = false
		recoilStart = false
		recoilCounter = 30
		speed = speed_walk
		if (lookRight):
			recoilDir = 1
		else:
			recoilDir = -1
		velocity.y = 0.75 * force_jump_double
		if (state == A_SH) or (state == A_SL) or (state == A_H3):
			state = RISING
	if (recoilCounter > 0) and (is_on_floor() == false):
		velocity.x = -1.25 * speed * recoilDir
		velocity.z = 0
		
	# sliding
	if (isInState([A_SL, A_SH, WAVE]) == false):
		slideReady = true
	if (slideReady) and isInState([A_SL, A_SH, WAVE]):
		slideReady = false
		slideSpeed = speed_run * 2.0 #2.0
		slideDir.x = direction.x
		slideDir.y = direction.z
	elif isInState([A_SL, A_SH, WAVE]):
		velocity.x = slideSpeed * slideDir.x
		velocity.z = slideSpeed * (float(speed_z) / float(speed_run)) * slideDir.y
		if (slideSpeed > 0):
			if (playerChar == "Sasha"):
				slideSpeed -= 1.0
			elif (playerChar == "Marcy"):
				if isInState([A_SL]):
					slideSpeed -= 1.25
				else:
					slideSpeed -= 1.75
			elif (playerChar == "Darla"):
				if isInState([A_SL]):
					slideSpeed -= 1.25
				else:
					slideSpeed -= 0.75
			else:
				slideSpeed -= 1.25 # 1.5
		if (slideSpeed < 0):
			slideSpeed = 0
	
	# large knockback
	if isInState([HURTLAUNCH]):
		velocity.x = hurtDir.x
		velocity.y = hurtDir.y
		velocity.z = hurtDir.z
	
	# effect of windboxes
	if (windVect != Vector3.ZERO) and (!isInWindbox):
		if (is_on_floor()):
			windVect = Vector3.ZERO
		elif (direction.x * windVect.x <= 0) and (direction.z * windVect.z <= 0):
			windVect = Vector3.ZERO
	
	# Heavy Air attack 3
	if (isInState([A_AH3_HIT])) and !comboReady and (playerChar == "Maggie" or playerChar == "Sasha" or playerChar == "Marcy" or playerChar == "Darla"):
		canMove = true
		velocity.y = -3
		velocity.x = speed * direction.x
		velocity.z = speed_z * direction.z
		if playerChar == "Sasha" or playerChar == "Marcy" or playerChar == "Darla":
			velocity.x = 0
			velocity.z = 0
			velocity.y = 0 #-0.5
	elif (isInState([A_AH3_HIT])) and (playerChar == "Maggie" or playerChar == "Sasha" or playerChar == "Marcy" or playerChar == "Darla"):
		canMove = true
		velocity.x = speed * direction.x
		velocity.z = speed_z * direction.z
	elif (isInState([A_AH3_HIT])) and !comboReady:
		canMove = true
		velocity.y = -3
		velocity.x = speed * direction.x
		velocity.z = speed_z * direction.z
	elif (isInState([A_AH3_HIT])) and hitLanded:
		velocity.y = -50
		
	#wavedashing
	if (!is_on_floor()):
		isWavedashing = false
		waveVect = Vector3.ZERO
	if isWavedashing and (sign(velocity.x) == sign(waveVect.x)) and (sign(velocity.z) == sign(waveVect.z)) and (waveVect.length() <= 0.2*wavedashSpeed):
		isWavedashing = false
		waveVect = Vector3.ZERO
	if isWavedashing:
		velocity.x = sign(velocity.x)*0.1
		velocity.z = sign(velocity.z)*0.1
		waveVect *= 0.90
		if (abs(waveVect.x) <= 5) and ((abs(waveVect.z) <= 5)):
			waveVect = Vector3.ZERO
			isWavedashing = false

	
	#airdashing
	if (is_on_floor() or isInState([HURT, HURTLAUNCH, HURTFALLING, HURTRISING, HURTFLOOR])):
		isAirdashing = false
		airdashVect = Vector3.ZERO
	if isAirdashing:
		velocity.x = airdashVect.x
		velocity.y = 0
		velocity.z = 0
	
	# move and slide
	if isInState([JUMP, RISING, HURTLAUNCH, HURTRISING, BOUNCE]):
		snapVect = Vector3.ZERO
	else:
		snapVect = Vector3(0, -2, 0)
	
	velocity = move_and_slide_with_snap(velocity, snapVect, Vector3.UP, true, 4, 1.05)
	if (!isInState([BLOCK, BLOCKHIT, HURTFLOOR])) and (isInWindbox) and (invincibleGetUp <= 45):
		move_and_slide_with_snap(Vector3(windVect.x, 0, windVect.z), snapVect, Vector3.UP, true, 4, 1.05)
	if (isWavedashing):
		move_and_slide_with_snap(Vector3(waveVect.x, 0, waveVect.z), snapVect, Vector3.UP, true, 4, 1.05)
	
	# checks if player is sliding up a wall and corrects if necessary
#	if (is_on_wall() and ((direction.x * velocity.x > 0) or (direction.z * velocity.z > 0)) and (velocity.y > 0)):
#		for i in range (get_slide_count() - 1):
#			if (get_slide_collision(i).get_normal().y > 0):
#				wallSliding = true
#			else:
#				wallSliding = false
#	for i in range (get_slide_count() - 1):
#		var v1 = Vector2(velocity.x, velocity.z)
#		var v2 = Vector2(get_slide_collision(i).get_normal().x, get_slide_collision(i).get_normal().z)
#		if (v1.dot(v2) < -0.1):
#			wallSliding = true
#	if (is_on_floor()):
#		wallSliding = false
#	if wallSliding and velocity.y > 0:
#		velocity.y = 0

	# clears input buffer if near NPCs to prevent attacking when exiting zone
	if (nearNPCs > 0):
		clearInputBuffer()
	
	# fall off world
	if (translation.y <= deathFloorHeight):
		respawn(false)
	
	# animations
	if isInState([WALK]):
		anim.play("walk")
	if isInState([RUN]):
		anim.play("run")
	elif isInState([IDLE]):
		anim.play("idle")
	elif isInState([RISING]):
		anim.play("rise")
	elif isInState([FALLING]):
		anim.play("fall")
	elif isInState([LAND]):
		anim.play("land")
	elif isInState([LANDC]):
		anim.play("land_cancel")
	elif isInState([A_L1]):
		anim.play("attack_L1")
	elif isInState([A_L2]):
		anim.play("attack_L2")
	elif isInState([A_L3]):
		anim.play("attack_L3")
	elif isInState([A_H1]):
		anim.play("attack_H1")
	elif isInState([A_H2]):
		anim.play("attack_H2")
	elif isInState([A_H3]):
		anim.play("attack_H3")
	elif isInState([A_AL1]):
		anim.play("attack_air_L1")
	elif isInState([A_AL2]):
		anim.play("attack_air_L2")
	elif isInState([A_AL3]):
		anim.play("attack_air_L3")
	elif isInState([A_AH1]):
		anim.play("attack_air_H1")
	elif isInState([A_AH2]):
		anim.play("attack_air_H2")
	elif isInState([A_AH3_LAUNCH, A_AH3_RISE]):
		anim.play("attack_air_H3_rise")
	elif isInState([A_AH3_HIT]):
		anim.play("attack_air_H3_hit")
	elif isInState([A_AH3_LAND]):
		anim.play("attack_air_H3_land")
	elif isInState([A_SL]):
		anim.play("attack_slide_L")
	elif isInState([A_SH]):
		anim.play("attack_slide_H")
	elif isInState([WAVE]):
		anim.play("wave")
	elif isInState([BLOCK]):
		anim.play("block")
	elif isInState([BLOCKHIT]):
		anim.play("block_hit")
	elif isInState([COUNTER]):
		anim.play("counter")
	elif isInState([HURT]):
		anim.play("hurt")
		if hurtAgain:
			hurtAgain = false
			anim.seek(0)
	elif isInState([HURTRISING, HURTFALLING]):
		anim.play("hurt_air")
	elif isInState([HURTFLOOR]):
		anim.play("hurt_floor")
	elif isInState([KO]):
		anim.play("dead")
		
	# updates bottom of screen panel
	$playerInfo/lifeBar.value = 100 * float(hp/hpMax)
	$playerInfo/coinCounter.text = str(coins).pad_zeros(3)
	if (lives > 9):
		$playerInfo/lifeCounter.text = " "
	else:
		$playerInfo/lifeCounter.text = str(lives)
	if (isInState([HURT, HURTLAUNCH, HURTRISING, HURTFALLING, HURTFLOOR])):
		face.play("hurt")
	elif (hp <= 0.35 * hpMax):
		face.play("low")
	else:
		face.play("idle")
	
	# re-positions character if global flag is set
	if pg.playerFixPos[playerNum]:
		fixPlayerPos()
		pg.playerFixPos[playerNum] = false
	
	# testing prints
	#$Label.text = str(counterSpamTimer) + " - " + str(counterTimer)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#initialize(playerNum, translation)



func _on_AnimationPlayer_animation_finished(_anim_name):
	animFinished = true


func _on_hurtbox_area_entered(area):
	# prevents self hurting
	
	
	# evnironmental stuff
	if area.is_in_group("oneWayRight") or area.is_in_group("oneWayLeft"):
		area.get_parent().get_parent().get_node("Camera").disableBarriers(true)
		return
	elif area.is_in_group("respawnZones"):
		safePos = area.translation
		return
	elif area.is_in_group("boucePads"):
		if (bouncing == false):
			bouncing = true
		else:
			return
		bounceHeight = area.get_parent().bounceHeight
		area.get_parent().bounce()
		# play sfx
		soundManager.pitchSound("jump", 0.45)
		soundManager.playSound("jump")
		return
	elif area.is_in_group("windboxes"):
		isInWindbox = true
		windVect = area.direction.normalized() * area.magnitude
		return
	# pickups
	elif area.is_in_group("coins"):
		coins += area.get_parent().value
		# makes visual effect
		var vfx = vfxScene.instance()
		get_parent().add_child(vfx)
		vfx.playEffect("coin", 0.5*(translation + area.get_parent().translation))
		# removes coin
		area.get_parent().queue_free()
		# plays sfx
		soundManager.pitchSound("coin1", rng.rand.randf_range(0.9, 1.2))
		soundManager.playSound("coin1")
		return
	elif area.is_in_group("healthTiny"):
		# prevents self healing
		if (area.get_parent().playerNum == playerNum):
			return
		# heals
		addHealth(10)
		# makes visual effect
		var vfx = vfxScene.instance()
		get_parent().add_child(vfx)
		vfx.playEffect("health", 0.5*(translation + area.get_parent().translation))
		# removes item
		area.get_parent().queue_free()
		# plays sfx
		soundManager.playSound("pickup")
		return
	elif area.is_in_group("healthSmall"):
		addHealth(0.25*hpMax)
		# makes visual effect
		var vfx = vfxScene.instance()
		get_parent().add_child(vfx)
		vfx.playEffect("health", 0.5*(translation + area.get_parent().translation))
		# removes item
		area.get_parent().queue_free()
		# plays sfx
		soundManager.playSound("pickup")
		return
	elif area.is_in_group("healthBig"):
		addHealth(hpMax)
		# makes visual effect
		var vfx = vfxScene.instance()
		get_parent().add_child(vfx)
		vfx.playEffect("health", 0.5*(translation + area.get_parent().translation))
		# removes item
		area.get_parent().queue_free()
		# plays sfx
		soundManager.playSound("pickup")
		return
	elif area.is_in_group("1up"):
		addLives(1)
		# makes visual effect
#		var vfx = vfxScene.instance()
#		get_parent().add_child(vfx)
#		vfx.playEffect("health", 0.5*(translation + area.get_parent().translation))
		# removes item
		area.get_parent().queue_free()
		# plays sfx
		soundManager.playSound("1up")
		return
	# HURTBOX COLISSION
	# handles attack if projectile, sets attacker and attackerLocation variables
	var attacker = area.get_parent().get_parent()
	# checks if player is hitting self
	if attacker.is_in_group("players") or attacker.is_in_group("playerProjectiles"):
		if !pg.pvp or (attacker.playerNum == playerNum):
			return
		else:
			attacker.hitLanded = true
	# NOTE: Commenting this out likely broke arrow launcher test scenes.
	# But those will be re-made to closer match player projectiles anyway, so
	# for now attackers will be defined as above for all impacts.
#	if area.is_in_group("projectiles"):
#		attacker = area.get_parent()
#	else:
#		attacker = area.get_parent().get_parent()
	# Enemy hitboxes:
	if (invincible == false) and (invincibleState == false) and (invincibleGetUp <= 0) and (pg.dontMove == false):
		justHurt = true
	else:
		return
	invincible = true
	
	var attackerLoc = attacker.global_transform.origin
	if area.is_in_group("bosses"):
		attackerLoc += attacker.get_node("boss").translation
	# makes visual effect
	var vfx = vfxScene.instance()
	get_parent().add_child(vfx)
	vfx.playEffect("hit", 0.5*(translation + attackerLoc))
	# stores damage/knockback variables
	hurtDamage = attacker.hitDamage
	hurtType = attacker.hitType
	hurtDir = attacker.hitDir
	# sets up piercing damage
	if (hurtType == KB_WEAK_PIERCE):
		hurtType = KB_WEAK
		hurtPierced = true
	elif (hurtType == KB_STRONG_PIERCE):
		hurtType = KB_STRONG
		hurtPierced = true
	elif (hurtType == KB_ANGLED_PIERCE):
		hurtType = KB_ANGLED
		hurtPierced = true
	else:
		hurtPierced = false
	# changes attack to launching if "dead"
	if (hurtType == KB_WEAK) and (hp <= 0):
		hurtType = KB_ANGLED
		hurtDir = Vector3(10, 25, 0)
	# changes x-z knokback angle to be away from attacker if an angled attack
	if (hurtType == KB_ANGLED):
		var mag = abs(attacker.hitDir.x)
		var vp = Vector2(translation.x, translation.z)
		var va = Vector2(attackerLoc.x, attackerLoc.z)
		var newDir = Vector2.ZERO
		newDir = vp - va
		newDir = newDir.normalized() * mag
		hurtDir.x = newDir.x
		hurtDir.z = newDir.y
	
		

func _on_hurtbox_area_exited(area):
	if area.is_in_group("oneWayRight") or area.is_in_group("oneWayLeft"):
		area.get_parent().get_parent().get_node("Camera").disableBarriers(false)
		return
	elif area.is_in_group("boucePads"):
		bouncing = false
		return
	elif area.is_in_group("windboxes"):
		isInWindbox = false
		return
	else:
		invincible = false
		return
