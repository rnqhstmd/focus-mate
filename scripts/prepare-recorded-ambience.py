"""Prepare verified CC0 original WAVs as continuous, level-matched app loops.

Keeps the original sample rate and channels. No low-pass or noise reduction.
Original downloads and the previous sketches remain in the review directory.
"""
from pathlib import Path
import hashlib
import json
import math
import shutil
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / '.impeccable/review/audio-sources'
OUT = ROOT / 'designs/audio-sources'  # inputs for build-travel-ambience.py, not shipped
OLD = ROOT / '.impeccable/review/audio-before'
OLD.mkdir(parents=True, exist_ok=True)
for name in ['white-noise.wav', 'rain-window.wav', 'forest.wav', 'bus-ride.wav', 'audio-stats.json', 'SOURCE.md']:
    existing = OUT / name
    if existing.exists() and not (OLD / name).exists():
        shutil.copy2(existing, OLD / name)


def probe(path):
    return json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(path)]))['streams'][0]


def loop(signal, rate, fade=2):
    count = min(int(rate * fade), len(signal) // 4)
    angle = np.linspace(0, math.pi / 2, count)[:, None]
    seam = signal[-count:] * np.cos(angle) + signal[:count] * np.sin(angle)
    return np.concatenate([signal[count:-count], seam])


def select_segment(signal, rate, seconds):
    """Avoid bursts by choosing a steady segment, without flattening its dynamics."""
    count = int(seconds * rate)
    if len(signal) < count:
        base = loop(signal, rate, .8)
        return np.tile(base, (math.ceil(count / len(base)), 1))[:count], 0
    best = None
    for start in range(0, int(len(signal) / rate - seconds) + 1, 2):
        candidate = signal[start * rate:start * rate + count]
        frame = np.sqrt(np.mean(candidate.reshape(int(seconds), rate, signal.shape[1]) ** 2, axis=(1, 2)))
        if np.min(frame) < .00001:
            continue
        db = 20 * np.log10(frame)
        crest = np.max(np.abs(candidate)) / max(np.sqrt(np.mean(candidate ** 2)), 1e-8)
        score = np.std(db) + .35 * (np.max(db) - np.min(db)) + .10 * crest
        if best is None or score < best[0]:
            best = score, start, candidate
    if best is None:
        return signal[:count], 0
    return best[2], best[1]


metadata = json.loads((SOURCES / 'downloads.json').read_text(encoding='utf-8'))
files = {'rain':'rain-windshield-cc0-v1.wav', 'forest':'forest-edge-cc0-v1.wav', 'bus':'bus-london-cc0-v1.wav', 'pink':'pink-noise-cc0-v1.wav'}
stats = []
for source in metadata:
    key = source['key']
    path = SOURCES / (key + '-original.wav')
    info = probe(path)
    rate, channels = int(info['sample_rate']), int(info['channels'])
    decoded = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-acodec', 'pcm_f32le', '-'])
    signal = np.frombuffer(decoded, dtype='<f4').reshape(-1, channels).astype(np.float64)
    original_clipped = int(np.count_nonzero(np.abs(signal) >= .9999))
    target_seconds = 30 if key == 'pink' else 40
    segment, start = select_segment(signal, rate, target_seconds + 2)
    prepared = loop(segment, rate)
    prepared -= np.mean(prepared, axis=0, keepdims=True)
    # Same RMS as the old sketches: a quality change, without simply turning it up.
    gain = min(10 ** (-26 / 20) / np.sqrt(np.mean(prepared ** 2)), .5 / np.max(np.abs(prepared)))
    prepared *= gain
    pcm = np.round(prepared * 32767).astype('<i2')
    target = OUT / files[key]
    with wave.open(str(target), 'wb') as wav:
        wav.setnchannels(channels); wav.setsampwidth(2); wav.setframerate(rate); wav.writeframes(pcm.tobytes())
    measured = pcm.astype(np.float64) / 32768
    adjacent = np.abs(np.diff(measured, axis=0))
    window = measured[:min(len(measured), rate * 8)]
    spectrum = np.abs(np.fft.rfft(window, axis=0)) ** 2
    frequency = np.fft.rfftfreq(len(window), 1 / rate)
    rms = float(np.sqrt(np.mean(measured ** 2)))
    frames = np.sqrt(np.mean(measured.reshape(target_seconds, rate, channels) ** 2, axis=(1, 2)))
    item = {
        'file': files[key], 'source_key': key, 'source_title': source['title'], 'source_url': source['url'],
        'author': source['author'], 'license': source['license'], 'license_url': source['licenseUrl'],
        'original_sha256': source['sha256'], 'original_sample_rate_hz': rate, 'original_channels': channels,
        'original_duration_seconds': round(len(signal)/rate, 3), 'original_clipped_samples': original_clipped,
        'excerpt_start_seconds': start, 'crossfade_seconds': 2, 'duration_seconds': target_seconds,
        'sample_rate_hz': rate, 'channels': channels, 'bit_depth': 16, 'rms_dbfs': round(20 * math.log10(rms), 3),
        'peak_dbfs': round(20 * math.log10(float(np.max(np.abs(measured)))), 3),
        'clipped_samples': int(np.count_nonzero(np.abs(pcm.astype(np.int32)) >= 32767)),
        'boundary_step': round(float(np.max(np.abs(measured[0] - measured[-1]))), 8),
        'adjacent_step_p99': round(float(np.quantile(adjacent, .99)), 8),
        'energy_above_3khz_percent': round(float(spectrum[frequency > 3000].sum()/spectrum.sum()*100), 4),
        'one_second_rms_range_db': round(float(np.ptp(20*np.log10(frames))), 3),
        'bytes': target.stat().st_size, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()
    }
    assert item['boundary_step'] <= item['adjacent_step_p99'], 'Abnormal loop seam'
    stats.append(item)
    print(json.dumps(item))
(OUT / 'audio-stats.json').write_text(json.dumps(stats, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(OUT / 'sources.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
for name in ['white-noise.wav', 'rain-window.wav', 'forest.wav', 'bus-ride.wav']:
    existing = OUT / name
    if existing.exists():
        existing.unlink()
