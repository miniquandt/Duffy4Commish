import tournamentData from "./tournamentData.js";
import tournaments from "./tournaments.js";
import gameStats from "./gameStats.js"
import teamsData from "./teamsData.js"

export const useTournamentData = () => {
  //console.log(tournamentData.tournament);
  return {tournamentData};
}

export const useTournaments = () => {
  return {tournaments};
}

export const useGameStats = () => {
  return (gameStats);
}

export const useTeams = () => {
  return (teamsData)
}
