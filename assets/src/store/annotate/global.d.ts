interface NodeDefinition {
    title: string
    anchor?: string
    unit: string
    comments: string[]
}

interface Contribution {
    username: string,
    votingPower: number,
    choice: number,
    atDate: string
}

interface Results {
    mean: number,
    median: number,
    contributions: Contribution[]
}

interface Comment {
    text: string,
    results: Results
}

interface Reference {
    definition: NodeDefinition,
    referenceResults: Results
}

interface NodeData {
    results: Results,
    comments: Comment[],
    references: Reference[],
    inverseReferences: Reference[]
}

interface NodeWithData {
    definition: NodeDefinition,
    data: NodeData
}
