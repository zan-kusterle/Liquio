export function compareDefinition (a: NodeDefinition, b: NodeDefinition, excludeKeys?: string[]): boolean {
    let commentsEqual = true
    if (!(excludeKeys || []).includes('comments')) {
        commentsEqual = a.comments.length === b.comments.length
        if (commentsEqual) {
            for (var i = 0; i < a.comments.length; i++) {
                if (a.comments[i] !== b.comments[i]) {
                    commentsEqual = false
                }
            }
        }
    }
    return a.title === b.title && a.anchor === b.anchor && a.unit === b.unit && commentsEqual
}
