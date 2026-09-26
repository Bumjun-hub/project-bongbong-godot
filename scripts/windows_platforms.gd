extends Node

signal surfaces_changed(rectangles: Array[Rect2])
signal windows_changed(windows: Array)

const HELPER_PATH := "res://native/windows/bin/Bongbong.WindowBounds.exe"
const POLL_MSEC := 33
const TIMEOUT_MSEC := 3000
const MIN_PLATFORM_WIDTH := 64.0
const MIN_SIDE_HEIGHT := 40.0

var host_window: Window
var minimum_top_y := 140.0
var desktop_floor := 0.0
var edge_inset := 0.0
var last_windows: Array = []
var native_client_rect := Rect2()
var surfaces: Array[Rect2] = []
var platforms: Array = []
var status := "starting"
var helper_pid := -1
var _io: FileAccess
var _stderr: FileAccess
var _pending := false
var _requested_at := 0
var _next_request := 0
var _buffer := PackedByteArray()


func _ready() -> void:
	var executable := ProjectSettings.globalize_path(HELPER_PATH)
	if not FileAccess.file_exists(executable):
		_fail("창 위치 도구를 찾지 못했습니다. native/windows/build.ps1을 실행해 주세요.")
		return
	var native_handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, host_window.get_window_id())
	var process := OS.execute_with_pipe(executable, PackedStringArray([str(native_handle)]), false)
	if process.is_empty():
		_fail("창 위치 도구를 시작하지 못했습니다.")
		return
	helper_pid = process["pid"]
	_io = process["stdio"]
	_stderr = process["stderr"]


func _process(_delta: float) -> void:
	if _io == null:
		return
	var now := Time.get_ticks_msec()
	var bytes := _io.get_buffer(65536)
	if not bytes.is_empty():
		_buffer.append_array(bytes)
		if _buffer.size() > 1048576:
			_fail("창 위치 응답이 너무 큽니다.")
			return
		var newline := _buffer.find(10)
		if newline >= 0:
			var line := _buffer.slice(0, newline).get_string_from_utf8()
			_buffer = _buffer.slice(newline + 1)
			if not _accept_snapshot(line):
				return
			_pending = false
	if _pending and now - _requested_at > TIMEOUT_MSEC:
		_fail("창 위치 도구가 응답하지 않아 바닥 이동으로 돌아갑니다.")
		return
	if not _pending and now >= _next_request:
		if not OS.is_process_running(helper_pid):
			_fail("창 위치 도구가 종료되어 바닥 이동으로 돌아갑니다.")
			return
		_io.store_line("snapshot")
		_pending = true
		_requested_at = now
		_next_request = now + POLL_MSEC


func _accept_snapshot(line: String) -> bool:
	var document = JSON.parse_string(line)
	if not document is Dictionary or document.get("version") != 1 or not document.get("windows") is Array:
		_fail("창 위치 응답을 읽지 못했습니다.")
		return false
	last_windows = document["windows"]
	var client = document.get("client")
	if not client is Dictionary:
		_fail("봉봉이 창의 화면 기준점을 읽지 못했습니다.")
		return false
	native_client_rect = Rect2(float(client.get("x", 0)), float(client.get("y", 0)), float(client.get("width", 0)), float(client.get("height", 0)))
	if not native_client_rect.has_area():
		_fail("봉봉이 창의 화면 크기를 읽지 못했습니다.")
		return false
	var coordinate_scale := Vector2(host_window.size) / native_client_rect.size
	var next_platforms := visible_platforms(last_windows, native_client_rect.position, Vector2(host_window.size), minimum_top_y, desktop_floor, edge_inset, coordinate_scale)
	var next_surfaces := platform_rectangles(next_platforms)
	status = "ready"
	# Identity and full bounds matter even when the visible top is unchanged.
	if next_platforms != platforms:
		platforms = next_platforms
		windows_changed.emit(platforms)
	if next_surfaces != surfaces:
		surfaces = next_surfaces
		surfaces_changed.emit(surfaces)
	return true


