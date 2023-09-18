create database if not exists lol;

CREATE TABLE lol.`leagues`(
  `id` string, 
  `name` string, 
  `slug` string, 
  `sport` string, 
  `image` string, 
  `lightimage` string, 
  `darkimage` string, 
  `region` string, 
  `priority` int, 
  `displaypriority` struct<position:int,status:string>, 
  `tournaments` array<struct<id:string>>)
ROW FORMAT SERDE 
  'org.openx.data.jsonserde.JsonSerDe' 
WITH SERDEPROPERTIES ( 
  'paths'='darkImage,displayPriority,id,image,lightImage,name,priority,region,slug,sport,tournaments') 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://namenode:8020/esports-sql/leagues.json'
TBLPROPERTIES (
  'classification'='json',
  'typeOfData'='file')