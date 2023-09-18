create database if not exists lol;
use lol;
CREATE EXTERNAL TABLE `players`(
  `player_id` string, 
  `handle` string, 
  `first_name` string, 
  `last_name` string, 
  `home_team_id` string)
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
WITH SERDEPROPERTIES ( 
  'paths'='first_name,handle,home_team_id,last_name,player_id') 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://namenode:8020/esports-sql/players.json'
TBLPROPERTIES (
  'classification'='json',
  'typeOfData'='file')