extends Node
class_name EmailDatabase

# Baza wszystkich możliwych maili w grze
static var pool = [
	{
		"sender": "szef@firma.pl",
		"subject": "PILNE: Faktura do wydrukowania",
		"body": "Cześć,\nw załączniku przesyłam zaległą fakturę. Proszę, wydrukuj ją i przekaż do księgowości na już.\n\nPozdrawiam,\nSzef",
		"attachment": "faktura_05_2026.pdf" # Nazwa pliku załącznika (opcjonalnie)
	},
	{
		"sender": "no-reply@sharepoint-security.pl",
		"subject": "Twój kod uwierzytelniający MFA",
		"body": "Wykryto nową próbę logowania do konta SharePoint.\nTwój jednorazowy kod dostępu to: [b]1234[/b].",
		"attachment": "" # Brak załącznika
	},
	{
		"sender": "admin@serwer.local",
		"subject": "Raport z logowania",
		"body": "System zarejestrował udane logowanie z nieznanego adresu IP.",
		"attachment": "logi_systemowe.txt"
	}
]

# Funkcja losująca maila z puli
static func get_random_email() -> Dictionary:
	randomize()
	return pool[randi() % pool.size()]
