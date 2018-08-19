export function compareComments (a: string[], b: string[]): boolean {
    if (a.length !== b.length)
        return false
    for (var i = 0; i < a.length; i++)
        if (a[i] !== b[i])
            return false
    return true
}

export function compareDefinition (a: NodeDefinition, b: NodeDefinition, excludeKeys?: string[]): boolean {
    return a.title === b.title && a.anchor === b.anchor && a.unit === b.unit && ((excludeKeys || []).includes('comments') || compareComments(a.comments, b.comments))
}
