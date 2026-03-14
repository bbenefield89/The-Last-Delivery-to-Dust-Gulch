# Ship Checklist

## Submission Build

- Target export preset: `Windows Desktop`
- Windows export path pattern: `Builds/Win/vX.X.X/DustGulch.exe`
- Web export path pattern: `Builds/Web/vX.X.X/index.html`
- Replace `vX.X.X` with the actual release version before exporting
- On this machine, use the local interactive Godot editor or your own local CLI session for the final Windows export
- Do not treat Codex-run Windows exports as the final ship artifact on this setup
- Verify the export includes the `Assets`, `Scenes`, `Scripts`, and `Tests/Smoke` content needed by the shipped build
- Launch the exported build once before submission

## Pre-Submission Checks

- Run `godot --headless --path . --quit`
- Run `godot --headless --path . --editor --quit`
- Run `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://Tests/Unit -ginclude_subdirs -gexit`
- Run `godot --headless --path . -s res://Tests/Smoke/smoke_test_runner.gd`
- Confirm the game boots directly into the run
- Confirm success, collapse, and restart all work in a manual play pass
- Confirm the result panel and recovery panel remain readable at game resolution

## Jam Packaging

- Zip the exported executable and its accompanying data files together
- Include only the final jam build payload, not editor caches or source-control metadata
- Use the jam page title `Last Delivery to Dust Gulch`
- Include a short control summary: `A/D or Left/Right to steer`, `R to restart after a run`

## Known Follow-Up Before Final Upload

- Headless shutdown still reports resource-in-use warnings tied to audio resources
- Re-test audio mix in the exported build before final submission
