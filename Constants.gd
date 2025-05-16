class_name Constants
extends Node

# Special reserved section not to use.
const RESERVED_SECTION = "LOADER_CONFIG_SECTION_DO_NOT_USE"
const LOCK_CONST = "SOFTWARE_SECONDARY_OPEN_LOCK"

# Common names for every listing.
const CARD_HOLDER = "CardHolder"
const CARD_NUMBER = "CardNumber"
const PROJECT_NOTES = "ProjectNotes"
const PROJECT_ID = "ProjectID"
const PROJECT_SOURCE = "ProjectSource"
const PROJECT_COLOR = "ProjectColor"
const SIGNATURE = "ApprovedBy"
const LAST_UPDATED = "LastUpdated"

enum SearchBy {
	Title,
	Description,
	LibraryCard,
}
