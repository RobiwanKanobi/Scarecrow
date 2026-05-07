extends StaticBody3D

@export var resource_id: String = "straw"
@export var display_name: String = "Resource"
@export var amount_per_harvest: int = 1
@export var max_harvests: int = 3
@export var secondary_resource_id: String = ""
@export var secondary_amount: int = 1

var harvests_remaining: int = 0
var _depleted: bool = false
var _visual: MeshInstance3D

func _ready() -> void:
	harvests_remaining = max_harvests
	_visual = get_node_or_null("Visual")
	add_to_group("resource_nodes")

func interact(_player: Node) -> void:
	if _depleted:
		GameEvents.message_requested.emit("%s is depleted." % display_name)
		return
	_harvest()

func _harvest() -> void:
	var inventory := get_tree().get_first_node_in_group("inventory_manager")
	if inventory:
		inventory.add_item(resource_id, amount_per_harvest)
		GameEvents.message_requested.emit("Collected %d %s" % [amount_per_harvest, resource_id])
		if secondary_resource_id != "":
			inventory.add_item(secondary_resource_id, secondary_amount)
			GameEvents.message_requested.emit("Also collected %d %s" % [secondary_amount, secondary_resource_id])

	harvests_remaining -= 1
	if harvests_remaining <= 0:
		_deplete()

func _deplete() -> void:
	_depleted = true
	if _visual:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		_visual.material_override = mat

	var col := get_node_or_null("CollisionShape3D")
	if col:
		(col as CollisionShape3D).disabled = true

	var timer := get_tree().create_timer(20.0)
	timer.timeout.connect(queue_free)
