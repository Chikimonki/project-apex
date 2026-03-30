#!/usr/bin/env python3
import zlib
import sys
import re

def decompress_vbox_full(input_file, output_file):
    with open(input_file, 'rb') as f:
        data = f.read()
    
    print(f"📂 File size: {len(data)} bytes")
    
    # Find ALL zlib blocks (0x78DA or 0x789C)
    zlib_headers = []
    for i in range(len(data) - 1):
        if data[i:i+2] in [b'\x78\xDA', b'\x78\x9C']:
            zlib_headers.append(i)
    
    print(f"🔍 Found {len(zlib_headers)} compressed blocks")
    
    all_decompressed = bytearray()
    
    for idx, start in enumerate(zlib_headers):
        try:
            # Try to decompress from this position
            decompressor = zlib.decompressobj()
            chunk = decompressor.decompress(data[start:])
            all_decompressed.extend(chunk)
            print(f"   Block {idx+1}: {len(chunk)} bytes decompressed")
        except zlib.error as e:
            # Try with different window bits
            try:
                chunk = zlib.decompress(data[start:start+500], -15)
                all_decompressed.extend(chunk)
                print(f"   Block {idx+1}: {len(chunk)} bytes (raw deflate)")
            except:
                pass
    
    # Also extract any plain text in the header
    header_end = data.find(b'\x78\xDA')
    if header_end > 0:
        header = data[:header_end]
        print(f"\n📋 Header ({header_end} bytes):")
        print(header.decode('utf-8', errors='replace'))
    
    with open(output_file, 'wb') as f:
        f.write(all_decompressed)
    
    print(f"\n✅ Total decompressed: {len(all_decompressed)} bytes → {output_file}")
    
    # Show content
    print(f"\n📄 Content preview:")
    print("-" * 60)
    try:
        print(all_decompressed.decode('utf-8', errors='replace')[:2000])
    except:
        print(all_decompressed[:500])

if __name__ == "__main__":
    input_f = sys.argv[1] if len(sys.argv) > 1 else "Ferrari-488 Challenge (X710 Connector) 2020-.REF"
    output_f = input_f.replace('.REF', '_full.txt')
    decompress_vbox_full(input_f, output_f)
