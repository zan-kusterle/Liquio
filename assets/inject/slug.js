export default function (x) {
    return x.replace(/-|–|\./g, '').replace(/[^a-zA-Z\d\s:\-]/g, '').replace(/^[^a-zA-Z\d]+|\[^a-zA-Z\d]+$/g, '').trim().replace(/\s+/g, '-').toLowerCase()
}
