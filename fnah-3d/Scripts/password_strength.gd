extends RefCounted
class_name PasswordStrength
## Ocena siły hasła. Poziomy: 0 bardzo słabe ... 4 bardzo silne (-1 = brak hasła).

const LABELS := ["Bardzo słabe", "Słabe", "Średnie", "Silne", "Bardzo silne"]

const COMMON := [
	"password", "passw0rd", "haslo", "qwerty", "123456", "1234567", "12345678", "123456789",
	"1234567890", "111111", "000000", "admin", "administrator", "user", "login", "letmein",
	"welcome", "abc123", "iloveyou", "monkey", "dragon", "master", "zaq12wsx", "polska",
	"kocham", "kochamcie", "test", "windows", "windows10", "komputer", "drukarka",
	"harcowka", "szef", "faktura", "krystian",
]

# Ciągi klawiszy (i ich odwrotności) - 4 znaki z rzędu = wzorzec klawiaturowy
const KEYBOARD_RUNS := [
	"qwertyuiop", "asdfghjkl", "zxcvbnm", "1234567890", "qazwsxedc",
	"poiuytrewq", "lkjhgfdsa", "mnbvcxz", "0987654321", "cdexswzaq",
]

const LEET := {"@": "a", "$": "s", "0": "o", "3": "e", "!": "i"}
const TRAILING := "0123456789!@#$%^&*?._-"


static func none_result() -> Dictionary:
	return {"score": 0, "level": -1, "label": "Brak hasła", "entropy": 0.0, "length": 0, "tips": []}


static func evaluate(pw: String, username: String = "") -> Dictionary:
	if pw.is_empty():
		return none_result()

	var length := pw.length()
	var has_lower := false
	var has_upper := false
	var has_digit := false
	var has_other := false
	for i in length:
		var c := pw.unicode_at(i)
		if c >= 97 and c <= 122:
			has_lower = true
		elif c >= 65 and c <= 90:
			has_upper = true
		elif c >= 48 and c <= 57:
			has_digit = true
		else:
			has_other = true

	var pool := 0
	if has_lower: pool += 26
	if has_upper: pool += 26
	if has_digit: pool += 10
	if has_other: pool += 33

	# --- wzorce obniżające wartość znaków ---
	var penalized: Array[bool] = []
	penalized.resize(length)
	penalized.fill(false)
	var has_repeats := false
	var has_sequences := false
	var has_keyboard := false

	for i in range(1, length):
		if pw.unicode_at(i) == pw.unicode_at(i - 1):
			penalized[i] = true
			has_repeats = true

	for i in range(2, length):
		var c0 := pw.unicode_at(i - 2)
		var c1 := pw.unicode_at(i - 1)
		var c2 := pw.unicode_at(i)
		if c1 - c0 == c2 - c1 and absi(c1 - c0) == 1:
			penalized[i - 2] = true
			penalized[i - 1] = true
			penalized[i] = true
			has_sequences = true

	var lower := pw.to_lower()
	for i in range(0, length - 3):
		var sub := lower.substr(i, 4)
		for run in KEYBOARD_RUNS:
			if run.contains(sub):
				for j in range(i, i + 4):
					penalized[j] = true
				has_keyboard = true
				break

	# --- efektywna długość i entropia ---
	var seen := {}
	var eff := 0.0
	for i in length:
		var ch := pw[i]
		if penalized[i]:
			eff += 0.25
		elif seen.has(ch):
			eff += 0.5
		else:
			eff += 1.0
		seen[ch] = true
	var entropy := eff * log(float(pool)) / log(2.0)

	# --- popularne hasła (także z podmianami @->a, 0->o oraz cyframi na końcu) ---
	var normalized := lower
	for k in LEET:
		normalized = normalized.replace(k, LEET[k])
	var is_common := _is_common(lower) or _is_common(normalized)
	var has_username := username != "" and lower.contains(username.to_lower())

	# --- poziom ---
	var level := 0
	if entropy >= 80.0:
		level = 4
	elif entropy >= 60.0:
		level = 3
	elif entropy >= 36.0:
		level = 2
	elif entropy >= 28.0:
		level = 1
	if length < 8:
		level = mini(level, 1)
	if length < 5:
		level = 0
	if has_username:
		level = mini(level, 1)
	if is_common:
		level = 0

	# wynik 0-100 spójny z poziomem
	var score := int(clampf(entropy / 80.0 * 100.0, 0.0, 100.0))
	var band_max := (level + 1) * 20 - (1 if level < 4 else 0)
	score = clampi(score, level * 20, band_max)

	# --- wskazówki (najważniejsze pierwsze) ---
	var tips: Array[String] = []
	if is_common:
		tips.append("To hasło jest bardzo popularne – łatwo je odgadnąć.")
	if has_username:
		tips.append("Hasło nie powinno zawierać nazwy użytkownika.")
	if length < 12:
		tips.append("Użyj co najmniej 12 znaków.")
	if not (has_lower and has_upper):
		tips.append("Połącz małe i wielkie litery.")
	if not has_digit:
		tips.append("Dodaj cyfry.")
	if not has_other:
		tips.append("Dodaj znaki specjalne (np. ! ? # %).")
	if has_repeats:
		tips.append("Unikaj powtarzających się znaków.")
	if has_sequences or has_keyboard:
		tips.append("Unikaj ciągów typu 123, abc czy qwerty.")

	return {
		"score": score,
		"level": level,
		"label": LABELS[level],
		"entropy": entropy,
		"length": length,
		"tips": tips,
	}


static func _is_common(s: String) -> bool:
	if COMMON.has(s):
		return true
	var base := s.rstrip(TRAILING)
	return base != "" and COMMON.has(base)
