class_name ProjectPaths
extends RefCounted

## Centralizes project-owned scene and script path strings.


# Constants

const APP_ROOT_SCENE_PATH := "res://Scenes/AppRoot/AppRoot.tscn"
const RUN_SCENE_PATH := "res://Scenes/RunScene/RunScene.tscn"
const TITLE_SCREEN_SCENE_PATH := "res://Scenes/TitleScreen/TitleScreen.tscn"

const DEV_CHEATS_SCRIPT_PATH := "res://Systems/DevCheats/dev_cheats.gd"
const FAILURE_STATE_SCRIPT_PATH := "res://Systems/RunState/failure_state.gd"
const RUN_STATE_MACHINE_SCRIPT_PATH := "res://Scenes/RunScene/FSM/RunStateMachine/run_state_machine.gd"
const RUN_STATE_MACHINE_STATE_SCRIPT_PATH := (
	"res://Scenes/RunScene/FSM/RunStateMachine/States/run_state_machine_state.gd"
)
const RUN_STATE_MACHINE_IN_PROGRESS_STATE_SCRIPT_PATH := (
	"res://Scenes/RunScene/FSM/RunStateMachine/States/in_progress_state.gd"
)
const RUN_STATE_MACHINE_SUCCESS_STATE_SCRIPT_PATH := (
	"res://Scenes/RunScene/FSM/RunStateMachine/States/success_state.gd"
)
const RUN_STATE_MACHINE_COLLAPSED_STATE_SCRIPT_PATH := (
	"res://Scenes/RunScene/FSM/RunStateMachine/States/collapsed_state.gd"
)
const HAZARD_DEFINITION_SCRIPT_PATH := "res://Systems/HazardSpawner/hazard_definition.gd"
const HAZARD_INSTANCE_SCRIPT_PATH := "res://Systems/HazardSpawner/hazard_instance.gd"
const HAZARD_SCENE_PATH := "res://Systems/HazardSpawner/Hazard.tscn"
const HAZARD_SPAWNER_SCRIPT_PATH := "res://Systems/HazardSpawner/hazard_spawner.gd"
const LIVESTOCK_HAZARD_DEFINITION_RESOURCE_PATH := "res://Systems/HazardSpawner/Definitions/livestock_hazard_definition.tres"
const POTHOLE_HAZARD_DEFINITION_RESOURCE_PATH := "res://Systems/HazardSpawner/Definitions/pothole_hazard_definition.tres"
const RECOVERY_SEQUENCE_GENERATOR_SCRIPT_PATH := "res://Systems/RecoverySequenceGenerator/recovery_sequence_generator.gd"
const ROADSIDE_SCENERY_SCRIPT_PATH := "res://Systems/RoadsideScenery/roadside_scenery.gd"
const ROCK_HAZARD_DEFINITION_RESOURCE_PATH := "res://Systems/HazardSpawner/Definitions/rock_hazard_definition.tres"
const RESULT_PANEL_UI_SCRIPT_PATH := "res://UI/ResultPanel/result_panel_ui.gd"
const RESULT_STAT_ROW_SCENE_PATH := "res://UI/ResultPanel/ResultStatRow.tscn"
const RESULT_STAT_ROW_SCRIPT_PATH := "res://UI/ResultPanel/result_stat_row.gd"
const RUN_AUDIO_PRESENTER_SCRIPT_PATH := "res://Systems/RunAudioPresenter/run_audio_presenter.gd"
const RUN_DIRECTOR_SCRIPT_PATH := "res://Systems/RunDirector/run_director.gd"
const RUN_HAZARD_RESOLVER_SCRIPT_PATH := "res://Systems/RunHazardResolver/run_hazard_resolver.gd"
const RUN_PRESENTATION_SCRIPT_PATH := "res://Systems/RunPresentation/run_presentation.gd"
const RUN_STATE_SCRIPT_PATH := "res://Systems/RunState/run_state.gd"
const BONUS_CALLOUT_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/bonus_callout_layer.gd"
const GAMEPLAY_UI_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/gameplay_ui_layer.gd"
const PAUSE_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/pause_layer.gd"
const PHASE_CALLOUT_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/phase_callout_layer.gd"
const RECOVERY_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/recovery_layer.gd"
const RESULT_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/result_layer.gd"
const TOUCH_LAYER_SCRIPT_PATH := "res://Scenes/RunScene/touch_layer.gd"
const TUMBLEWEED_HAZARD_DEFINITION_RESOURCE_PATH := "res://Systems/HazardSpawner/Definitions/tumbleweed_hazard_definition.tres"
