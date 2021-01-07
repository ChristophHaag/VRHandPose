extends ARVRController

# The velocity the controller is moving at (calculated using physics frames)
var controller_velocity = Vector3(0,0,0)
# The controller's previous position (used to calculate velocity)
var prior_controller_position = Vector3(0,0,0)
# The last 30 calculated velocities (1/3 of a second worth of velocity calculations,
# assuming the game is running at 90 FPS)
var prior_controller_velocities = []

# The hand mesh, used to represent the player's hand when they are not holding anything.
var hand_mesh
var hand
var keypoints

# The Area node used to grab objects.
var grab_area
# The current grab mode
var grab_mode = "AREA"

# The dead zone for both the trackpad and the joystick.
# See (http://www.third-helix.com/2013/04/12/doing-thumbstick-dead-zones-right.html)
# for more information on what dead zones are, and how we are using them.
#
# Notice that we are using a really large dead zone. This is because we do not want to move
# the player if they barely bump the trackpad/joystick.
const CONTROLLER_DEADZONE = 0.65

# The speed the player moves at when moving using the trackpad and/or joystick.
const MOVEMENT_SPEED = 1.5

# A boolean to track whether the player is moving using this controller.
# This is needed for the vignette effect that shows only when the player is moving.
var directional_movement = false

func _ready():

	# Get the hand mesh
	hand_mesh = get_node("Left Hand")
	hand = get_node("Left Hand/Armature/Skeleton/Hand")
	keypoints = get_node("Left Hand/Armature/Skeleton/Keypoints")
	hand_mesh.visible = true
	hand.visible = true
	keypoints.visible = false
	
	
	# Get the grab related nodes
	grab_area = get_node("Area")
	grab_mode = "AREA"
	
	# Connect the VR buttons
	connect("button_pressed", self, "button_pressed")
	connect("button_release", self, "button_released")


func _physics_process(delta):
		
	# Controller velocity
	# --------------------
	# Update velocity, IF there is a controller active for this controller (left/right hand)
	if get_is_active() == true:
		
		# Reset the controller velocity
		controller_velocity = Vector3(0,0,0)
		
		# Add the following lines if you want to use the velocity
		# calculations from before.
		# Using the prior calculations gives a smoother throwing/catching
		# experience, though it is not perfect...
		# Add the previous controller velocities
		if prior_controller_velocities.size() > 0:
			for vel in prior_controller_velocities:
				controller_velocity += vel
			
			# Get the average velocity, instead of just adding them together.
			controller_velocity = controller_velocity / prior_controller_velocities.size()
		
		# Add the most recent controller velocity to the list of propr controller velocities
		# (not needed if you are not using the controller's prior velocities)
		prior_controller_velocities.append((global_transform.origin - prior_controller_position) / delta)
		
		# If you want to only use the last frame's position to calculate velocity, then
		# only use the two lines of code below (and not the ones with prior_controller_velocities above!)
		# Calculate the velocity using the controller's prior position.
		controller_velocity += (global_transform.origin - prior_controller_position) / delta
		prior_controller_position = global_transform.origin
		
		# If we have more than a third of a seconds worth of velocities, then we
		# should remove the oldest (not needed if you are not using the controller's prior velocities)
		if prior_controller_velocities.size() > 30:
			prior_controller_velocities.remove(0)
	
	# --------------------
	

	# Directional movement
	# --------------------
	# First we need to convert the VR axes to Vectors.
	# We do this for both the trackpad and the joystick.
	# 
	# NOTE: you may need to change this depending on which VR controllers
	# you are using and which OS you are on.
	var trackpad_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
	var joystick_vector = Vector2(-get_joystick_axis(5), get_joystick_axis(4))
	
	# Account for dead zones on both the trackpad and the joystick, starting with the trackpad.
	# See the link at CONTROLLER_DEADZONE for an explanation of how this code works!
	if trackpad_vector.length() < CONTROLLER_DEADZONE:
		trackpad_vector = Vector2(0,0)
	else:
		trackpad_vector = trackpad_vector.normalized() * ((trackpad_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# Account for dead zones on the the joystick
	if joystick_vector.length() < CONTROLLER_DEADZONE:
		joystick_vector = Vector2(0,0)
	else:
		joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	# Get the VR camera's forward and right directional/local-space vectors
	var forward_direction = get_parent().get_node("ARVRCamera").global_transform.basis.z.normalized()
	var right_direction = get_parent().get_node("ARVRCamera").global_transform.basis.x.normalized()
	
	# Calculate how much we will move by adding both the trackpad and the joystick vectors together
	# and normalizing them.
	var movement_vector = (trackpad_vector + joystick_vector).normalized()
	
	# Calculate how far we will move forward/backwards and right/left, using the camera's directional/local-space vectors.
	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED
	
	# Remove movement on the Y axis so the player cannot fly/fall by moving
	movement_forward.y = 0
	movement_right.y = 0
	
	# Move the player if there is any movement forward/backwards or right/left.
	if (movement_right.length() > 0 or movement_forward.length() > 0):
		get_parent().translate(movement_right + movement_forward)
		directional_movement = true
	else:
		directional_movement = false
	# --------------------


func button_pressed(button_index):
	
	# If the trigger is pressed...
	if button_index == 15:
	
		get_node("Left Hand").pose("finger_out")
	
	
	# If the grab button is pressed...
	if button_index == 2:
		get_node("Left Hand").pose("fist")
	
		
	# If the menu button is pressed...
	if button_index == 1:
		keypoints.visible = true
		hand.visible = false
		

func button_released(button_index):
	
	# If the trigger button is released...
	if button_index == 15:
		get_node("Left Hand").pose("finger_in")
	if button_index == 2:
		get_node("Left Hand").pose("default")
	if button_index == 1:
		keypoints.visible = false
		hand.visible = true
	

func _on_Area_body_entered(body):
	if body.name.right(8) == "1L":
		get_node("Left Hand").getData(11)
	elif body.name.right(8) == "2L":
		get_node("Left Hand").getData(10)
	elif body.name.right(8) == "3L":
		get_node("Left Hand").getData(9)
	elif body.name.right(8) == "4L":
		get_node("Left Hand").getData(8)
	elif body.name.right(8) == "5L":
		get_node("Left Hand").getData(7)
	elif body.name.right(8) == "6L":
		get_node("Left Hand").getData(6)
	elif body.name.right(8) == "7L":
		get_node("Left Hand").getData(5)
	elif body.name.right(8) == "8L":
		get_node("Left Hand").getData(4)
	elif body.name.right(8) == "9L":
		get_node("Left Hand").getData(3)
	elif body.name.right(8) == "10L":
		get_node("Left Hand").getData(2)
	elif body.name.right(8) == "11L":
		get_node("Left Hand").getData(1)
	elif body.name.right(8) == "12L":
		get_node("Left Hand").getData(0)
	elif body.name.right(8) == "13L":
		get_node("Left Hand").getData(12)
	elif body.name.right(8) == "14L":
		get_node("Left Hand").getData(13)
	elif body.name == "Reverse Button":
		get_node("Left Hand").changeDirection()
	

func _on_Area_body_exited(_body):
	get_node("Left Hand").set_physics_process(false)
	get_node("Left Hand").findPose()
