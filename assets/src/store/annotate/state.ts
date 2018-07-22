interface State {
	dialogVisible: boolean,
	nodes: NodeWithData[],
	definition: NodeDefinition,
	currentPage: string,
	currentSelection: string,
	currentVideoTime: number,
	activeDefinition: NodeDefinition,
	historyIndex: number
	history: NodeDefinition[],
}

let state: State = {
	dialogVisible: false,

	nodes: [],
	definition: null,

	currentPage: null,
	currentSelection: null,
	currentVideoTime: null,
	activeDefinition: null,

	historyIndex: -1,
	history: [],
}

export default state
