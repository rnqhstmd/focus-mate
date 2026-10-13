"""Build the four app travel sounds as comfortable, seamless 40-second loops.

| app sound | file                   | made from |
|-----------|------------------------|-----------|
| 버스       | travel-bus-v2.wav      | bus-cabin-hum-v1.wav (generate-bus-cabin-hum.py) |
| 비 오는 버스 | travel-bus-rain-v2.wav | bus hum + rain-windshield-cc0-v1.wav (CC0 recording) |
| 지하철      | travel-subway-v2.wav   | synthesized here: floor rumble, rail roar, rounded wheel-joint pulses |
| 숲속       | travel-forest-v2.wav   | forest-edge-cc0-v1.wav (CC0 recording) |

Every file goes through the same comfort pass so nothing pops or sounds sharp:
- band limit: gentle cut below 30 Hz, smooth roll-off from 4.5 kHz, nothing above 12 kHz
  (so no ultrasonic or near-ultrasonic content);
- transient softening: a 30 ms RMS envelope may rise at most 2x (6 dB) above the 400 ms envelope.
All filtering is circular over the whole loop, so the loop seam stays continuous.
Inputs live in designs/audio-sources/ and are already 40-second seamless loops. Writes audio-stats.json for the app files.
"""
from pathlib import Path
import hashlib
import json
import math
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / 'designs/final/assets/audio'
SOURCES = ROOT / 'designs/audio-sources'  # inputs, not shipped with the app
RATE, SECONDS = 48000, 40
N = RATE * SECONDS
TARGET_RMS_DB = -26.0
LOW_CUT, SOFT_FROM, HARD_STOP = 30, 4500, 12000
MAX_RISE, FAST, SLOW = 2.0, 0.03, 0.4
rng = np.random.default_rng(20261014)


def read_wav(name):
    with wave.open(str(SOURCES / name), 'rb') as file:
        assert file.getsampwidth() == 2 and file.getframerate() == RATE, name
        data = np.frombuffer(file.readframes(file.getnframes()), '<i2').astype(np.float64) / 32767
        data = data.reshape(-1, file.getnchannels())
    assert len(data) == N, (name, len(data))
    return data if data.shape[1] == 2 else np.repeat(data, 2, axis=1)


