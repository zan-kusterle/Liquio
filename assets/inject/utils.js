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

export function getUrl(url, success, error) {
    var request = new XMLHttpRequest()
    request.open('GET', url, true)

    request.onload = function () {
        if (request.status >= 200 && request.status < 400) {
            var resp = request.responseText
            success(JSON.parse(resp))
        } else {
            error()
        }
    }

    request.onerror = function () {
        error()
    }

    request.send()
}