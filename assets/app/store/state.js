import { allUnits } from 'shared/data'

export default {
    nodes: [],
    references: [],
    identities: [],
    storageSeeds: localStorage.seeds || '',
    currentKeyPairIndex: localStorage.currentIndex ? parseInt(localStorage.currentIndex) : 0,
    trustMetricURL: localStorage.trustMetricURL || (process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html')
}