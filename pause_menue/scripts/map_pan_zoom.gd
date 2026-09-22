class_name MapPanZoom extends Control

@export var min_zoom : float = 0.5
@export var max_zoom : float = 4.0
@export var zoom_step : float = 0.15
@export var pan_speed : float = 600.0
@export var edge_margin : float = 150.0

var _dragging : bool = false
var _drag_last_mouse : Vector2



func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pass


func _process( delta : float ) -> void:
	if not visible:
		return
	var pan_dir : Vector2 = Vector2(
		Input.get_axis( "left", "right" ),
		Input.get_axis( "up", "down" )
	)
	if pan_dir != Vector2.ZERO:
		position -= pan_dir * pan_speed * delta
		_clamp_position()
	pass


func _gui_input( event : InputEvent ) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_step( zoom_step )
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_step( -zoom_step )
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			if _dragging:
				_drag_last_mouse = get_parent().get_local_mouse_position()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var mouse_now : Vector2 = get_parent().get_local_mouse_position()
		position += mouse_now - _drag_last_mouse
		_drag_last_mouse = get_parent().get_local_mouse_position()
		_clamp_position()
		accept_event()
	pass


func _zoom_step( delta_zoom : float ) -> void:
	var mouse_in_parent_space : Vector2 = get_parent().get_local_mouse_position()
	var point_before : Vector2 = ( mouse_in_parent_space - position ) / scale.x
	var new_zoom : float = clampf( scale.x + delta_zoom, min_zoom, max_zoom )
	scale = Vector2( new_zoom, new_zoom )
	position = mouse_in_parent_space - point_before * new_zoom
	_clamp_position()
	pass


## Focuses the map on whichever MapNode child matches the current scene.
## Falls back to fit_to_view() if the player's current room isn't found
## (shouldn't normally happen, since you're standing in it).
func center_on_current_room( target_zoom : float = 2.0 ) -> void:
	for child in get_children():
		if child is MapNode and child.linked_scene == SceneManager.current_scene_uid:
			center_on( child, target_zoom )
			return
	fit_to_view()
	pass


func center_on( node : Control, target_zoom : float ) -> void:
	var new_zoom : float = clampf( target_zoom, min_zoom, max_zoom )
	scale = Vector2( new_zoom, new_zoom )
	var node_center : Vector2 = node.position + node.size * 0.5
	position = ( _get_viewport_size() * 0.5 ) - node_center * new_zoom
	_clamp_position()
	pass


## Zooms out to show every discovered room at once.
func fit_to_view() -> void:
	var bounds : Rect2 = _get_content_bounds()
	if bounds.size == Vector2.ZERO:
		return
	var view_size : Vector2 = _get_viewport_size()
	var fit_zoom : float = min( view_size.x / bounds.size.x, view_size.y / bounds.size.y )
	fit_zoom = clampf( fit_zoom * 0.9, min_zoom, max_zoom )
	scale = Vector2( fit_zoom, fit_zoom )
	var content_center : Vector2 = bounds.position + bounds.size * 0.5
	position = ( view_size * 0.5 ) - content_center * fit_zoom
	_clamp_position()
	pass


func _get_content_bounds() -> Rect2:
	var bounds : Rect2 = Rect2()
	var first : bool = true
	for child in get_children():
		if child is Control:
			var r : Rect2 = Rect2( child.position, child.size )
			if first:
				bounds = r
				first = false
			else:
				bounds = bounds.merge( r )
	return bounds


func _get_viewport_size() -> Vector2:
	var parent : Node = get_parent()
	if parent is Control:
		return parent.size
	return get_viewport_rect().size


func _clamp_position() -> void:
	var bounds : Rect2 = _get_content_bounds()
	if bounds.size == Vector2.ZERO:
		return
	var view_size : Vector2 = _get_viewport_size()
	
	var scaled_pos : Vector2 = bounds.position * scale
	var scaled_size : Vector2 = bounds.size * scale
	
	var min_x : float = view_size.x - scaled_pos.x - scaled_size.x - edge_margin
	var max_x : float = edge_margin - scaled_pos.x
	var min_y : float = view_size.y - scaled_pos.y - scaled_size.y - edge_margin
	var max_y : float = edge_margin - scaled_pos.y
	
	if min_x > max_x:
		var mid_x : float = ( min_x + max_x ) * 0.5
		min_x = mid_x
		max_x = mid_x
	if min_y > max_y:
		var mid_y : float = ( min_y + max_y ) * 0.5
		min_y = mid_y
		max_y = mid_y
	
	position.x = clampf( position.x, min_x, max_x )
	position.y = clampf( position.y, min_y, max_y )
	pass
