
--drop table football.sched;

create table football.sched (
	game_id integer not null,
	week_id integer not null,
	home_id integer not null,
	away_id integer not null,
	game_tsp timestamp not null
);

create table football.scores (
	game_id integer not null,
	away_score integer not null,
	home_score integer not null
);
create table football.picks (
	username varchar(50) not null,
	game_id integer not null,
	pick char(1) not null
);
create table football.tiebreaker (
	username varchar(50) not null,
	week_id integer not null,
	score integer not null
);
create table football.teams (
	team_id integer not null,
	team_name varchar(20) not null,
	team_shortname char(3) not null,
	team_alias varchar(20) not null
);
create table football.teamstandings (
	team_id integer not null,
	wins integer not null,
	losses integer not null,
	ties integer not null
);
import from 2003teamstandings.del of del replace into football.teamstandings;


--import from newsched.csv of del replace into football.sched;
--import from football.teams.del of del replace into football.teams;

--export to away_teams.del of del select distinct away_team from football.sched;
--export to home_teams.del of del select distinct home_team from football.sched;

--export to newsched.csv of del select game_id,week_id,game_date,game_time,home_id,away_id from football.sched;

--export to swap.csv of del select game_id,week_id,away_id,home_id,game_tsp from football.sched;
--import from swap.csv of del replace into football.sched;


