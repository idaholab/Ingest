import configparser

def parse_ini_file(file_path):
    config = configparser.ConfigParser()
    try:
        config.read(file_path)
        config_dict = {section: dict(config.items(section)) for section in config.sections()}
        return config_dict if config_dict else {"content": "Empty or non-standard INI format"}
    except configparser.MissingSectionHeaderError:
        with open(file_path, "r") as f:
            lines = f.readlines()
        return {"content": lines}
