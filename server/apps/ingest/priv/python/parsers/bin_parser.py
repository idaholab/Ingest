import struct
import json

def parse_bin_header(file_path, header_size=64):
    with open(file_path, "rb") as f:
        header_bytes = f.read(header_size)
        
        ascii_text = header_bytes.decode('ascii', errors='ignore').strip()
        hex_representation = header_bytes.hex()
        int_val = struct.unpack(">I", header_bytes[:4])[0] if len(header_bytes) >= 4 else None
        float_val = struct.unpack(">f", header_bytes[:4])[0] if len(header_bytes) >= 4 else None

        return {
            "ascii_text": ascii_text,
            "hex_representation": hex_representation,
            "interpreted_integer": int_val,
            "interpreted_float": float_val
        }
