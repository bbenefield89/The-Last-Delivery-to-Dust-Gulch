# Ship Checklist

## Release Targets

- Primary release target: `Android`
- Secondary support targets: `Web` and `Windows Desktop`
- Android export path pattern: `Builds/Android/vX.X.X/`
- Web export path pattern: `Builds/Web/vX.X.X/index.html`
- Windows export path pattern: `Builds/Win/vX.X.X/DustGulch.exe`
- Replace `vX.X.X` with the actual release version before exporting
- Treat Android as the product-defining build when tradeoffs appear between platforms

## Automated Verification

- Run `godot --headless --path . --quit`
- Run `godot --headless --path . --script res://Tests/Smoke/smoke_test_runner.gd`
- Run `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`

## Manual Release Checks

- Confirm the game boots into the title screen and starts a run cleanly
- Confirm onboarding, pause, success, collapse, restart, and return-to-title flows work
- Confirm hazard readability and HUD clarity at gameplay resolution
- Confirm touch controls appear correctly on mobile runtime and do not cover critical road space
- Confirm a full successful run resolves inside the intended mobile session target
- Confirm the result screen shows score, grade, and best-run information correctly
- Confirm best-run persistence survives a relaunch
- Re-test music, impact cues, and failure audio on device speakers or headphones

## Android Release Packaging

- Verify app name, version, icon, and orientation settings are correct
- Build a release-ready Android package from a trusted local Godot/editor session
- Install the package on at least one physical device before release
- Check startup time, pause/resume behavior, and touch responsiveness on device
- Check that the game remains readable on the intended phone aspect ratios

## Store and Release Prep

- Prepare short store copy that clearly sells the delivery-run structure
- Capture screenshots or clips that show driving, hazards, recovery, and results
- Keep control summary concise and mobile-focused in store-facing text
- Do not ship editor caches, source-control metadata, or test-only artifacts in release payloads

## Known Follow-Up Before Release Candidate

- Headless shutdown still reports resource-in-use warnings tied to audio resources
- Audio mix still needs final device validation before public release
