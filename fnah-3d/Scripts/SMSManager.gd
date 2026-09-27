extends Node

# Emitowany, gdy przyjdzie nowy SMS (dzięki temu aplikacja UI wie, kiedy się odświeżyć)
signal sms_received(sender: String, message: String)

# Słownik do przechowywania czatów: { "NazwaNadawcy": ["Treść 1", "Treść 2"] }
var chats: Dictionary = {}

# Uniwersalna funkcja do wywoływania SMS-ów z DOWOLNEGO miejsca w grze
func receive_sms(sender: String, message_text: String) -> void:
	if not chats.has(sender):
		chats[sender] = []
	
	chats[sender].append(message_text)
	sms_received.emit(sender, message_text)
	print("Odebrano SMS od [", sender, "]: ", message_text)
