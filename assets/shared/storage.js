let storage = {
    get (key, type) {
        let decode = (v) => {
            if (!v) return null
            if (type === Array && !Array.isArray(v))
                return v.split(',')
            return v
        }

        if (IS_EXTENSION) {
            return new Promise((resolve, reject) => {
                browser.storage.local.get(key).then((data) => {
                    resolve(decode(data[key]))
                })
            })
        } else {
            return new Promise((resolve, reject) => {
                resolve(decode(localStorage.getItem(key)))
            })
        }
    },
    set (key, value) {
        let encoded = value
        if (Array.isArray(value))
            encoded = value.join(',')

        if (IS_EXTENSION) {
            let data = {}
            data[key] = encoded
            browser.storage.local.set(data)
        } else {
            localStorage.setItem(key, encoded)
        }
    }
}

export default {
    getSeeds () {
        return storage.get('seeds', Array)
    },
    getUsername () {
        return storage.get('username')
    },
    addSeed (seed) {
        storage.get('seeds', Array).then(seeds => {
            seeds.push(seed)
            storage.set('seeds', seeds)
        })
    },
    removeSeed (index) {
        storage.get('seeds', Array).then(seeds => {
            seeds.splice(index, 1)
            storage.set('seeds', seeds)
        })
    },
    setUsername (username) {
        storage.set('username', username)
    }
}