extends Control

var SavePath: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Library.cfg"
var Loader: ConfigFile = ConfigFile.new()

func _ready() -> void:
	var E = Loader.load(SavePath)
	if E != 0 && E != 7:
		%Dialog.dialog_text = "Something went wrong while loading the project database. Error code " + E
		%Dialog.popup_centered()
		return

	if Loader.get_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST, "UNLOCKED") == "LOCKED":
		%Confirm.dialog_text = "This program is either already open on another computer at the moment, or it was closed improperly.\n\nTo avoid version mismatch or data corruption, please close this program until other users are finished using the software."
		%Confirm.popup_centered()
		%Confirm.cancel_button_text = "Open anyways (DANGEROUS!)"
		%Confirm.ok_button_text = "Close"
		%Confirm.connect("confirmed", func(): get_tree().quit())

	# Lock the software to prevent data issues.
	Loader.set_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST, "LOCKED")
	Loader.save(SavePath)
	PopulateList()
	%ProjectList.select(0)
	LoadProject(%ProjectList.get_item_text(0))

func SaveProject() -> void:
	if %ProjectName.text.is_empty():
		%GenericPopup.dialog_text = "You need to give the project a name first!"
		%GenericPopup.popup_centered()
		return

	if %ProjectList.is_anything_selected():
		RemoveProject(%ProjectList.get_item_text(%ProjectList.get_selected_items()[0]), false)

	%LastUpdated.text = Time.get_date_string_from_system()
	#var Attatchments: Dictionary = Loader.get_value(%ProjectName.text, Constants.ATTATCHMENTS, {})
	Loader.clear()
	Loader.load(SavePath)
	if %CardNumber.text.is_empty():
		Loader.set_value(%ProjectName.text, Constants.VOLENTEER, true)
		%LastUsedCard.hide()
		%LastUpdated.hide()
		%VolProj.show()
	else:
		Loader.set_value(%ProjectName.text, Constants.VOLENTEER, false)
	Loader.set_value(%ProjectName.text, Constants.CARD_HOLDER, %ProjectRequester.text)
	Loader.set_value(%ProjectName.text, Constants.CARD_NUMBER, %CardNumber.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_NOTES, %ProjectNotes.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_ID, %ProjectID.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_SOURCE, %ProjectSource.selected)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_COLOR, %ProjectColor.text)
	Loader.set_value(%ProjectName.text, Constants.SIGNATURE, %ApprovedBy.text)
	Loader.set_value(%ProjectName.text, Constants.LAST_UPDATED, Time.get_unix_time_from_system())
	#Loader.set_value(%ProjectName.text, Constants.ATTATCHMENTS, Attatchments)
	Loader.save(SavePath)
	PopulateList()

func LoadProject(N: String) -> void:
	%ProjectName.text = N
	%ProjectRequester.text = Loader.get_value(N, Constants.CARD_HOLDER, "")
	%CardNumber.text = Loader.get_value(N, Constants.CARD_NUMBER, "00000000")
	%ProjectNotes.text = Loader.get_value(N, Constants.PROJECT_NOTES, "")
	%ProjectID.text = Loader.get_value(N, Constants.PROJECT_ID, "00000000")
	%ProjectSource.selected = Loader.get_value(N, Constants.PROJECT_SOURCE, 0)
	%ProjectColor.text = Loader.get_value(N, Constants.PROJECT_COLOR, "None")
	%ApprovedBy.text = Loader.get_value(N, Constants.SIGNATURE, "Nobody")

	if Loader.get_value(N, Constants.VOLENTEER, false):
		%LastUsedCard.hide()
		%LastUpdated.hide()
		%VolProj.show()
	else:
		%LastUsedCard.show()
		%LastUpdated.show()
		%VolProj.hide()

	%LastUpdated.text = "Updated on: " + Time.get_date_string_from_unix_time(Loader.get_value(N, Constants.LAST_UPDATED, "Never"))
	%LastUsedCard.text = CheckCardLastUse(%CardNumber.text)
	#%FilesAdded.text = "Contains " + str(Loader.get_value(N, Constants.ATTATCHMENTS, {}).size()) + " attatchments"

	#%RemoveFiles.disabled = !HasAttatchments()
	#%SaveToDisk.disabled = %RemoveFiles.disabled

func RemoveProject(N: String, UpdateUI: bool = true) -> void:
	if !%ProjectList.is_anything_selected():
		ClearFields()
		return

	Loader.erase_section(N)
	Loader.save(SavePath)

	if UpdateUI:
		PopulateList()
		LoadProject(%ProjectList.get_item_text(%ProjectList.get_selected_items()[0]))

func CheckCardLastUse(CardNumber: String) -> String:
	var Oldest: int = 0
	for N in Loader.get_sections():
		if N == Constants.RESERVED_SECTION:
			continue

		if Loader.get_value(N, Constants.CARD_NUMBER) == CardNumber:
			Oldest = max(Loader.get_value(N, Constants.LAST_UPDATED), Oldest)

	if Oldest == 0:
		return "Card never used"
	else:
		return "Card used: " + Time.get_date_string_from_unix_time(Oldest)

