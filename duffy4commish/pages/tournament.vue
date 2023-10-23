<script setup>
const {tournaments} = useTournaments();

</script>

<template>
    <h1>Tournament ranking</h1>
    <h4>Select which tournament you would like to see the rankings for:</h4>
    <div style="width: 100%">
        <template v-for="t in tournaments.tournaments" v-bind="t.id">
        
            <a :href="`/tournament/${t.id}`" style="margin: 5px;">{{ t.slug }}</a>
        
        </template>
    </div>
    <NuxtPage style="margin 10px;"></NuxtPage>
</template>

