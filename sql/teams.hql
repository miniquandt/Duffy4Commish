create database if not exists lol;

CREATE EXTERNAL TABLE lol.`teams`(
  `team_id` string, 
  `name` string, 
  `acronym` string, 
  `slug` string)
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
WITH SERDEPROPERTIES ( 
  'paths'='acronym,name,slug,team_id') 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://namenode:8020/esports-sql/teams.json'
TBLPROPERTIES (
  'classification'='json',
  'typeOfData'='file')