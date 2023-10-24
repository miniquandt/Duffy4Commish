# Hackathon 2023: Duffy4Commish

The folowing steps will hopefully get the project downloaded and installed testing locally. Feel free to skip steps if you already have them installed.

0. Download and install this git repro
    - Probably can download Zip from online
    - download git, install that way
        - https://desktop.github.com/

# Download Public Data

0. Download and install Python 3
    - I already have it installed, so reach out if you are having trouble
    - https://www.python.org/downloads/
1. Run the python file "downloadAllRiotData.py" in the folder "DownloadRiotData"
    - I am able to run in Visual Studio Code by
        1. opening the Duffy4Commish folder
        2. select the python file
        3. select [run] in the taskbar at the nav bar then [start without debugging]
            - [ctrl][f5]
        4. if you get a dropdown "select a dubug configuration"
            - select "Python File"
2. after a few minutes you should have ~60 gb of files in a esports-data folder
    - that folder should be in the project's root directory, not in the DownloadRiotData folder

# Set up Docker

1. Download and install Docker: https://www.docker.com/products/docker-desktop/
    - You will also need to install docker command line/terminal tools unsure if it will be installed with above
2. open up command prompt/terminal, Navigate to directory where this folder is in
    - Command Prompt(windows)/Terminal (mac/linux) commands
        - dir / ls -> show all files and folders in the current folder that you are in
        - cd .. -> change Directory by moving backwards up the folder structure
        - cd Duffy4Commish -> change directory by moving fowards into the folder names "Duffy4Commish"
3. run command: docker-compose up
    - you should see many logs being processed
    - after running this command, in Docker Desktop you should see duffy4commish as a container
    - if you wish to run docker in the background add a "-d" on the end to run it detached
        - docker-compose up -d
    - to shut down the docker container, 
        - in terminal press [ctrl][c]
        - in docker container press the stop button for duffy4commish, and it will shut down all the containers

# load data 

1. connect to hive-server
    - docker exec -it hive-server /bin/bash
    - open Docker, containers
        1. find the hive-server container
        2. click the 3 vertical dots
        3. click [Open in Terminal]
        4. enter command "bash" 
2. run following command to move json serde with dependancy files to proper install location
    - cp /hive-lib/json-serde-1.3.8-jar-with-dependencies.jar /opt/hive/lib/
3. run following commands to create sql tables
    - cd /sql
    - hive -f leagues.hql
    - hive -f players.hql
    - hive -f teams.hql
    - hive -f tournaments.hql
    - hive -f mapping-data.hql
    - hive -f games.hql
4. load data (warning 1: if file fails to find a folder or directory ping me; 2 the last command may take 20 minutes)
    - cd /esportsSql
    - hadoop fs -mkdir /esports-sql
    - hadoop fs -put leagues.json hdfs://namenode:8020/esports-sql/leagues.json
    - hadoop fs -put players.json hdfs://namenode:8020/esports-sql/players.json
    - hadoop fs -put teams.json hdfs://namenode:8020/esports-sql/teams.json
    - hadoop fs -put tournaments.json hdfs://namenode:8020/esports-sql/tournaments.json
    - hadoop fs -put mapping-data.json hdfs://namenode:8020/esports-sql/mapping-data.json
    - hadoop fs -mkdir /esports-data
    - hadoop fs -put /esportsData/* hdfs://namenode:8020/esports-data/
        - Or ^possibly faster but copies file need 2x space // V slower, but doesn't need extra storage
        - hadoop fs -moveFromLocal /esportsData/* hdfs://namenode:8020/esports-data/

# Connect to Database

0. attempt at visualizing data mapping https://dbdiagram.io/d/650d1dc4ffbf5169f0481c88
1. type: hive
2. commands:
    - show databases;
    - use [database];
        - use lol;
    - show tables;
    - desc [table];
        - desc games;
3. get query from "Queries.sql" file