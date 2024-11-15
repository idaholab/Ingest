import os
from nptdms import TdmsFile
import numpy as np
from datetime import datetime

def parse_tdms_metadata(file_path):
    if isinstance(file_path, bytes):
        file_path = file_path.decode("utf-8")

    metadata = {}
    with TdmsFile.read(file_path) as file:
        metadata["file_properties"] = dict(file.properties)
        props = {}
        for group in file.groups():
            for channel in group.channels():
                temp = dict(channel.properties)
                temp["Ntime"] = len(channel)
                props[channel.name.replace("/", "_")] = temp
        metadata["channel_properties"] = props
        metadata["Nchannels"] = len(group.channels())
        metadata["Ntime"] = len(channel)
        metadata["fs"] = 1 / channel.properties.get("wf_increment", 4e-10)
        t0 = channel.properties.get("wf_start_time")
        metadata["t0"] = t0.isoformat() if isinstance(t0, datetime) else None
    return metadata
