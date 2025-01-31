extends KinematicBody

var vfxScene = preload("res://scenes/vfx.tscn")
var coinScene = preload("res://scenes/pickups/coin.tscn")
var khaoScene = preload("res://scenes/pickups/khao.tscn")
var mushScene = preload("res://scenes/pickups/mush.tscn")
var debrisScene = preload("res://scenes/enemies/spawners/debris.tscn")

onready var animDamage = $AnimationPlayerDamage
onready var animSpawn = $AnimationPlayerSpawn

var active = false
var counterSpawn = false # a flag that checks if the nest has been hit. Nests will spawn at the next opportunuty if this is true.
var invincible = false
var dead = false
export var decoration = false
export var hp = 60
export var oddsSpawn = 0.2
export var maxSpawns = 8
var spawnCount = 0
var velocity = Vector3.ZERO

export var maxCoins = 20
export var minCoins = 15
export var oddsDrop = 1.0 
export var oddsKhao = 0.20 

var fallDir = Vector3.ZERO

func spawn():
	var num = rng.rand.randi_range(1, 2)
	for i in range(0, num):
		var nextEnemy = nme.paperWaspScene.instance()
		get_parent().add_child(nextEnemy)
		nextEnemy.initialize(nme.paperWasp, translation + fallDir + Vector3(rng.rand.randf_range(-0.8, 0.8), 0, rng.rand.randf_range(-0.8, 0.8)), Vector3.ZERO, true, true, true)
	spawnCount += num

func spawnMore():
	for i in range(0, 2):
		var nextEnemy = nme.paperWaspScene.instance()
		get_parent().add_child(nextEnemy)
		nextEnemy.initialize(nme.paperWasp, translation + Vector3(0, 1, 0), Vector3.ZERO, true, true, false)
	for i in range(0, 2):
		var nextEnemy = nme.waspScene.instance()
		get_parent().add_child(nextEnemy)
		nextEnemy.initialize(nme.wasp, translation + Vector3(0, 1, 0), Vector3.ZERO, false, true, false)
	
func despawn():
	# update drop counts/odds
	minCoins += (pg.luckUpgrades * pg.coinBoost)
	maxCoins += (pg.luckUpgrades * pg.coinBoost)
	oddsDrop += (pg.luckUpgrades * pg.dropBoost)
	#print(oddsDrop)
	queue_free()
	# spawns items/money
	var coinsLeft = rng.rand.randi_range(minCoins, maxCoins)
	while (coinsLeft > 0):
		if (coinsLeft >= 20):
			var coins = coinScene.instance()
			get_parent().add_child(coins)
			coins.initialize(translation + Vector3(0, 0.5, 0), 20)
			coinsLeft -= 20
		elif (coinsLeft >= 5):
			var coins = coinScene.instance()
			get_parent().add_child(coins)
			coins.initialize(translation + Vector3(0, 0.5, 0), 5)
			coinsLeft -= 5
		else:
			var coins = coinScene.instance()
			get_parent().add_child(coins)
			coins.initialize(translation + Vector3(0, 0.5, 0), 1)
			coinsLeft -= 1
	var food = null
	if (rng.rand.randf() <= oddsDrop):
		food = mushScene.instance()
		if (rng.rand.randf() <= oddsKhao):
			food = khaoScene.instance()
		get_parent().add_child(food)
		food.initialize(translation + Vector3(0, 0.5, 0))
	# spawns debris
	var debris = null
	# makes one of everything
	for i in range (0, 5):
		debris = debrisScene.instance()
		get_parent().add_child(debris)
		debris.initialize(translation + Vector3(0, -1, 0), 5)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$modelZero/pivot.rotation = rotation
	fallDir = Vector3(1, 0, 1).rotated(Vector3.UP, rotation.y)
	rotation = Vector3.ZERO
	print(fallDir)


func _process(delta):
	# despawns when it hits the ground
	if is_on_floor():
		despawn()
		spawnMore()
	# falls if dead
	if dead:
		$modelZero/pivot/nest.rotate_z(-1.25*PI*delta)
		velocity.x = fallDir.x * 400 * delta
		velocity.z = fallDir.z * 400 * delta
		velocity.y -= 80 * delta
		velocity = move_and_slide_with_snap(velocity, Vector3(0, 1, 0), Vector3.UP, true)

func _on_hurtbox_area_entered(area):
	if invincible or dead or decoration:
		return
	# identifies attacker
	var attacker = area.get_parent().get_parent()
	# stores damage/knockback variables
	hp -= attacker.hitDamage
	# tells attacker that the hit occurred
	attacker.hitLanded = true
	# signals attacker to recoil if necessary
	if (attacker.playerChar != "proj") and (attacker.hitType == attacker.KB_STRONG_RECOIL):
		attacker.recoilStart = true
	# plays animation
	if (hp > 0):
		animDamage.play("hurt")
	else:
		animDamage.play("dead")
		active = false
	# plays sfx
	soundManager.playSound(attacker.hitSound)
	# makes enemy unhittable until it leaves a hitbox
	invincible = true
	# Produces hit vfx
	var vfx = vfxScene.instance()
	get_parent().add_child(vfx)
	vfx.playEffect("hit", 0.5*(translation + attacker.translation))
	# prepares a counterattack
	counterSpawn = true


func _on_hurtbox_area_exited(_area):
	invincible = false


func _on_AnimationPlayerDamage_animation_finished(anim_name):
	match anim_name:
		"hurt":
			animDamage.play("idle")
		"dead":
			dead = true
			velocity.y = 20
			animDamage.play("idle")


func _on_spawnDelay_timeout():
	if active and (spawnCount < maxSpawns):
		spawn()


func _on_aggro_area_entered(area):
	active = true


func _on_AnimationPlayerSpawn_animation_finished(anim_name):
	match anim_name:
		"idle":
			if (rng.rand.randf() < oddsSpawn) or counterSpawn:
				$spawnTimer.start()
				animSpawn.play("spawn")
			else:
				animSpawn.play("idle")
		"spawn":
			counterSpawn = false
			animSpawn.play("idle")


func _on_aggroTimer_timeout():
	$aggro/CollisionShape.disabled = false


func _on_aggro_area_exited(area):
	active = false
	# turns off the collision and re-activates it after a short time to re-check is a player is still in range
	# done this way to account for multiple players
	$aggro/CollisionShape.disabled = true
	$aggro/aggroTimer.start()

