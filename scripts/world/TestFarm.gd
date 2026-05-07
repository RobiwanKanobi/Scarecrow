extends Node3D

const RESOURCE_NODE_SCENE := preload("res://scenes/resources/ResourceNode.tscn")

# Resource node definitions: [resource_id, display_name, max_harvests, color, secondary_id, secondary_amt, positions]
const SPRITE_PATHS: Dictionary = {
	"straw": "res://art/sprites/resource_hay.png",
	"stick": "res://art/sprites/resource_twigs.png",
	"stone": "res://art/sprites/resource_rock.png",
	"cloth": "res://art/sprites/resource_cloth.png",
	"berry": "res://art/sprites/resource_berries.png",
}

const RESOURCE_DEFS: Array = [
	{
		"resource_id": "straw", "display_name": "Hay Pile",
		"amount": 2, "max_harvests": 3,
		"secondary_id": "", "secondary_amt": 0,
		"positions": [Vector3(-5, 0, -5), Vector3(5, 0, -3), Vector3(-8, 0, 3), Vector3(0, 0, 7)],
	},
	{
		"resource_id": "stick", "display_name": "Twig Bush",
		"amount": 1, "max_harvests": 2,
		"secondary_id": "", "secondary_amt": 0,
		"positions": [Vector3(7, 0, 5), Vector3(-6, 0, 7), Vector3(9, 0, -6)],
	},
	{
		"resource_id": "stone", "display_name": "Rock",
		"amount": 1, "max_harvests": 3,
		"secondary_id": "", "secondary_amt": 0,
		"positions": [Vector3(3, 0, -8), Vector3(-10, 0, -2), Vector3(10, 0, 2), Vector3(-4, 0, -12)],
	},
	{
		"resource_id": "cloth", "display_name": "Cloth Line",
		"amount": 1, "max_harvests": 2,
		"secondary_id": "", "secondary_amt": 0,
		"positions": [Vector3(-3, 0, 9), Vector3(8, 0, -9)],
	},
	{
		"resource_id": "berry", "display_name": "Berry Bush",
		"amount": 2, "max_harvests": 3,
		"secondary_id": "seed", "secondary_amt": 1,
		"positions": [Vector3(5, 0, 8), Vector3(-7, 0, -9), Vector3(12, 0, -3)],
	},
]

func _ready() -> void:
	_create_ground()
	_place_boundary_walls()
	_place_resources()

func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(42.0, 42.0)
	ground.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.42, 0.18)
	ground.material_override = mat
	add_child(ground)

	var ground_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(42.0, 0.2, 42.0)
	col.shape = shape
	ground_body.position = Vector3(0.0, -0.1, 0.0)
	ground_body.add_child(col)
	add_child(ground_body)

func _place_boundary_walls() -> void:
	var walls: Array = [
		[Vector3(0.0, 1.0, 21.0), Vector3(42.0, 2.0, 1.0)],
		[Vector3(0.0, 1.0, -21.0), Vector3(42.0, 2.0, 1.0)],
		[Vector3(21.0, 1.0, 0.0), Vector3(1.0, 2.0, 42.0)],
		[Vector3(-21.0, 1.0, 0.0), Vector3(1.0, 2.0, 42.0)],
	]
	for w: Array in walls:
		var wall := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = w[1]
		col.shape = shape
		wall.position = w[0]
		wall.add_child(col)
		add_child(wall)

func _place_resources() -> void:
	for def: Dictionary in RESOURCE_DEFS:
		for pos: Vector3 in def["positions"]:
			var node: Node3D = RESOURCE_NODE_SCENE.instantiate()
			node.resource_id = def["resource_id"]
			node.display_name = def["display_name"]
			node.amount_per_harvest = def["amount"]
			node.max_harvests = def["max_harvests"]
			node.secondary_resource_id = def["secondary_id"]
			node.secondary_amount = def["secondary_amt"]
			node.position = pos

			# Assign the correct sprite texture per resource type
			var sprite := node.get_node_or_null("Sprite3D") as Sprite3D
			if sprite and SPRITE_PATHS.has(def["resource_id"]):
				var tex := load(SPRITE_PATHS[def["resource_id"]]) as Texture2D
				if tex:
					sprite.texture = tex
					var mat := sprite.material_override as StandardMaterial3D
					if mat:
						mat = mat.duplicate() as StandardMaterial3D
						mat.albedo_texture = tex
						sprite.material_override = mat

			add_child(node)
