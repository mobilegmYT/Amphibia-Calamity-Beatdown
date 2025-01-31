extends Node

# player variables
var playerStartingMaxHP = 100 #100
var playerStartingLives = 3 #3
var totalMoney = 280
var newMoney = 0
var kills = 0 # Used to count in ambushes
var killsTotal = 0 # Used to count total kills

# upgrades
var healthUpgrades = 0 # 20 per upgrade, max 3
var livesUpgrades  = 0 # 1 life per upgrade, max 3
var damageUpgrades = 0 # 20% per upgrade, max 3
var luckUpgrades   = 0 # increase coin drop by 1 and drop chances by 5%, max 3. Influences barrel drops.
const healthBoost  = 20
const livesBoost   = 1
const damageBoost  = 0.2
const coinBoost    = 1
const dropBoost    = 0.05
const techBoost    = 0.15


# attack unlocks
var hasSpin    = true
var hasSlide   = true
var hasAirSpin = true
var hasDJ      = true
var hasCounter = true

# numer of players / player inputs
var availableInputs = ["k0"]
var playerActive = [false, false, false, false]
var playerReady = [true, true, true, true]
var playerAlive = [false, false, false, false]
var playerInput = ["X", "X", "X", "X"]
var playerCharacter = ["Anne", "Anne", "Anne", "Anne"]
var playerLives = [0, 0, 0, 0]
var playerCoins = [0, 0, 0, 0]
var playerHealth = [100, 100, 100, 100]
var numPlayers = 1
var playerFixPos = [false, false, false, false]

# cheats
var unlimitedLives = false
var unlimitedMoney = false
var hardcoreMode   = false
var allCharsMode   = false
var easyMode       = false
var hardMode       = false

# PVP flag
var pvp = false
 
# destination level info
var levelName = "test"
var levelNameDisc = "test"
var levelMusic = "ripple"
var levelNum = 0

# playable characters
var hasMarcy  = true
var hasSasha  = true
var hasSprig = true
var hasMaggie = true
var hasGrime = false
var hasDarla = false
var availableChars = ["Anne"]

var clover = false

# Completed levels
#                     [Wartwood, Test,  l1,    l2,    l3,    l4,    l5,    l6,    l7,    l8,    l9,   final]
var completedLevels = [  true,   true, true, true, false, false, false, false, false, false, false, false]
var unlockedFinalLevel = false

# game over stuff
var GOCount = 0

# pauses player for cutscenes/other events
var dontMove = false
var inCutscene = false

# wartwood flags
var seenToadstool = false
var seenMaddie = false
var firstTimeInWartwood = true
var currentStore = 0 # 0 = none; 1 = city hall; 2 = Maddie; 3 = Felicia

# other flags
var seenTutorial = false
var karting = false
var initialSpawn = true
var dropPlayerEnabled = true

# debug flags
var debugCameraAvailable = false

# localization
var prefLang = "en"

func recalcInfo():
	# characters
	availableChars = ["Anne"]
	if hasSprig or allCharsMode:
		availableChars.append("Sprig")
	if hasSasha or allCharsMode:
		availableChars.append("Sasha")
	if hasMarcy or allCharsMode:
		availableChars.append("Marcy")
	if hasGrime or allCharsMode:
		availableChars.append("Grime")
	if hasMaggie or allCharsMode:
		availableChars.append("Maggie")
	if hasDarla and clover:
		availableChars.append("Darla")
	# inputs
	checkAvailableInputs()

func checkAvailableInputs():
	availableInputs = ["k0"]
	for i in range(0, len(Input.get_connected_joypads())):
		availableInputs.append(str(i))

func _process(delta):
	#print(playerCoins)
	pass
	
# Called when the node enters the scene tree for the first time.
func _ready():
	# localization
	TranslationServer.set_locale(prefLang)
	

func cycleLocale():
	var curLangIndex = TranslationServer.get_loaded_locales().find(prefLang) + 1
	if (curLangIndex >= len(TranslationServer.get_loaded_locales())):
		curLangIndex = 0
	prefLang = TranslationServer.get_loaded_locales()[curLangIndex]
	TranslationServer.set_locale(prefLang)
	
func countPlayers():
	var count = 0
	for i in playerAlive:
		if i:
			count += 1
	return count

# returns number of completed levels. Note Wartwood and the test playground are levels
# 0 and 1 and are not included in the count
func countCompletedLevels():
	var count = 0
	for i in completedLevels:
		if i:
			count += 1
	#removes levels 0 and 1
	count -= 2
	if count <= 0:
		count = 0
	return count
	

func backToMapLose():
	soundManager.stopMusic()
	tran.loadLevel("res://scenes/menus/mapOpen.tscn")
	
func endLevel():
	# prevents player actions
	dontMove = true
	# stops music
	soundManager.FadeOutSong(levelMusic)
	# plays transitioner to fade and open tally scene
	tran.endLevel()
	
func spend(amount):
	totalMoney -= amount
	if (totalMoney <= 0):
		totalMoney = 0
