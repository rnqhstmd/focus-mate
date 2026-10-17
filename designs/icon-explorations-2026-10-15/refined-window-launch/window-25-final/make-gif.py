from pathlib import Path
import json
from PIL import Image
root = Path(__file__).parent
# The 60fps source is sampled at 25fps with exact 40ms GIF delays.
images = []
for i in range(40):
    source_index = round(i * 60 / 25)
    image = Image.open(root / 'frames' / f'{source_index:04d}.png').convert('RGB')
    image = image.resize((360, 780), Image.Resampling.LANCZOS)
    images.append(image.quantize(colors=128))
images[0].save(root / 'focus-mate-window-25-splash.gif', save_all=True,
    append_images=images[1:], duration=40, loop=0, optimize=False, disposal=2)
with Image.open(root / 'focus-mate-window-25-splash.gif') as gif:
    duration = sum(gif.seek(i) or gif.info['duration'] for i in range(gif.n_frames))
    print(f'GIF: {gif.size}, {gif.n_frames} encoded frames, total duration {duration}ms')

report_file = root / 'validation.json'
report = json.loads(report_file.read_text()) if report_file.exists() else {}
with Image.open(root / 'focus-mate-window-25-splash.gif') as gif:
    report['gif'] = {'width':gif.width, 'height':gif.height, 'encoded_frame_count':gif.n_frames, 'duration_ms':duration, 'source_sample_fps':25, 'loop':gif.info.get('loop')}
report_file.write_text(json.dumps(report, indent=2) + '\n')
