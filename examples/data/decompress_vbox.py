#!/usr/bin/env python3
import zlib
import sys

def decompress_vbox(input_file, output_file):
    with open(input_file, 'rb') as f:
        data = f.read()
    
    # Find zlib magic bytes
    zlib_start = data.find(b'\x78\xDA')
    if zlib_start == -1:
        zlib_start = data.find(b'\x78\x9C')  # Alternative zlib header
    
    if zlib_start == -1:
        print("No zlib compressed data found")
        return
    
    print(f"Found zlib at offset {zlib_start}")
    
    compressed = data[zlib_start:]
    
    try:
        decompressed = zlib.decompress(compressed)
        with open(output_file, 'wb') as f:
            f.write(decompressed)
        print(f"✅ Decompressed {len(decompressed)} bytes to {output_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_f = sys.argv[1] if len(sys.argv) > 1 else "Ferrari-488 Challenge (X710 Connector) 2020-.REF"
    output_f = input_f.replace('.REF', '_decoded.txt')
    decompress_vbox(input_f, output_f)
