<template>
<div class="faq">
	<h1 class="title">Frequently Asked Questions</h1>

	<div v-for="item in items" class="item">
		<p class="question">{{ item.question }}</p>
		<p class="answer" v-html="item.answer.replace(/\t/g, '&nbsp;').replace(/\n/g, '<br>')"></p>
	</div>
</div>
</template>

<script>
import App from '../app.vue'

export default {
	components: {App},
	props: [],
	data: function() {
		return {
			items: [
				{
					question: 'What is a trust metric?',
					answer: 'A whitelist of usernames whose votes and delegations will be used when calculating the final results.'
				},
				{
					question: 'Doesn\'t reliability of the results greatly depend on who is in a trust metric?',
					answer: 'Yes, trust metrics are the only subjective part of the platform and therefore the weakest spot. The good thing is you can choose your own trust metric.'
				},
				{
					question: 'What is the advantage of trust metrics?',
					answer: 'With most online communities there is a single source of trust, banlist,... Here everyone can choose a different trust metric, which makes Liquio completly open and democratic.'
				},
				{
					question: 'What do you mean by democratic?',
					answer: 'Liquio is a public database of votes and delegations. This means everyone can verify that results are correct or fine tune their computation.'
				},
				{
					question: 'What do you mean by cryptographically secure?',
					answer: 'Only the owner of the password (13 words) can sign votes and delegations to prove their integrity.'
				},
				{
					question: 'Why use IPFS?',
					answer: 'This prevents us from being able to remove votes once they are online. Every IPFS message contains starts with datetime and a public key.'
				},
				{
					question: 'IPFS: Identifications',
					answer: `Used to tie identities with URLs, or to set a public name.
					%{
						node => Path,
						key => String,
						name => String
					}`
				},
				{
					question: 'IPFS: Delegations',
					answer: `%{
						node => Path,
						unit => X-not X OR Name(Unit),
						unit => (True-False) OR Length(m),
						at_date => Grouping by month, set votes on records from the past,
						choice => Number
					}`
				},
				{
					question: 'IPFS: Votes',
					answer: 'Example: Human-activity-is-causing-global-warming True-False 0.20000 30-1-2017.'
				},
				{
					question: 'IPFS: References',
					answer: `%{
						node => Path,
						reference_node => Path,
						relevance => Number
					}`
				},
				{
					question: 'Does this mean anyone can build another client using the same data?',
					answer: 'Exactly. The common point is the ipfs format, which is simple'
				},
				{
					question: 'What is a node? Does slash (/) have a special meaning?',
					answer: 'This prevents us from being able to remove votes once they are online.'
				},
				{
					question: 'Vote date explained, grouping by unit. give example of chart poll?',
					answer: 'This prevents us from being able to remove votes once they are online.'
				},
				{
					question: 'What are references?',
					answer: 'A link between two nodes. Node can be an URL or any text'
				},
				
			]
		}
	}
}
</script>

<style lang="less" scoped>
.faq {
	padding: 0px 50px;

	.title {
		font-size: 20px;
		font-weight: normal;
		text-align: left;
	}

	.item {
		text-align: left;
		margin-top: 50px;

		.question {
			font-weight: bold;
			font-size: 16px;
		}
		.answer {
			font-size: 20px;
		}
	}
}
</style>