func ClearFields() -> void:
	%ProjectName.clear()
	%ProjectRequester.clear()
	%CardNumber.clear()
	%ProjectNotes.clear()
	%ProjectID.clear()
	%ProjectSource.select(0)
	%ProjectColor.clear()
	%ApprovedBy.clear()
	%LastUpdated.text = "Never"
	%LastUsedCard.text = "Card never used"

func PopulateList() -> void:
	%ProjectList.clear()
	var Sections = Loader.get_sections()
	Sections.reverse()
	for N in Sections:
		if N == Constants.RESERVED_SECTION:
			continue

		%ProjectList.add_item(N)
	%ProjectList.select(0)

func ApplyFilter(Type: int, Query: String) -> void:
	%ProjectList.clear()
	match Type:
		Constants.SearchBy.Title:
			for N in Loader.get_sections():
				if N == Constants.RESERVED_SECTION:
					pass
				if N.contains(Query):
					%ProjectList.add_item(N)
		Constants.SearchBy.Description:
			for N in Loader.get_sections():
				if N == Constants.RESERVED_SECTION:
					pass
				if Loader.get_value(N, "ProjectNotes", "").contains(Query):
					%ProjectList.add_item(N)
		Constants.SearchBy.LibraryCard:
			for N in Loader.get_sections():
				if N == Constants.RESERVED_SECTION:
					pass
				if Loader.get_value(N, "CardNumber", "").contains(Query):
					%ProjectList.add_item(N)

func HasAttatchments() -> bool:
	return (Loader.get_value(%ProjectName.text, Constants.ATTATCHMENTS, {}) as Dictionary).size() > 0

func _exit_tree() -> void:
	if %ProjectName.text.is_empty():
		%ProjectName.text = "Unsaved project"
	SaveProject()
	Loader.set_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST, "UNLOCKED")
	Loader.save(SavePath)

func _on_project_list_item_clicked(index, _at_position, _mouse_button_index) -> void:
	LoadProject(%ProjectList.get_item_text(index))

func _on_save_project_button_up() -> void:
	if Loader.has_section(%ProjectName.text) && Loader.has_section_key(%ProjectName.text, Constants.PROJECT_SOURCE):
		%Confirm.dialog_text = "You are about to overwrite an existing entry. Continue?"
		%Confirm.connect("confirmed", SaveProject)
		%Confirm.cancel_button_text = "Go Back"
		%Confirm.ok_button_text = "Yes"
		%Confirm.popup_centered()

	SaveProject()

func _on_add_project_button_up() -> void:
	%ProjectList.deselect_all()
	ClearFields()
	%VolProj.hide()
	%LastUpdated.show()
	%LastUsedCard.show()

func _on_delete_project_button_up() -> void:
	%Confirm.dialog_text = "Are you sure you want to remove this listing? It will be removed forever and cannot be brought back."
	%Confirm.connect("confirmed", RemoveProject.bind(%ProjectName.text))
	%Confirm.popup_centered()

func _on_clear_filter_button_up() -> void:
	%ClearFilter.disabled = true
	%OptionButton.select(0)
	%SearchBox.clear()
	PopulateList()

func _on_set_filter_button_up() -> void:
	if %SearchBox.text.is_empty():
		%Dialog.dialog_text = "You need to enter a query first!"
		%Dialog.ok_button_text = "Back"
		%Dialog.popup_centered()
		return

	ApplyFilter(%OptionButton.selected, %SearchBox.text)
	%ClearFilter.disabled = false

func _on_button_button_up() -> void:
	%Dialog.dialog_text = "This software is open source software, governed by the GPL-V3 software license.
	The purpose of this program is to streamline the work done in a local 3D print lab, though it's use may suit other cases.
	Software designed by Laserology. For future software support, contact help@laserology.net.

	https://www.github.com/Laserology/library-tracker/
	https://laserology.net/"
	%Dialog.ok_button_text = "Dismiss"
	%Dialog.popup_centered()

func _on_save_to_disk_pressed() -> void:
	if !HasAttatchments():
		%Dialog.dialog_text = "This project doesn't have any files attatched."
		%Dialog.ok_button_text = "Back"
		%Dialog.popup_centered()
		return

	var Attatchments: Dictionary = Loader.get_value(%ProjectName.text, Constants.ATTATCHMENTS)
	for N in Attatchments:
		var Writer: FileAccess = FileAccess.open(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + N, FileAccess.WRITE)
		Writer.store_buffer(Attatchments[N])

	%Dialog.dialog_text = "Saved files to your home folder!"
	%Dialog.ok_button_text = "Continue"
	%Dialog.popup_centered()

func _on_remove_files_pressed() -> void:
	if Loader.has_section_key(%ProjectName.text, Constants.ATTATCHMENTS):
		Loader.erase_section_key(%ProjectName.text, Constants.ATTATCHMENTS)
		LoadProject(%ProjectName.text)

func _on_add_files_pressed() -> void:
	%FileDialog.popup_centered()

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	var Files: Dictionary = Loader.get_value(%ProjectName.text, Constants.ATTATCHMENTS, {})
	_on_remove_files_pressed()
	for N in paths:
		Files[N.get_file()] = FileAccess.get_file_as_bytes(N)

	%FilesAdded.text = "Contains %s attatchments" % str(Files.size())
	Loader.set_value(%ProjectName.text, Constants.ATTATCHMENTS, Files)
