<template>
<div>
	<div v-if="node">
		<router-link :to="'/' + node.url_key" v-if="link == 'true'" class="title" style="display: inline; vertical-align: middle;">{{ node.title }}</router-link>
		<h1 v-else class="title" style="display: inline; vertical-align: middle;">{{ node.title }}</h1>

		<div class="score-container">
			<results v-bind:node="node" v-bind:results-key="resultsKey"></results>

			<i class="el-icon-caret-bottom" @click="isOpen = true" v-if="!isOpen"></i>

			<transition name="fade">
				<div class="vote-container" v-if="isOpen" v-bind:class="{open: isOpen}">
					<p style="margin-top: 15px; margin-bottom: 5px;" v-on:click="isOpen = false">
						Your choice
					</p>
					
					<own-vote v-bind:node="node" v-bind:results-key="resultsKey"></own-vote>
					<div class="votes" ng-if="node.results.contributions && node.results.contributions.length > 0" style="max-width: 800px; margin-left: auto; margin-right: auto;">
						<p style="margin-bottom: 5px;">Votes</p>
						<table class="contributions">
							<tr class="contribution" v-for="contribution in node.contributions">
								<td class="contribution">
									<div style="background: #1f8dd6; text-align: center; color: white; line-height: 32px; height: 32px;" v-bind:style="{'width': (contribution.weight * 100) + '%'}">
										{{ Math.round(contribution.weight * 100) + '%' }} 
									</div>
								</td>
								<td class="choice" v-html="contribution.embed_html"></td>
								<td class="username"><router-link :to="'/identities/' + contribution.identity.username">{{ contribution.identity.username }}</router-link></td>
								<td class="date">{{ contribution.datetime }}</td>
							</tr>
						</table>
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
		}
	}
}
</script>

<style scoped>
	.title {
		display: block;
		margin: 0px;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
	}
</style>