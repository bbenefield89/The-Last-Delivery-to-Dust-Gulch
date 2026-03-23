# Systems

Reusable runtime owners live under `Systems/<Owner>/`.

Use these rules when adding or moving runtime code:

- Keep node-backed systems with their scene and script as siblings in the same owning folder.
- Keep pure helper systems as a single `.gd` file in their owning folder when that is all they need.
- Keep owner-specific support types, constants, and enums near the owner that uses them.
- Reserve top-level `Enums/` only for genuinely cross-cutting shared enums.
- Do not reintroduce active runtime code under a top-level `Scripts/` folder.
