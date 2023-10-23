
<template>
    <div style="background-color: greenyellow;">
        <div>
            <h2>Tournament Ranking: Global</h2>
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
        <div>
            <h2>Tournament Game Data</h2>
            <table>
                <tr>
                    <th>Slug</th>
                    <th>Name</th>
                    <th>Blue Team</th>
                    <th>Red Team </th>
                    <th>Team ID</th>
                    <th>Winning Team</th>
                    <th>Gold Diff 14</th>
                    <th>Gold Diff End</th>
                    <th>Towers End</th>
                    <th>Baron End</th>
                    <th>Dragon End</th>
                    <th>Rift End</th>
                    <th>Vision Score Diff End</th>
                </tr>

                <template v-for="t in tournamentData.tournament" :key="t.gameid">
                    <tr>
                        <td>{{ t.slug }}</td>
                        <td>{{ t.name }}</td>
                        <td>{{ t.blueteam }}</td>
                        <td>{{ t.redteamname }}</td>
                        <td>{{ (t.teamid == 100)? "blue" : "red" }}</td>
                        <td>{{(t.winningteam == 100)? "blue" : "red"  }}</td>
                        <td>{{ t.gold_diff_14 }}</td>
                        <td>{{ t.gold_diff_end }}</td>
                        <td>{{ t.towers_end }}</td>
                        <td>{{ t.baron_end }}</td>
                        <td>{{ t.dragon_end }}</td>
                        <td>{{ t.rift_end }}</td>
                        <td>{{ t.vision_score_diff_end }}</td>
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
    let rankCounter = 1;

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
            existingObject.totalScoreArray.push(score);
        } else {
            let wins = (wonGame) ? 1 : 0;
            // If the object doesn't exist, create a new object and push it to the array
            const newObject = {
                Name: name,
                gamesPlayed: 1,
                totalScore: score,
                totalWins: wins,
                totalScoreArray: [score]
            };
            teams.push(newObject);
        }
    }

    function median(arr) {
   const mid = Math.floor(arr.length / 2);
   const sortedArr = arr.sort((a, b) => a - b);
 
   if (arr.length % 2 === 0) {
      return (sortedArr[mid - 1] + sortedArr[mid]) / 2;
   } else {
      return sortedArr[mid];
   }
}


    const tId = route.params.tournamentId;
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
    
    for (const t in tournamentGames.tournamentData.tournament) {
        const game = tournamentGames.tournamentData.tournament[t];
        
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
        
        //Blue team data
        if (game.teamid == 100){
            addScoreToTeam(game.blueteam, teamScore, teamWon);
        }
            
        //red team data
        if (game.teamid == 200){
            addScoreToTeam(game.redteamname, teamScore, teamWon);
        }
    }

    /* sort and order the teams by score */
    const sortedTeams = teams
    .map(team => {
        const scorePerGame = team.totalScore / team.gamesPlayed;
        return { ...team, scorePerGame };
    })
    .sort((a, b) => b.scorePerGame - a.scorePerGame);

    /*console.log(teams[0]);
    for (var t in teams)
    {
        var medianVal = median(teams[t].totalScoreArray);
        teams[t].totalScore = medianVal;
    }

    
    const sortedTeams = teams
    .map(team => {
        const scorePerGame = team.totalScore;
        return { ...team, scorePerGame };
    })
    .sort((a, b) => b.scorePerGame - a.scorePerGame); */

</script>