def circular_smooth(values, seconds):
    width = max(1, int(seconds * RATE))
    kernel = np.zeros(len(values))
    kernel[:width] = 1 / width
    kernel = np.roll(kernel, -(width // 2))
    return np.fft.irfft(np.fft.rfft(values) * np.fft.rfft(kernel), len(values))


def band_limit(signal):
    freqs = np.fft.rfftfreq(len(signal), 1 / RATE)
    gain = np.clip((freqs - LOW_CUT / 2) / (LOW_CUT / 2), 0, 1)
    fall = np.clip((freqs - SOFT_FROM) / (HARD_STOP - SOFT_FROM), 0, 1)
    gain *= 0.5 * (1 + np.cos(math.pi * fall))
    return np.stack([np.fft.irfft(np.fft.rfft(signal[:, c]) * gain, len(signal)) for c in range(signal.shape[1])], axis=1)


def soften_transients(signal):
    power = (signal ** 2).mean(axis=1)
    fast, slow = np.sqrt(np.maximum(circular_smooth(power, FAST), 0)), np.sqrt(np.maximum(circular_smooth(power, SLOW), 0))
    gain = np.minimum(1, MAX_RISE * slow / np.maximum(fast, 1e-9))
    gain = circular_smooth(gain, 0.02)
    return signal * gain[:, None]


def comfort(signal):
    signal = soften_transients(band_limit(signal))
    signal = band_limit(signal)
    signal -= signal.mean(axis=0)
    return signal * 10 ** (TARGET_RMS_DB / 20) / np.sqrt(np.mean(signal ** 2))


def shaped_noise(low, high, tilt):
    spectrum = np.fft.rfft(rng.standard_normal(N))
    freqs = np.fft.rfftfreq(N, 1 / RATE)
    gain = np.zeros_like(freqs)
    band = (freqs >= low) & (freqs <= high)
    gain[band] = 1 / np.power(freqs[band], tilt / 2)
    edge = 0.15
    gain *= np.clip((freqs - low * (1 - edge)) / (low * edge), 0, 1) * np.clip((high * (1 + edge) - freqs) / (high * edge), 0, 1)
    signal = np.fft.irfft(spectrum * gain, N)
    return signal / np.sqrt(np.mean(signal ** 2))


def subway():
    t = np.arange(N) / RATE
    swell = 1 + 0.12 * np.sin(2 * math.pi * t / 20) + 0.05 * np.sin(2 * math.pi * t / 8 + 0.7)
    # Wheel joints: a rounded low pulse pair (front/rear axle, 0.14 s apart) every 1.25 s,
    # 32 pairs per loop. Raised-cosine attack, no clicks.
    pulse_t = np.arange(int(0.22 * RATE)) / RATE
    attack = 0.04
    envelope = np.where(pulse_t < attack, 0.5 * (1 - np.cos(math.pi * pulse_t / attack)), np.exp(-(pulse_t - attack) / 0.05))
    pulse = np.sin(2 * math.pi * 58 * pulse_t) * envelope
    pulses = np.zeros(N)
    for beat in np.arange(0.4, SECONDS, 1.25):
        for offset, strength in [(0.0, 1.0), (0.14, 0.75)]:
            start = int((beat + offset) * RATE)
            idx = (start + np.arange(len(pulse))) % N
            pulses[idx] += strength * (0.9 + 0.2 * rng.random()) * pulse
    pulses /= np.sqrt(np.mean(pulses ** 2))
    common_rumble, common_roar = shaped_noise(22, 220, 2.0), shaped_noise(220, 1400, 1.4)
    channels = []
    for side in (0, 1):
        rumble = 0.8 * common_rumble + 0.2 * shaped_noise(22, 220, 2.0)
        roar = (0.7 * common_roar + 0.3 * shaped_noise(220, 1400, 1.4)) * swell
        channels.append(0.9 * rumble + 0.3 * roar + 0.28 * np.roll(pulses, int(0.004 * RATE) * side))
    return np.stack(channels, axis=1)


def write_wav(name, signal):
    peak = float(np.max(np.abs(signal)))
    assert peak < 0.9, (name, peak)
    with wave.open(str(AUDIO / name), 'wb') as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(np.round(signal * 32767).astype('<i2').tobytes())


def stats(name, **extra):
    path = AUDIO / name
    with wave.open(str(path), 'rb') as file:
        data = np.frombuffer(file.readframes(file.getnframes()), '<i2').astype(np.float64).reshape(-1, 2) / 32767
    mono = data.mean(axis=1)
    spectrum = np.abs(np.fft.rfft(mono)) ** 2
    freqs = np.fft.rfftfreq(len(mono), 1 / RATE)
    seconds = mono.reshape(-1, RATE)
    second_db = 20 * np.log10(np.sqrt(np.mean(seconds ** 2, axis=1)))
    fast = np.sqrt(np.maximum(circular_smooth(mono ** 2, FAST), 0))
    slow = np.sqrt(np.maximum(circular_smooth(mono ** 2, SLOW), 1e-18))
    return {
        'file': name, **extra,
        'duration_seconds': len(data) / RATE, 'sample_rate_hz': RATE, 'channels': 2, 'bit_depth': 16,
        'rms_dbfs': round(float(20 * np.log10(np.sqrt(np.mean(data ** 2)))), 2),
        'peak_dbfs': round(float(20 * np.log10(np.max(np.abs(data)))), 3),
        'clipped_samples': int(np.sum(np.abs(data) >= 1)),
        'boundary_step': round(float(np.max(np.abs(data[0] - data[-1]))), 8),
        'adjacent_step_p99': round(float(np.percentile(np.abs(np.diff(data, axis=0)), 99)), 8),
        'energy_above_3khz_percent': round(float(spectrum[freqs > 3000].sum() / spectrum.sum() * 100), 4),
        'energy_above_8khz_percent': round(float(spectrum[freqs > 8000].sum() / spectrum.sum() * 100), 6),
        'max_30ms_over_400ms_ratio': round(float(np.max(fast / np.maximum(slow, 1e-9))), 3),
        'one_second_rms_range_db': round(float(second_db.max() - second_db.min()), 3),
        'bytes': path.stat().st_size,
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
    }


bus = read_wav('bus-cabin-hum-v1.wav')
rain = read_wav('rain-windshield-cc0-v1.wav')
outputs = {
    'travel-bus-v2.wav': (bus, {'label': '버스', 'inputs': ['bus-cabin-hum-v1.wav']}),
    'travel-bus-rain-v2.wav': (0.55 * bus + 0.85 * rain, {'label': '비 오는 버스', 'inputs': ['bus-cabin-hum-v1.wav', 'rain-windshield-cc0-v1.wav'], 'mix_gain': {'bus': 0.55, 'rain': 0.85}}),
    'travel-subway-v2.wav': (subway(), {'label': '지하철', 'inputs': []}),
    'travel-forest-v2.wav': (read_wav('forest-edge-cc0-v1.wav'), {'label': '숲속', 'inputs': ['forest-edge-cc0-v1.wav']}),
}
entries = []
for name, (signal, meta) in outputs.items():
    write_wav(name, comfort(signal))
    entries.append(stats(name, **meta, generator='scripts/build-travel-ambience.py',
                         comfort={'low_cut_hz': LOW_CUT, 'soft_rolloff_from_hz': SOFT_FROM, 'hard_stop_hz': HARD_STOP, 'max_rise': MAX_RISE, 'fast_seconds': FAST, 'slow_seconds': SLOW}))
(AUDIO / 'audio-stats.json').write_text(json.dumps(entries, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='
')
print(json.dumps([{k: e[k] for k in ('file', 'peak_dbfs', 'boundary_step', 'adjacent_step_p99', 'energy_above_8khz_percent', 'max_30ms_over_400ms_ratio')} for e in entries], ensure_ascii=False, indent=1))
