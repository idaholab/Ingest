from scipy.io import loadmat

def parse_mat_file(file_path):
    data = loadmat(file_path)
    return data

def parse_m_file(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()
    return {"commands": lines}
