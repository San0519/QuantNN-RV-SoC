# bin2coe.py
import sys

bin_file = "test.bin"
coe_file = "test.coe"
rom_width = 32  # ROM width in bits
bytes_per_word = rom_width // 8

with open(bin_file, "rb") as f:
    data = f.read()

words = []
for i in range(0, len(data), bytes_per_word):
    chunk = data[i:i+bytes_per_word]
    if len(chunk) < bytes_per_word:
        # padding
        chunk += b'\x00' * (bytes_per_word - len(chunk))
    word = int.from_bytes(chunk, byteorder='little')
    words.append(word)

with open(coe_file, "w") as f:
    f.write("memory_initialization_radix=16;\n")
    f.write("memory_initialization_vector=\n")
    for i, w in enumerate(words):
        line_end = "," if i < len(words)-1 else ";"
        f.write(f"{w:08X}{line_end}\n")