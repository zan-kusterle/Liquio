<template>
<div>
	<div v-if="node">
		<router-link :to="'/' + node.url_key" v-if="link == 'true'" class="title" style="display: inline; vertical-align: middle;">{{ node.title }}</router-link>
		<h1 v-else class="title" style="display: inline; vertical-align: middle;">{{ node.title }}</h1>

		<div class="score-container">
			<results v-bind:node="node" v-bind:results-key="resultsKey"></results>

			<i class="el-icon-caret-bottom" @click="isOpen = true" v-if="votable != 'false' && !isOpen"></i>

			<transition name="fade">
				<div class="vote-container" v-if="isOpen" v-bind:class="{open: isOpen}">
					<p class="ui-title">Your choice</p>
					
					<own-vote v-on:change="refreshNode()" v-bind:node="node" v-bind:results-key="resultsKey"></own-vote>
					<div class="votes" ng-if="node.results.contributions && node.results.contributions.length > 0">
						<p class="ui-title">Votes</p>
						<div class="contribution" v-for="contribution in node.contributions">
							<div class="weight">
								<el-progress :text-inside="true" :stroke-width="18" :percentage="contribution.weight * 100"></el-progress>
							</div>
							<div class="choice" v-html="contribution.embed_html" style="height: 40px;"></div>
							<div class="username"><router-link :to="'/identities/' + contribution.identity.username">{{ contribution.identity.username }}</router-link></div>
							<div class="date">{{ moment(contribution.datetime).fromNow() }}</div>
						</div>
					</div>
				</div>
			</transition>
		</div>
	</div>
</div>
</template>

<script>
import Results from '../vue/results.vue'
import OwnVote from '../vue/own-vote.vue'

import Vue from 'vue'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'

Vue.use(ElementUI, {locale})

export default {
	props: ['node', 'resultsKey', 'votable', 'link'],
	components: {Results, OwnVote},
	data: function() {
		return {
			isOpen: false,
			mean: 0.5,
			moment: require('moment')
		}
	}
}
</script>

<style scoped>
	.ui-title {
		margin-top: 30px;
		margin-bottom: 10px;
		font-weight: bold;
	}

	.title {
		display: block;
		margin: 0px;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
	}

	.contribution {
		text-align: left;
		padding: 10px 30px
	}

	
	.weight {
		width: 350px;
		display: inline-block;
	}
	.choice {
		height: 40px;
		width: 100px;
		display: inline-block;
		vertical-align: middle;
		margin-left: 30px;
	}
	.username {
		width: 150px;
		display: inline-block;
		margin-left: 25px;
	}
	.date {
		width: 120px;
		display: inline-block;
		margin-left: 10px;
	}
</style>