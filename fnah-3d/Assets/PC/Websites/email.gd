extends Control

# Referencje UI
@onready var login_panel: PanelContainer = $LoginPanel
@onready var main_panel: PanelContainer = $MainPanel
@onready var email_input: LineEdit = $LoginPanel/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $LoginPanel/VBoxContainer/PasswordInput
@onready var error_label: Label = $LoginPanel/VBoxContainer/ErrorLabel

@onready var email_list_container: VBoxContainer = $MainPanel/HSplitContainer/ScrollContainer/EmailListContainer
@onready var sender_label: Label = $MainPanel/HSplitContainer/EmailPreview/VBoxContainer/SenderLabel
@onready var subject_label: Label = $MainPanel/HSplitContainer/EmailPreview/VBoxContainer/SubjectLabel
@onready var body_label: RichTextLabel = $MainPanel/HSplitContainer/EmailPreview/VBoxContainer/BodyLabel
@onready var attachment_section: HBoxContainer = $MainPanel/HSplitContainer/EmailPreview/VBoxContainer/AttachmentSection

# Przechowywanie odebranych maili gracza
var received_emails: Array = []
var pc_control: Control # Referencja do pulpitu, potrzebna do pobierania załączników

func _ready() -> void:
	login_panel.show()
	main_panel.hide()
	error_label.text = ""
	clear_preview()
	
	$LoginPanel/VBoxContainer/LoginButton.pressed.connect(_on_login_pressed)
	
	# Szukamy naszego pulpitu w drzewie (tak jak w poprzednich krokach)
	pc_control = get_node_or_null("/root/model_harcowka/PC/PC/SubViewport/PCControl")
	if pc_control:
		# REJESTRACJA: Mówimy pulpitowi, że ta instancja aplikacji jest teraz aktywna
		pc_control.active_email_app = self
		
		# Pobieramy maile, które zdążyły przyjść, zanim gracz otworzył stronę
		received_emails = pc_control.all_received_emails

# --- LOGOWANIE ---
func _on_login_pressed() -> void:
	# Przykładowe dane logowania
	if email_input.text == "gracz@poczta.pl" and password_input.text == "haslo123":
		login_panel.hide()
		main_panel.show()
		refresh_email_list()
	else:
		error_label.text = "Błędny login lub hasło."

# --- SYSTEM ODBIERANIA MAILI (Wywołaj tę funkcję z zewnątrz, np. przez Timer w grze) ---
func receive_new_email() -> void:
	# Losujemy maila z przygotowanej wcześniej bazy danych
	var new_mail = EmailDatabase.get_random_email()
	
	# Dodajemy go na początek listy odebranych (najnowsze u góry)
	received_emails.push_front(new_mail)
	
	# Jeśli gracz jest zalogowany, odświeżamy listę na ekranie
	if main_panel.visible:
		refresh_email_list()

# --- WYŚWIETLANIE LISTY ---
func refresh_email_list() -> void:
	# Czyścimy stare przyciski z listy
	for child in email_list_container.get_children():
		child.queue_free()
		
	# Tworzymy przyciski dla każdego odebranego maila
	for i in range(received_emails.size()):
		var mail = received_emails[i]
		var btn = Button.new()
		
		# Ładny nagłówek na liście: Nadawca - Temat
		btn.text = mail["sender"] + "\n" + mail["subject"]
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		
		# Podpinamy kliknięcie pod podgląd konkretnego maila
		btn.pressed.connect(func(): show_email_preview(mail))
		email_list_container.add_child(btn)

# --- PODGLĄD MAILA I ZAŁĄCZNIKI ---
func show_email_preview(mail: Dictionary) -> void:
	sender_label.text = "Od: " + mail["sender"]
	subject_label.text = "Temat: " + mail["subject"]
	body_label.text = mail["body"] # RichTextLabel automatycznie obsłuży np. [b]pogrubienie[/b]
	
	# Czyszczenie poprzednich przycisków załączników
	for child in attachment_section.get_children():
		child.queue_free()
		
	# Sprawdzamy czy mail ma załącznik
	if mail["attachment"] != "":
		var attachment_label = Label.new()
		attachment_label.text = "Załącznik: 📄 " + mail["attachment"]
		attachment_section.add_child(attachment_label)
		
		var dl_btn = Button.new()
		dl_btn.text = "Pobierz na pulpit"
		dl_btn.pressed.connect(func():
			_download_attachment(mail["attachment"])
		)
		attachment_section.add_child(dl_btn)

func _download_attachment(file_name: String) -> void:
	# Wykorzystujemy system pobierania, który zrobiliśmy w poprzednich krokach!
	# Tworzymy plik bezpośrednio na pulpicie za pomocą metody spawn_file_on_desktop
	if pc_control and pc_control.has_method("spawn_file_on_desktop"):
		pc_control.spawn_file_on_desktop(file_name)
		print("Pobrano załącznik z maila: ", file_name)

func clear_preview() -> void:
	sender_label.text = ""
	subject_label.text = ""
	body_label.text = "Wybierz wiadomość z listy po lewej stronie."

func refresh_from_pc(new_emails_list: Array) -> void:
	received_emails = new_emails_list
	if main_panel.visible:
		refresh_email_list()
