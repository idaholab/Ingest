import os
from parsers.tdms_parser import TDMSReader
from parsers.bin_parser import parse_bin_header
from parsers.ini_parser import parse_ini_file
from parsers.matlab_parser import parse_mat_file, parse_m_file

def process_tdms(file_path, output_dir="parsed_data"):
    tdms_parser = TDMSReader(file_path)
    tdms_parser.load_metadata()
    tdms_parser.save_metadata_as_json(file_path.replace(".tdms", "_parsed.json"), output_dir=output_dir)
    return f"TDMS data processed and saved for {file_path}"

def process_bin(file_path, output_dir="parsed_data"):
    parse_bin_header(file_path, output_dir=output_dir)
    return f"Binary data processed and saved for {file_path}"

def process_ini(file_path, output_dir="parsed_data"):
    parse_ini_file(file_path, output_dir=output_dir)
    return f"INI data processed and saved for {file_path}"

def process_mat(file_path, output_dir="parsed_data"):
    parse_mat_file(file_path, output_dir=output_dir)
    return f"MAT data processed and saved for {file_path}"

def process_m(file_path, output_dir="parsed_data"):
    parse_m_file(file_path, output_dir=output_dir)
    return f"M file data processed and saved for {file_path}"

# This block allows Elixir to call these functions directly
__all__ = ["process_tdms", "process_bin", "process_ini", "process_mat", "process_m"]
