extends Control

var Loader: ConfigFile = ConfigFile.new()
var SavePath: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Managment.ini"

func _ready() -> void:
	var E = Loader.load(SavePath)
	if E:
		print("Something went wrong!\n", E)
		return

	if Loader.get_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST) == "LOCKED":
		%GenericPopup.dialog_text = "This program is either already open on another computer at the moment, or it was closed improperly.\n\nTo avoid version mismatch or data corruption, please close this program until other users are finished using the software."
		%GenericPopup.popup_centered()

	# Lock the software to prevent data issues.
	Loader.set_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST, "LOCKED")
	PopulateList()

func SaveProject() -> void:
	if %ProjectName.text.is_empty():
		%GenericPopup.dialog_text = "You need to give the project a name first!"
		%GenericPopup.popup_centered()
		return

	%LastUpdated.text = Time.get_date_string_from_system()
	Loader.clear()
	Loader.load(SavePath)
	Loader.set_value(%ProjectName.text, Constants.CARD_HOLDER, %ProjectRequester.text)
	Loader.set_value(%ProjectName.text, Constants.CARD_NUMBER, %CardNumber.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_NOTES, %ProjectNotes.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_ID, %ProjectID.text)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_SOURCE, %ProjectSource.selected)
	Loader.set_value(%ProjectName.text, Constants.PROJECT_COLOR, %ProjectColor.text)
	Loader.set_value(%ProjectName.text, Constants.SIGNATURE, %ApprovedBy.text)
	Loader.set_value(%ProjectName.text, Constants.LAST_UPDATED, Time.get_unix_time_from_system())
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
	%LastUpdated.text = "Updated on: " + Time.get_date_string_from_unix_time(Loader.get_value(N, Constants.LAST_UPDATED, "Never"))
	%LastUsedCard.text = CheckCardLastUse(%CardNumber.text)

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
	for N in Sections:
		if N == Constants.RESERVED_SECTION:
			continue

		%ProjectList.add_item(N)

func ApplyFilter(Type: Constants.SearchBy, Query: String) -> void:
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

func _exit_tree():
	Loader.set_value(Constants.RESERVED_SECTION, Constants.LOCK_CONST, "UNLOCKED")
	Loader.save(SavePath)

func _on_project_list_item_clicked(index, _at_position, _mouse_button_index):
	LoadProject(%ProjectList.get_item_text(index))

func _on_save_project_button_up() -> void:
	if Loader.has_section(%ProjectName.text):
		%ConfirmSave.dialog_text = "You are about to overwrite an existing entry. Continue?"
		%ConfirmSave.popup_centered()
		return

	SaveProject()

func _on_add_project_button_up():
	%ProjectList.deselect_all()
	ClearFields()

func _on_delete_project_button_up():
	%ConfirmDelete.dialog_text = "Are you sure you want to remove this listing? It will be removed forever and cannot be brought back."
	%ConfirmDelete.popup_centered()

func _on_confirmation_dialog_confirmed():
	SaveProject()

func _on_clear_filter_button_up():
	%SearchBox.clear()
	%OptionButton.select(0)
	PopulateList()

func _on_confirm_delete_confirmed():
	Loader.erase_section(%ProjectName.text)
	Loader.save(SavePath)
	PopulateList()
	ClearFields()

func _on_set_filter_button_up():
	ApplyFilter(%OptionButton.selected, %SearchBox.text)

func _on_button_button_up() -> void:
	%AboutPopup.popup_centered()
