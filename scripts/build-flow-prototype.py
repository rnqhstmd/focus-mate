"""Package the current app flow and preserve the historical 36-screen viewer."""
import json
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "designs/prototype"
output = root / "sites/next-stop-flow/dist"
current = root / "designs/final"
archive = source / "archive-36"
if (source / "prototype.js").exists() and not archive.exists():
    archive.mkdir()
    for name in ["index.html", "prototype.js", "prototype.css", "screens.json", "README.md"]:
        if (source / name).exists():
            shutil.copy2(source / name, archive / name)
    shutil.copytree(source / "assets", archive / "assets", dirs_exist_ok=True)
shutil.copy2(current / "animation-preview.html", source / "index.html")
for name in ["flow-viewer.js", "city-map.png", "transit-card-next-step.png", "bus-guide.html"]:
    shutil.copy2(current / name, source / name)
for kind in ["fonts", "audio", "bus"]:
    shutil.copytree(current / "assets" / kind, source / "assets" / kind, dirs_exist_ok=True)
output.mkdir(parents=True, exist_ok=True)
for name in ["index.html", "flow-viewer.js", "city-map.png", "transit-card-next-step.png", "bus-guide.html"]:
    shutil.copy2(source / name, output / name)
shutil.copytree(source / "assets", output / "assets", dirs_exist_ok=True)
# Retired sketches remain in archive-36/review, rather than the current app package.
for destination in [source / "assets/audio", output / "assets/audio"]:
    for name in ["white-noise.wav", "rain-window.wav", "forest.wav", "bus-ride.wav",
                 "pink-noise-cc0-v1.wav", "bus-london-cc0-v1.wav", "bus-cabin-hum-v1.wav",
                 "rain-windshield-cc0-v1.wav", "forest-edge-cc0-v1.wav"]:
        retired = destination / name
        if retired.is_file():
            retired.unlink()
manifest = root / "sites/next-stop-flow/.openai/hosting.json"
if manifest.exists():
    config = json.loads(manifest.read_text(encoding="utf-8-sig"))
    config["static"] = {"directory": "dist"}
    manifest.write_text(json.dumps(config, indent=2)+"\n", encoding="utf-8")
print(f"Packaged current research-guided flow into {output}; preserved the old 36-screen viewer.")
