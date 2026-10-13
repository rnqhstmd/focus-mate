"""Synthesize a voice-free bus cabin hum as a seamless 40-second loop.

The recorded London bus contained passengers' voices and bursts, so the app
uses this synthesized steady hum instead: a low engine tone with slow RPM drift,
band-limited road rumble and faint air hiss. No speech-band events are added.
"""
from pathlib import Path
import json
import math
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'designs/audio-sources/bus-cabin-hum-v1.wav'
RATE, SECONDS, FADE = 48000, 40, 2
TARGET_RMS_DB = -26.0
rng = np.random.default_rng(20261013)
n = RATE * (SECONDS + FADE)
t = np.arange(n) / RATE


def shaped_noise(low, high, tilt):
    """White noise filtered in the frequency domain to [low, high] Hz with a 1/f^tilt slope."""
    spectrum = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    gain = np.zeros_like(freqs)
    band = (freqs >= low) & (freqs <= high)
    gain[band] = 1 / np.power(freqs[band], tilt / 2)
    edge = 0.15
    gain *= np.clip((freqs - low * (1 - edge)) / (low * edge), 0, 1) * np.clip((high * (1 + edge) - freqs) / (high * edge), 0, 1)
    signal = np.fft.irfft(spectrum * gain, n)
    return signal / np.sqrt(np.mean(signal ** 2))


def engine():
    drift = 1 + 0.03 * np.sin(2 * math.pi * 0.05 * t) + 0.01 * np.sin(2 * math.pi * 0.013 * t + 1.1)
    phase = 2 * math.pi * np.cumsum(38.0 * drift) / RATE
    tone = sum(a * np.sin(k * phase) for k, a in [(1, 1.0), (2, 0.55), (3, 0.3), (4, 0.16), (6, 0.07)])
    return tone * (1 + 0.04 * np.sin(2 * math.pi * 0.21 * t)) / np.sqrt(np.mean(tone ** 2))


def channel(common_rumble, common_air):
    rumble = 0.75 * common_rumble + 0.25 * shaped_noise(30, 260, 2.0)
    air = 0.6 * common_air + 0.4 * shaped_noise(1500, 9000, 1.0)
    return 0.55 * engine() + 0.75 * rumble + 0.06 * air


def loop(signal):
    count = RATE * FADE
    angle = np.linspace(0, math.pi / 2, count)[:, None]
    seam = signal[-count:] * np.cos(angle) + signal[:count] * np.sin(angle)
    return np.concatenate([signal[count:-count], seam])


rumble, air = shaped_noise(30, 260, 2.0), shaped_noise(1500, 9000, 1.0)
stereo = np.stack([channel(rumble, air), channel(rumble, air)], axis=1)
stereo -= stereo.mean(axis=0)
stereo = loop(stereo)
stereo *= 10 ** (TARGET_RMS_DB / 20) / np.sqrt(np.mean(stereo ** 2))
peak = float(np.max(np.abs(stereo)))
assert peak < 0.9, peak
pcm = np.round(stereo * 32767).astype('<i2')
with wave.open(str(OUT), 'wb') as file:
    file.setnchannels(2)
    file.setsampwidth(2)
    file.setframerate(RATE)
    file.writeframes(pcm.tobytes())
print(json.dumps({'file': OUT.name, 'seconds': len(pcm) / RATE, 'rate': RATE, 'peak': round(peak, 3), 'rmsDb': TARGET_RMS_DB}))
