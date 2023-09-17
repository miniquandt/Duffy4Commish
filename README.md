# Duffy4Commish

How to get started (still in development, may change)

0: Download and install this git repro
    A: Probably can download Zip from online
    B: download git, install that way
        i:https://desktop.github.com/

# Download Public Data

0: Download and install Python 3
    A: I already have it installed, so reach out if you are having trouble
        i: https://www.python.org/downloads/
1: Run the python file "downloadAllRiotData.py" in the folder "DownloadRiotData"
    A: I am able to run in Visual Studio Code by
        i: opening the Duffy4Commish folder
        ii: select the python file
        iii: select [run] in the taskbar at the nav bar then [start without debugging]
            - [ctrl][f5]
        iv: if you get a dropdown "select a dubug

# Set up Docker

1: Download and install Docker: https://www.docker.com/products/docker-desktop/
    A: You will also need to install docker command line/terminal tools unsure if it will be installed with above

2: open up command prompt/terminal, Navigate to directory where this folder is in
    - Command Prompt(windows)/Terminal (mac/linux) commands
    dir / ls -> show all files and folders in the current folder that you are in
    cd .. -> change Directory by moving backwards up the folder structure
    cd Duffy4Commish -> change directory by moving fowards into the folder names "Duffy4Commish"

3: run command: docker-compose up
    - you should see many logs being processed
    - after running this command, in Docker Desktop you should see duffy4commish as a container
    - if you wish to run docker in the background add a "-d" on the end to run it detached
    docker-compose up -d

4: