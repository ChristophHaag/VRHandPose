extends Spatial

var skel
var t
var id = []
var idNum = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var speed
var count = 0
var degree = 0
var reverse = false
var manualId
var label
var outD = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var halfD = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var inD = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var direction = -1
var idTable = [11,8,5,2,14]

func _ready():
	skel = get_node("Armature/Skeleton")
	id = [skel.find_bone("pointer_2"), skel.find_bone("pointer_3"), skel.find_bone("pointer_4"), skel.find_bone("middle_2"),skel.find_bone("middle_3"),skel.find_bone("middle_4"),skel.find_bone("ring_2"),skel.find_bone("ring_3"),skel.find_bone("ring_4"),skel.find_bone("pinky_2"),skel.find_bone("pinky_3"),skel.find_bone("pinky_4"),skel.find_bone("thumb_2"),skel.find_bone("thumb_3"),skel.find_bone("thumb_4"),skel.find_bone("wrist")]
	set_process(false)
	set_physics_process(false)
	label = get_node("/root/Main/GUI_Right_Hand")
	var bone
	var wrist
	var half
	var close
	wrist = to_global(skel.get_bone_global_pose(id[15]).origin)
	for n in range(5):
		bone = to_global(skel.get_bone_global_pose(id[idTable[n]]).origin)
		outD[n] = (bone.distance_to(wrist))
		half = outD[n]/1.2
		close = half/1.5
		halfD[n] = half
		inD[n] = close

func pose(pose):
		if pose == "finger_out":
			reset()
			speed = -3
			for n in range(3):
				idNum[n] = speed
			set_process(true)
		elif pose == "finger_in":
			reset()
			speed = 3
			for n in range(3):
				idNum[n] = speed
			reverse = true
			set_process(true)
		elif pose == "fist":
			reset()
			speed = -3
			for n in range(12):
				idNum[n] = speed
			set_process(true)
		elif pose == "default":
			reset()
			speed = 3
			for n in range(12):
				idNum[n] = speed
			reverse = true
			set_process(true)

func _process(delta):
	if reverse == false:
		if count < 20:
			callR(delta)
			count += 1
			degree += 1
	elif reverse == true:
		if degree > 0:
			callR(delta)
			degree -= 1

func findPose():
	var fingers = ["","","","",""]
	var pose
	var bone
	var wrist = to_global(skel.get_bone_global_pose(id[15]).origin)
	var distance

	for n in range(5):
		bone = to_global(skel.get_bone_global_pose(id[idTable[n]]).origin)
		distance = (bone.distance_to(wrist))
		if distance > halfD[n]:
			fingers[n] = "Out"
		elif distance > inD[n]:
			fingers[n] = "Half"
		else:
			fingers[n] = "In"
		
	if fingers[0] == "Out" && fingers[1] == "Out" && fingers[2] == "Out" && fingers[3] == "Out" && fingers[4] == "Out":
		pose = "Default"
	elif fingers[0] == "Out" && fingers[1] == "In" && fingers[2] == "In" && fingers[3] == "Out" && fingers[4] == "Out":
		pose = "Spiderman"
	elif fingers[0] == "In" && fingers[1] == "In" && fingers[2] == "Out" && fingers[3] == "Out" && fingers[4] == "In":
		pose = "Peace"
	else:
		pose = "Unknown"
	
	
	
	var text
	if direction == -1:
		text = "Default"
	else:
		text = "Reversed"
	label.setText(fingers[0],fingers[1],fingers[2],fingers[3],fingers[4],pose,text)

func getData(num):
	manualId = id[num]
	set_physics_process(true)
	
func changeDirection():
	direction = direction*-1
	
func _physics_process(delta):
	t = skel.get_bone_pose(manualId)
	t = t.rotated(Vector3(direction*1.0, 0.0, 0.0), 0.5 * delta)
	skel.set_bone_pose(manualId, t)
	
func r(num,v,x,delta):
	t = skel.get_bone_pose(num)
	t = t.rotated(v, x * delta)
	skel.set_bone_pose(num, t)

func callR(delta):
	for n in range(14):
		r(id[n],Vector3(1.0, 0.0, 0.0),idNum[n],delta)

func reset():
	for n in range(14):
		idNum[n] = 0
		count = 0
		reverse = false
		
