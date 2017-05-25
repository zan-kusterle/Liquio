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

export function encodeBase64(u8a) {
    var CHUNK_SZ = 0x8000
    var c = []
    for (var i = 0; i < u8a.length; i += CHUNK_SZ)
        c.push(String.fromCharCode.apply(null, u8a.subarray(i, i + CHUNK_SZ)))
    return btoa(c.join(""))
}

export function stringToBytes(s) {
    let buffer = []
    for (var i = 0; i < s.length; i++)
        buffer[i] = s.charCodeAt(i)
    return Uint8Array.from(buffer)
}