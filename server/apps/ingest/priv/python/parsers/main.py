import os
from tdms_parser import parse_tdms_metadata
from bin_parser import parse_bin_header
from ini_parser import parse_ini_file
from matlab_parser import parse_mat_file, parse_m_file

def process_file(file_path):
    if isinstance(file_path, bytes):
        file_path = file_path.decode("utf-8")
        
    # Determine file type and call the appropriate parsing function
    if file_path.endswith(".tdms"):
        return parse_tdms_metadata(file_path)
    elif file_path.endswith(".bin"):
        return parse_bin_header(file_path)
    elif file_path.endswith(".ini"):
        return parse_ini_file(file_path)
    elif file_path.endswith(".mat"):
        return parse_mat_file(file_path)
    elif file_path.endswith(".m"):
        return parse_m_file(file_path)
    else:
        return f"Unsupported file type for {file_path}"

__all__ = ["process_file"]
