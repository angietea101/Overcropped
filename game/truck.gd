extends Area2D

@onready var amount = $TruckSprite/TextBubbleSprite/Amount
@onready var truck_sprite = $TruckSprite
@onready var texture_rect = $TruckSprite/TextBubbleSprite/TextureRect
@onready var deadline_timer = $TruckSprite/DeadlineTimer
@onready var return_timer = $TruckSprite/ReturnTimer
@onready var score_count = get_node("../HUD")
signal delivery_fail
var amount_needed
var rng = RandomNumberGenerator.new()
const assets_folder = "res://assets/"
var crops_png = ["carrot.png", "corn.png", "potato.png", "radish.png", "tomato.png"]
var crop
var tween
const Grabbable = preload("res://game/grabbables/grabbable.gd")
const crops_name = ["carrot.png", "corn.png", "potato.png", "radish.png", "tomato.png"]
const truck_complete = preload("res://assets/truck_order_complete.png")
const truck_incomplete = preload("res://assets/truck_order.png")
var delivered: bool


# Called when the node enters the scene tree for the first time.
func _ready():
	truck_sprite.position = Vector2(200, 0)
	_enter_scene()
	
	
func _enter_scene():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(truck_sprite, "position", Vector2(0, 0), 5).set_trans(Tween.TRANS_LINEAR)
	truck_sprite.texture = truck_incomplete
	delivered = false
	_generate_amount()
	_generate_crop()
	deadline_timer.wait_time = rng.randi_range(36, 58)
	deadline_timer.start()
	
	
func _leave_scene():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(truck_sprite, "position", Vector2(300, 0), 3).set_trans(Tween.TRANS_LINEAR)
	return_timer.wait_time = rng.randi_range(3, 10)
	return_timer.start()


func _generate_amount():
	amount_needed = 1  # rng.randi_range(1, 10)
	if str(amount_needed).length() == 1:
		amount.text = " " + str(amount_needed)
	else:
		amount.text = str(amount_needed)
	
	
func _generate_crop():
	var random_index = rng.randi_range(0, crops_png.size() - 1)
	var random_crop = crops_png[random_index]
	crop = random_index + 1
	print("NEEDED: ", crop)
	texture_rect.texture = load(assets_folder + random_crop)


func _on_deadline_timer_timeout():
	deadline_timer.stop()
	score_count.decrease_score(20)
	delivered = false
	delivery_fail.emit()
	_leave_scene()


func _on_return_timer_timeout():
	return_timer.stop()
	_enter_scene()


func _on_delivery_area_area_entered(area):
	var parent_node = area.get_parent()
	var player = parent_node.get_parent().get_parent()
	# If player enters area, ignore
	if parent_node == player:
		return
	# If a crop is within our range, submit the order
	if parent_node is Grabbable and not parent_node.plantable and crop == parent_node.seed_type and not delivered:
		truck_sprite.texture = truck_complete
		score_count.increase_score()
		player.release_current_held_item()
		_leave_scene()
	elif parent_node is Grabbable and crop != parent_node.seed_type:
		delivered = false
		delivery_fail.emit()
		score_count.decrease_score(10)
		player.release_current_held_item()
		_leave_scene()
