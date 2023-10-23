
<template>
    <div style="background-color:papayawhip;">
        <div>
            <h2>Ranking Teams:</h2>
            <table>
                <tr>
                    <th>#</th>
                    <th>Team Name</th>
                    <th>Score</th>
                    <th>Total Wins</th>
                    <th>Games Played</th>
                </tr>
                <template v-for="t in sortedTeams">
                    <tr>
                        <td>{{ rankCounter++ }}</td>
                        <td>{{ t.Name }}</td>
                        <td>{{ t.scorePerGame }}</td>
                        <td>{{ t.totalWins }}</td>
                        <td>{{ t.gamesPlayed }}</td>
                    </tr>
                </template>
            </table>
        </div>
    </div>
</template>

<script type="ts" setup>
    import { ref } from 'vue';

    const tournamentGames = useTournamentData();
    const gameStats = useGameStats();
    const route = useRoute();
    const teams = [];
    const teamsSorted = [];
    let teamNames = ref({});
    let rankCounter = 1;

    var teamIds = route.params.teamId.split("+");

    function getGoldStats(gold14, goldEnd){
        // determine how the team did against the other winning teams
        let gold14Compared = gold14 / gameStats.gameStats.median_gold_diff_14;
        let goldEndCompared = goldEnd / gameStats.gameStats.median_gold_diff_end_game;

        let combinedGoldLead = gold14Compared + goldEndCompared;

        const maxGold = gameStats.gameStats.max_gold;
        const minGold = -maxGold;
        
        //Normalize gold lead to values between 1 and 2
        let normalized = ((combinedGoldLead - minGold) / (maxGold - minGold)) + 1;
        return normalized;
    }

    function getObjStats(towers, barons, dragons, rifts, visionScore){
        // this is because of Azir. I noticed it too late to try and fix the data
        if (towers > 11) towers = 11;

        const towerScore = towers / 11;
        const baronScore = barons / gameStats.gameStats.median_baron_per_game;
        const dragonScore = dragons / gameStats.gameStats.median_dragons;
        const riftScore = rifts / 2;

        const visionMax = gameStats.gameStats.max_vision_score;
        const visionMin = -visionMax;

        // normalize vision scores between 1 and 2
        const normalizedVision = ((visionScore - visionMin) / (visionMax - visionMin)) + 1;

        const totalObjScore = towerScore + baronScore + dragonScore + riftScore + normalizedVision;

        // Objective score NON NORMALIZED (will need to do it later)
        return totalObjScore;
    }


// Function to add or update the teams score
    function addScoreToTeam(name, score, wonGame) {
        // Check if an object with the given name already exists
        let existingObject = teams.find(obj => obj.Name === name);

        if (existingObject) {
            // If the object already exists, increment the counter and add the score
            existingObject.gamesPlayed++;
            existingObject.totalScore += score;
            existingObject.totalWins += (wonGame) ? 1 : 0;
        } else {
            let wins = (wonGame) ? 1 : 0;
            // If the object doesn't exist, create a new object and push it to the array
            const newObject = {
                Name: name,
                gamesPlayed: 1,
                totalScore: score,
                totalWins: wins
            };
            teams.push(newObject);
        }
    }

    function teamIdIsSelected(bId, rId) {
        //console.log(bId);
        for (let t in teamIds){
            if (teamIds[t] == bId || teamIds[t] ==rId){
                console.log("id"+ bId);
                return true;
            }
        }
        return false;
    }


    const tId = route.params.teamId;
    var minObjectiveScore = 99999999;
    var maxObjectiveScore = -9999999;

    // Couldn't find a better way to get max and min objective score by the quickly approaching deadline
    for (const t in tournamentGames.tournamentData.tournament) {
        const game = tournamentGames.tournamentData.tournament[t]
        const objectiveStat = getObjStats(game.towers_end, game.baron_end, game.dragon_end, game.rift_end, game.vision_score_diff_end);

        if (minObjectiveScore > objectiveStat) {
            minObjectiveScore = objectiveStat;
        }
        if (maxObjectiveScore < objectiveStat) {
            maxObjectiveScore = objectiveStat;
        }
    }
    var playoffCount = 0;
    //console.log(tournamentGames.tournamentData.tournament);
    for (const t in tournamentGames.tournamentData.tournament) {
        const game = tournamentGames.tournamentData.tournament[t];
        //console.log(game.blueside, game.redside);
        if (teamIdIsSelected(game.blueside, game.redside)){
            //tournamentName = game.slug;
            var gameStat =  getGoldStats(game.gold_diff_14, game.gold_diff_end);
            var objectiveStat = getObjStats(game.towers_end, game.baron_end, game.dragon_end, game.rift_end, game.vision_score_diff_end);

            // normalize objective stat
            const normalizedObjStat = ((objectiveStat - minObjectiveScore)/ (maxObjectiveScore - minObjectiveScore)) + 1
            var teamWon = false;
            if (game.winningteam == game.teamid)
            {
                teamWon = true;
            }

            // the idea was to pull what type of game it was played. Regular Season, Playoff, International. And give a bonus based on how they performed. But dont think time is going to let me try and figure it out
            const domesticLeagueBonus = (game.name == "Playoffs") ? gameStats.gameStats.playoff_multiplier : 1;
            
            // todo: Decide!!!
            const winLossBonus = teamWon ? gameStats.gameStats.win_multiplier : gameStats.gameStats.loss_multiplier;
            //const winLoss = (game.winningteam == game.teamid) ? gameStats.gameStats.win_bonus : gameStats.gameStats.loss_bonus;
            //const winLossBonus = winLoss;
            const teamScore = gameStat * normalizedObjStat * domesticLeagueBonus * winLossBonus
            //console.log(game);
            //Blue team data
            if (game.teamid == 100 && teamIdIsSelected(game.blueside, "")){
                addScoreToTeam(game.blueteam, teamScore, teamWon);
            }
             
            //red team data
            if (game.teamid == 200 && teamIdIsSelected("", game.redside)){
                addScoreToTeam(game.redteamname, teamScore, teamWon);
            }
        }
    }

    // sort and order the teams by score
    const sortedTeams = teams
  .map(team => {
    const scorePerGame = team.totalScore / team.gamesPlayed;
    return { ...team, scorePerGame };
  })
  .sort((a, b) => b.scorePerGame - a.scorePerGame);

console.log(sortedTeams);


</script>