<template>
<div>
	<div class="main">
		<div class="inset-top pure-g">
			<div class="pure-u-2-5">
				<%= for node <- @nodes do %>
					<liquio-node v-bind:node="nodes['<%= node.key %>']" votable="false" link="true"></liquio-node>
				<% end %>
			</div>
			<div class="pure-u-1-5">
				<img src="/images/arrow.svg" class="reference-arrow"></img>
			</div>
			<div class="pure-u-2-5">
				<%= for node <- @reference_nodes do %>
					<liquio-node v-bind:node="nodes['<%= node.key %>']" votable="false" link="true"></liquio-node>
				<% end %>
			</div>
		</div>

		<div class="main-node">
			<%= if @for_choice_node != nil do %>
				<liquio-node v-bind:node="forChoiceNode" results-key="for_choice" style="margin: 40px 0px;"></liquio-node>
			<% end %>
			
			<liquio-node v-bind:node="relevanceNode" results-key="relevance" style="margin: 40px 0px;"></liquio-node>
		</div>
	</div>

	<a @click="optionsOpen = true">Options</a>
	<calculation-opts v-bind:opts="nodes['<%= Enum.at(@nodes, 0).key %>'].calculation_opts" v-if="optionsOpen" @close="optionsOpen = false"></calculation-opts>
</div>
</template>
