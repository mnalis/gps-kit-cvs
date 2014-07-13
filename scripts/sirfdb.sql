-- $CSK: sirfdb.sql,v 1.1 2005/07/25 18:08:09 ckuethe Exp $
\u mysql
DROP DATABASE gpsobservatory;
CREATE DATABASE gpsobservatory;
\u gpsobservatory

-- This is a "Station". Stations have an administrator, and an "organization"
-- and an IP. Comments about the station (environmenta conditions, geography)
-- are always appreciated.
CREATE TABLE stations (
	station_id	INT UNSIGNED	NOT NULL AUTO_INCREMENT,
	operator_id	INT UNSIGNED	NOT NULL,
	ip		CHAR(15)	NOT NULL,
	station_org	CHAR(128)	NOT NULL,
	comments	INT UNSIGNED,
	PRIMARY KEY (station_id)
);

-- I don't anticipate that comments will be used too often, so we move the
-- comments into their own table and just link them back.
CREATE TABLE comments (
	comment_id	INT UNSIGNED,
	station_id	INT UNSIGNED,
	comments 	TEXT,
	PRIMARY KEY (comment_id)
);

-- if possible, sensor should be surveyed. this will be useful down the road
-- when reviewing the records from a particular sensor or station. New sensors
-- have their precision set to '0'. After some time, it may be possible to
-- calculate the ECEF coordinates of the site, in which case we set precision
-- to 1. Finally, if someone goes throught all the trouble to have all their
-- sensors surveyed, we set precision to 2.
CREATE TABLE sensors (
	sensor_id	INT UNSIGNED	NOT NULL AUTO_INCREMENT,
	station_id	INT UNSIGNED	NOT NULL,
	resolution	TINYINT		NOT NULL,
	ecef_x		FLOAT		NOT NULL,
	ecef_y		FLOAT		NOT NULL,
	ecef_z		FLOAT		NOT NULL,
	PRIMARY KEY (sensor_id)
);

-- These are the actual people who run sites, and this is how to get ahold of
-- them.
CREATE TABLE operators (
	operator_id	INT UNSIGNED	NOT NULL AUTO_INCREMENT,
	operator_phone	CHAR(24)	NOT NULL,
	operator_email	CHAR(128)	NOT NULL,
	operator_name	CHAR(128)	NOT NULL,
	PRIMARY KEY (operator_id)
);

-- This is the actual packet log. The database assigns a serial number, and we
-- record the time of reception at the site/sensor. A minimal decode is done
-- to allow us to select packets of a certain payload size or type. Finally,
-- the full packet is stored for later use.
CREATE TABLE observations (
	obs_id		INT UNSIGNED	NOT NULL AUTO_INCREMENT,
	station_id	INT UNSIGNED	NOT NULL,
	sensor_id	INT UNSIGNED	NOT NULL,
	msgtime		DOUBLE		NOT NULL,
	msgtype		SMALLINT	NOT NULL,
	msglen		SMALLINT	NOT NULL,
	msg		BLOB		NOT NULL,
	PRIMARY KEY (obs_id)
);

-- This is where we log "sessions" to make it easier to extract the data for
-- a particular sensor run.
CREATE TABLE sessions (
	session_id	INT UNSIGNED	NOT NULL AUTO_INCREMENT,
	sensor_id	INT UNSIGNED	NOT NULL,
	station_id	INT UNSIGNED	NOT NULL,
	start		DOUBLE		NOT NULL,
	stop		DOUBLE		NOT NULL,
	PRIMARY KEY (session_id)
);

CREATE UNIQUE	INDEX idx_obs ON observations (obs_id,station_id,sensor_id,msgtime,msgtype,msglen);
CREATE 		INDEX idx_obs_m_type_id ON observations (msgtype,obs_id);
CREATE 		INDEX idx_obs_sid ON observations (session_id);
-- CREATE 		INDEX idx_obs_interval ON observations (msgtime,station_id,sensor_id);
-- CREATE 		INDEX idx_obs_ssid ON observations (station_id,sensor_id);
-- CREATE 		INDEX idx_obs_msg ON observations (msgtime,msgtype,msglen);
-- CREATE 		INDEX idx_obs_m_time ON observations (msgtime);
