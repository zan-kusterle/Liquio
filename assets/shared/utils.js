export function encodeBase64(u8a) {
    var CHUNK_SZ = 0x8000
    var c = []
    for (var i = 0; i < u8a.length; i += CHUNK_SZ)
        c.push(String.fromCharCode.apply(null, u8a.subarray(i, i + CHUNK_SZ)))
    return btoa(c.join(""))
}

export function stringToBytes(s) {
    let buffer = []
    let bufferIndex = 0
    for (var i = 0; i < s.length; i++) {
        let code = s.charCodeAt(i)
        if (code <= 255) {
            buffer[bufferIndex] = code
            bufferIndex += 1
        } else {
            buffer[bufferIndex] = code >> 8
            buffer[bufferIndex + 1] = code & 255
            bufferIndex += 2
        }
    }
    return Uint8Array.from(buffer)
}