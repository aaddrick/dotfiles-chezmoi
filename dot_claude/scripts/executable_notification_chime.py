#!/usr/bin/env python3
"""Play a pleasant two-note notification chime using only stdlib."""

import io
import math
import shutil
import struct
import subprocess
import wave

SAMPLE_RATE = 44100


def generate_tone(freq, duration, volume=0.4):
    """Generate a bell-like tone with harmonics and exponential decay."""
    samples = []
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        envelope = math.exp(-t * 5.0)
        val = (
            math.sin(2 * math.pi * freq * t) * 0.80
            + math.sin(2 * math.pi * freq * 2 * t) * 0.15
            + math.sin(2 * math.pi * freq * 3 * t) * 0.05
        )
        samples.append(max(-1.0, min(1.0, val * envelope * volume)))
    return samples


def build_wav(samples):
    """Pack float samples into a WAV byte buffer."""
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(
            struct.pack("<" + "h" * len(samples), *[int(s * 32767) for s in samples])
        )
    return buf.getvalue()


def play_wav(wav_data):
    """Pipe WAV data to the first available audio player."""
    for cmd in ["paplay", "pw-play", "aplay"]:
        player = shutil.which(cmd)
        if player:
            proc = subprocess.Popen(
                [player] if cmd != "pw-play" else [player, "-"],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            proc.communicate(input=wav_data)
            return proc.returncode == 0
    return False


def main():
    # E5 (659 Hz) rising to G5 (784 Hz) - pleasant minor third interval
    silence_gap = [0.0] * int(SAMPLE_RATE * 0.04)
    chime = generate_tone(659.25, 0.22, 0.4) + silence_gap + generate_tone(783.99, 0.28, 0.35)
    play_wav(build_wav(chime))


if __name__ == "__main__":
    main()
