let storage = {
    get (key) {
        if (IS_EXTENSION) {
            return new Promise((resolve, reject) => {
                browser.storage.local.get(key).then((data) => {
                    resolve(data[key] || null)
                })
            })
        } else {
            return new Promise((resolve, reject) => {
                let value = localStorage.getItem(key) || null
                let items = value.split(';;').filter(v => v.length > 0)
                resolve(items.length > 1 ? items : value)
            })
        }
    },
    set (key, value) {
        if (IS_EXTENSION) {
            let data = {}
            data[key] = value
            browser.storage.local.set(data)
        } else {
            if (Array.isArray(value))
                value = value.join(';;')
            localStorage.setItem(key, value)
        }
    }
}

export default {
    setUsername (username) {
        storage.set('username', username)
    },
    getUsername () {
        return storage.get('username')
    },
    addSeed (seed) {
        let seeds = storage.get('seeds')
        seeds.push(seed)
        storage.set('seeds', seeds)
    },
    removeSeed (index) {
        let seeds = storage.get('seeds')
        seeds.splice(index, 1)
        storage.set('seeds', seeds)
    },
    getSeeds () {
        return storage.get('seeds')
    }
}