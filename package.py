import os
import glob
from zipfile import ZipFile

OUTPUT_FOLDER = "zips"
VERSIONS = ["BCC", "Classic", "Mainline"]

def zip_files(file_paths, output_path, subfolder=""):
    with ZipFile(output_path, 'w') as zip:
        # writing each file one by one
        for file in file_paths:
            zip.write(file, os.path.join(subfolder, file))

# Prepare output directory
if not os.path.exists("zips"):
    os.makedirs("zips")

files = glob.glob("**", recursive=True)
# Filter .git folders etc, and our own outputs, and our own scripts
files = [f for f in files if (not f.startswith(".")) and (not f.startswith("zips")) and (f != "package.py")]

for version in VERSIONS:
    # Overwrite interface number in the main toc file to current version so curseforge accepts the addon with this version
    main_toc_path = "RaidInviteClassic.toc"
    tmp_toc_path = main_toc_path + ".tmp"
    version_toc_path = main_toc_path.replace(".toc", "-" + version + ".toc")

    # Get interface num from current version
    with open(version_toc_path, "rt") as f:
        version_line = None
        for line in f:
            # Example: ## Interface: 90005
            if line.startswith("## Interface:"):
                version_line = line
                break
        assert version_line

    # Overwrite interface num in main toc
    with open(main_toc_path, "rt") as fin:
        with open(tmp_toc_path, "wt") as fout:
            for line_num, line in enumerate(fin):
                if line_num == 0:
                    assert(line.startswith("## Interface:"))
                    fout.write(version_line)
                else:
                    fout.write(line)
    os.remove(main_toc_path)
    os.rename(tmp_toc_path, main_toc_path)

    # Zip everything
    zip_files(files, os.path.join(OUTPUT_FOLDER, "RaidInviteClassic-" + version + ".zip"), "RaidInviteClassic")