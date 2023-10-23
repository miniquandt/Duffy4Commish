<script setup>
const {teams} = useTeams();
const route = useRoute();

const tId = (route.params.teamId != undefined) ? route.params.teamId + "+" : "";

</script>

<template>
    <h1>Team ranking</h1>
    <h4>Select which Teams would you like to see the rankings for:</h4>
    <div style="width: 100%">
         <template v-for="t in teams" v-bind="t.id">
        
            <a :href="`/team/${tId}${t.id}`" style="margin: 5px;">{{ t.name }}</a>
        
        </template>
    </div>
    <NuxtPage style="margin 10px;"></NuxtPage>
</template>

