export function parseVotes(text) {
    let lines = text.split('\n')
    var current_path = []
    var votes = []
    var referenceVotes = []
    _.each(lines, (line) => {
        line = line.replace(/\s\s\s\s/g, '\t')
        let num_indents = 0
        while (line[num_indents] == '\t') {
            num_indents++
        }
        let rest = line.substring(num_indents).trim()

        if (rest.length > 0) {
            if (line[0] !== '#') {
                let diff_indents = current_path.length - num_indents - 1
                if (diff_indents >= 0)
                    current_path = current_path.slice(0, current_path.length - diff_indents - 1)

                let words = rest.split(' ')
                let number = parseFloat(words[0])
                if (number) {
                    if (words[1] == '->') {
                        referenceVotes.push({
                            relevance: number,
                            path: current_path,
                            reference_path: words.slice(2).join(' ').split('/')
                        })
                    } else if (words[1] == '<-') {
                        referenceVotes.push({
                            relevance: number,
                            path: words.slice(2).join('-').split('/'),
                            reference_path: current_path
                        })
                    } else {
                        current_path.push(words.slice(2).join('-'))
                        votes.push({
                            choice: number,
                            unit: words[1].replace(':', ''),
                            path: current_path
                        })
                    }
                } else {
                    if (diff_indents === 0)
                        current_path = []
                    current_path.push(words.join('-'))
                }
            }
        }
    })

    return { votes, referenceVotes }
}

export function formatVotes(votes, referenceVotes) {
    var lines = []

    let recursive = (votes, currentPath) => {
        let depth = currentPath.length

        let currentReferenceVotes = _.filter(referenceVotes, (rv) => rv.path.join('/').toLowerCase() === currentPath.join('/').toLowerCase())
        _.each(currentReferenceVotes, (referenceVote) => {
            let referenceVoteText = '<b>' + referenceVote.relevance.toFixed(2) + ' -> </b>' + referenceVote.reference_path.join('/').replace(/-/g, ' ')
            for (var i = 0; i < depth; i++)
                referenceVoteText = '\t' + referenceVoteText
            lines.push(referenceVoteText)
        })

        let availableVotes = _.filter(votes, (v) => v.path.length > depth)
        let byPrefix = _.groupBy(availableVotes, (v) => v.path[depth])
        _.each(_.sortBy(Object.keys(byPrefix), (k) => -byPrefix[k].length), (prefix) => {
            let prefixVotes = byPrefix[prefix]
            let vote = _.find(prefixVotes, (v) => v.path.length - 1 === depth && v.path[depth] === prefix)
            let segment = prefix.replace(/-/g, ' ')
            if (vote)
                segment = '<b>' + vote.choice + ' ' + vote.unit + ': </b>' + segment
            for (var i = 0; i < depth; i++)
                segment = '\t' + segment

            lines.push(segment)
            recursive(prefixVotes, currentPath.slice().concat([prefix]))
        })
    }
    recursive(votes, [])

    return lines.join('\n')
}

export function formatNumber(number) {
    return Math.round(number * 10) / 10
}

export function getColor(mean) {
    if (mean == null) return "#ddd"
    if (mean < 0.25)
        return "rgb(255, 164, 164)"
    else if (mean < 0.75)
        return "rgb(249, 226, 110)"
    else
        return "rgb(140, 232, 140)"
}

export function slug(x) {
    return x.replace(/-|–|\./g, '').replace(/[^a-zA-Z\d\s:\-]/g, '').replace(/^[^a-zA-Z\d]+|\[^a-zA-Z\d]+$/g, '').trim().replace(/\s+/g, '-').toLowerCase()
}

export function colorOnGradient(color_a, color_b, ratio) {
    let hex = (x) => {
        x = x.toString(16)
        return (x.length == 1) ? '0' + x : x
    }

    var r = Math.ceil(parseInt(color_a.substring(0, 2), 16) * ratio + parseInt(color_b.substring(0, 2), 16) * (1 - ratio))
    var g = Math.ceil(parseInt(color_a.substring(2, 4), 16) * ratio + parseInt(color_b.substring(2, 4), 16) * (1 - ratio))
    var b = Math.ceil(parseInt(color_a.substring(4, 6), 16) * ratio + parseInt(color_b.substring(4, 6), 16) * (1 - ratio))

    return hex(r) + hex(g) + hex(b)
}

export function cleanUrl(url) {
    let clean = url.replace('://', ':')
    if (clean.endsWith('/'))
        clean = clean.substring(0, clean.length - 1)
    return clean
}

export function defaultUnit(node) {
    node.results && node.results.by_units["reliable"] && node.results.by_units["reliable"].average
    if (node.results) {
        let maxUnitKey = null
        for (var unitKey in node.results.by_units) {
            if (maxUnitKey == null || node.results.by_units[unitKey].turnout_ratio > node.results.by_units[maxUnitKey].turnout_ratio)
                maxUnitKey = unitKey
        }
        return maxUnitKey ? node.results.by_units[maxUnitKey] : null
    }
    return null
}