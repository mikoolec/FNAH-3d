extends RefCounted
class_name AppRegistry
## Definicje aplikacji PC w jednym miejscu.
## in_list    - widoczna na liście w menu Start
## searchable - podpowiadana w wyszukiwarce w trakcie pisania
## secret     - ukryta: wyszukiwarka pokaże ją TYLKO po wpisaniu dokładnie tego słowa
## cmd        - nazwy używane w poleceniach start / close

const DEFS := {
	&"browser": {"name": "Chrome", "cmd": ["chrome", "browser"], "in_list": true, "searchable": true,
		"icon": "res://Assets/PC/Aplikacje/Ikony/chrome.png"},
	&"printer": {"name": "Printer", "cmd": ["printer", "drukarka"], "in_list": true, "searchable": true,
		"icon": "res://Assets/PC/Aplikacje/Ikony/printer.png"},
	&"cmd": {"name": "Wiersz polecenia", "cmd": ["cmd"], "in_list": false, "searchable": false,
		"secret": "cmd", "icon_kind": WinIcon.Kind.CMD},
	&"settings": {"name": "Ustawienia", "cmd": ["settings", "ustawienia"], "in_list": false, "searchable": false,
		"icon_kind": WinIcon.Kind.GEAR},
}


static func all_ids() -> Array:
	return DEFS.keys()


static func display_name(id: StringName) -> String:
	return DEFS[id]["name"]


static func listed_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in DEFS:
		if DEFS[id].get("in_list", false):
			out.append(id)
	return out


# Wyniki wyszukiwania: zwykłe aplikacje po początku nazwy, ukryte tylko po całym słowie
static func search(query: String) -> Array[StringName]:
	var q := query.strip_edges().to_lower()
	var out: Array[StringName] = []
	if q.is_empty():
		return out
	for id in DEFS:
		var d: Dictionary = DEFS[id]
		if d.has("secret"):
			if q == String(d["secret"]):
				out.append(id)
		elif d.get("searchable", false) and String(d["name"]).to_lower().begins_with(q):
			out.append(id)
	return out


# Zamiana nazwy z polecenia (start/close) na id aplikacji. &"" = nie znaleziono.
static func find_by_cmd(token: String) -> StringName:
	var t := token.strip_edges().to_lower().trim_suffix(".exe")
	for id in DEFS:
		if DEFS[id]["cmd"].has(t):
			return id
	return &""


static func icon_texture(id: StringName) -> Texture2D:
	if DEFS[id].has("icon"):
		return load(DEFS[id]["icon"]) as Texture2D
	return null


static func icon_kind(id: StringName) -> int:
	return DEFS[id].get("icon_kind", WinIcon.Kind.GEAR)
