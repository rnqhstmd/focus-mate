#!/usr/bin/env python3
"""Generate deterministic, original DSP ambience sketches; no recorded/AI-model audio."""
from pathlib import Path
import json
import wave
import numpy as np

RATE = 24000
DURATION = 24
COUNT = RATE * DURATION
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "designs" / "final" / "assets" / "audio"
RNG = np.random.default_rng(20261011)
TIME = np.arange(COUNT) / RATE
FREQ = np.fft.rfftfreq(COUNT, 1 / RATE)


def noise(low=0, high=10000, pink=0):
    """Circular band-limited noise, using a smooth spectrum for loop continuity."""
    spectrum = np.fft.rfft(RNG.standard_normal(COUNT))
    gain = 1 / np.maximum(FREQ, 30) ** pink
    if low:
        gain *= 1 - np.exp(-(FREQ / low) ** 4)
    gain *= np.exp(-(FREQ / high) ** 6)
    gain[0] = 0
    signal = np.fft.irfft(spectrum * gain, n=COUNT)
    return signal / np.std(signal)


def add_event(signal, event, at):
    indices = (np.arange(len(event)) + round(at * RATE)) % COUNT
    np.add.at(signal, indices, event)


def white():
    # The UI name remains white noise; this is an intentionally warm filtered variant.
    return noise(70, 1600, .30)


def rain():
    signal = noise(100, 1500, .25) * .90 + noise(40, 650, .45) * .15
    for at in RNG.uniform(0, DURATION, 35):
        duration = RNG.uniform(.45, .90)
        t = np.arange(int(RATE * duration)) / RATE
        envelope = np.sin(np.pi * t / duration) ** 4
        # Soft liquid movement instead of sharp glass resonances or impulses.
        pitch = RNG.uniform(340, 650)
        drop = np.sin(2 * np.pi * (pitch * t - 75 * t * t))
        add_event(signal, drop * envelope * .055, at)
    return signal


def forest():
    breeze = 1 + .035 * np.sin(2 * np.pi * TIME / 24)
    signal = noise(70, 900, .55) * breeze + noise(400, 1500, .25) * .10
    for at in RNG.uniform(0, DURATION, 10):
        duration = RNG.uniform(.40, .75)
        t = np.arange(int(RATE * duration)) / RATE
        pitch = RNG.uniform(1450, 1950)
        chirp = np.sin(2 * np.pi * (pitch * t + 120 * t * t))
        add_event(signal, chirp * np.sin(np.pi * t / duration) ** 4 * .065, at)
    return signal


def bus():
    engine_phase = 2 * np.pi * 55 * TIME
    engine = np.sin(engine_phase) + .20 * np.sin(engine_phase * 2) + .08 * np.sin(engine_phase * 3)
    return engine + noise(35, 200, .5) * .10 + noise(90, 650, .40) * .025


def soften(signal):
    """Reduce noise crests and slow level drift without abrupt per-block gain changes."""
    signal = np.tanh(signal / np.std(signal) / 2) * 2
    spectrum = np.fft.rfft(signal)
    signal = np.fft.irfft(spectrum * np.exp(-(FREQ / 2100) ** 8), n=COUNT)
    blocks = signal.reshape(DURATION, RATE)
    levels = np.sqrt(np.mean(blocks ** 2, axis=1))
    gains = levels.mean() / levels
    centers = np.arange(DURATION) + .5
    envelope = np.interp(TIME, np.r_[centers[-1] - DURATION, centers, centers[0] + DURATION],
                         np.r_[gains[-1], gains, gains[0]])
    # Smooth gain over a circular half-second window to avoid pumping or steps.
    kernel = np.zeros(COUNT)
    width = RATE // 2
    kernel[:width] = 1 / width
    envelope = np.roll(np.fft.irfft(np.fft.rfft(envelope) * np.fft.rfft(kernel), n=COUNT), -width // 2)
    signal *= envelope
    # Both ends meet at a shared nonzero value; no recurring fade to silence.
    edge = round(RATE * .025)
    weight = np.sin(np.linspace(0, np.pi / 2, edge)) ** 2
    shared = (signal[0] + signal[-1]) / 2
    signal[:edge] = shared * (1 - weight) + signal[:edge] * weight
    signal[-edge:] = shared * (1 - weight[::-1]) + signal[-edge:] * weight[::-1]
    return signal


def save(name, signal):
    signal -= signal.mean()
    signal = soften(signal)
    target = 10 ** (-26 / 20)
    signal *= target / np.sqrt(np.mean(signal * signal))
    peak = np.max(np.abs(signal))
    if peak > .80:
        signal *= .80 / peak
    pcm = np.rint(signal * 32767).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(pcm.tobytes())
    actual = pcm.astype(float) / 32768
    power = np.abs(np.fft.rfft(actual)) ** 2
    block_db = 20 * np.log10(np.sqrt(np.mean(actual.reshape(DURATION, RATE) ** 2, axis=1)))
    return {"file": f"{name}.wav", "duration_seconds": DURATION,
            "sample_rate_hz": RATE, "channels": 1, "bit_depth": 16,
            "rms_dbfs": round(float(20 * np.log10(np.sqrt(np.mean(actual ** 2)))), 3),
            "peak_dbfs": round(float(20 * np.log10(np.max(np.abs(actual)))), 3),
            "clipped_samples": int(np.count_nonzero(np.abs(pcm.astype(int)) >= 32767)),
            "boundary_step": round(float(abs(actual[0] - actual[-1])), 6),
            "typical_adjacent_step_rms": round(float(np.sqrt(np.mean(np.diff(actual) ** 2))), 6),
            "energy_above_3khz_percent": round(float(100 * power[FREQ > 3000].sum() / power.sum()), 6),
            "one_second_rms_min_dbfs": round(float(block_db.min()), 3),
            "one_second_rms_max_dbfs": round(float(block_db.max()), 3),
            "one_second_rms_range_db": round(float(np.ptp(block_db)), 3)}


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    stats = [save(name, generator()) for name, generator in
             (("white-noise", white), ("rain-window", rain), ("forest", forest), ("bus-ride", bus))]
    (OUT / "audio-stats.json").write_text(json.dumps(stats, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(stats, ensure_ascii=False, indent=2))