static func visible_tops(windows: Array, origin: Vector2, area: Vector2, minimum_y: float, floor_y: float, inset: float, coordinate_scale: Vector2 = Vector2.ONE) -> Array[Rect2]:
	return platform_rectangles(visible_platforms(windows, origin, area, minimum_y, floor_y, inset, coordinate_scale))


static func platform_rectangles(windows: Array) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for window in windows:
		for surface in window["surfaces"]:
			result.append(surface)
	return result


static func visible_platforms(windows: Array, origin: Vector2, area: Vector2, minimum_y: float, floor_y: float, inset: float, coordinate_scale: Vector2 = Vector2.ONE) -> Array:
	var result: Array = []
	var occluders: Array[Rect2] = []
	var viewport := Rect2(Vector2.ZERO, area)
	for item in windows:
		if not item is Dictionary:
			continue
		var rectangle := Rect2(float(item.get("x", 0)), float(item.get("y", 0)), float(item.get("width", 0)), float(item.get("height", 0)))
		rectangle.position = (rectangle.position - origin) * coordinate_scale
		rectangle.size *= coordinate_scale
		if not rectangle.has_area() or not rectangle.intersects(viewport):
			continue
		var top := rectangle.position.y
		var clipped := rectangle.intersection(viewport)
		var visible: Array[Rect2] = []
		var sides: Array = []
		if bool(item.get("platform", false)) and top >= minimum_y and top < floor_y:
			var spans: Array[Vector2] = [Vector2(maxf(clipped.position.x, inset), minf(clipped.end.x, area.x - 1.0 - inset))]
			for front in occluders:
				if front.position.y > top or front.end.y <= top:
					continue
				var remaining: Array[Vector2] = []
				for span in spans:
					if front.end.x <= span.x or front.position.x >= span.y:
						remaining.append(span)
					else:
						if front.position.x > span.x:
							remaining.append(Vector2(span.x, front.position.x))
						if front.end.x < span.y:
							remaining.append(Vector2(front.end.x, span.y))
				spans = remaining
			for span in spans:
				if span.y - span.x >= MIN_PLATFORM_WIDTH:
					visible.append(Rect2(span.x, top, span.y - span.x, clipped.size.y))
		if bool(item.get("platform", false)):
			for edge in ["left", "right"]:
				var edge_x := rectangle.position.x if edge == "left" else rectangle.end.x
				if edge_x <= 0.0 or edge_x >= area.x:
					continue
				var spans: Array[Vector2] = [Vector2(maxf(top, 0.0), minf(rectangle.end.y, floor_y))]
				for front in occluders:
					if front.position.x > edge_x or front.end.x < edge_x:
						continue
					spans = subtract_span(spans, Vector2(front.position.y, front.end.y))
				for span in spans:
					if span.y - span.x >= MIN_SIDE_HEIGHT:
						sides.append({"edge": edge, "x": edge_x, "span": span})
		if not visible.is_empty() or not sides.is_empty():
			result.append({"id": str(item.get("id", "")), "bounds": rectangle, "surfaces": visible, "sides": sides, "blockers": occluders.duplicate()})
		# Even a fullscreen/non-platform window can cover a window behind it.
		occluders.append(clipped)
	return result


static func subtract_span(spans: Array[Vector2], cover: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for span in spans:
		if cover.y <= span.x or cover.x >= span.y:
			result.append(span)
		else:
			if cover.x > span.x:
				result.append(Vector2(span.x, cover.x))
			if cover.y < span.y:
				result.append(Vector2(cover.y, span.y))
	return result


func stop() -> void:
	set_process(false)
	if _io != null:
		_io.store_line("quit")
		_io.close()
		_io = null
	if _stderr != null:
		_stderr.close()
		_stderr = null


func _fail(message: String) -> void:
	status = message
	push_warning(message)
	stop()
	platforms.clear()
	surfaces.clear()
	windows_changed.emit(platforms)
	surfaces_changed.emit(surfaces)


func _exit_tree() -> void:
	stop()
