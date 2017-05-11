import $ from 'jquery'
import wui from 'webui-popover'
import _ from 'lodash'
import "../css/content.less"

$.expr[':'].icontains = function(a, i, m) {
    return slug($(a).text()).indexOf(slug(m[3])) >= 0
}

$.fn.getPath = function() {
    if (this.length != 1) throw 'Requires one element.';

    var path, node = this;
    while (node.length) {
        var realNode = node[0],
            name = realNode.localName;
        if (!name) break;
        name = name.toLowerCase();

        var parent = node.parent();

        var siblings = parent.children(name);
        if (siblings.length > 1) {
            name += ':eq(' + siblings.index(realNode) + ')';
        }

        path = name + (path ? '>' + path : '');
        node = parent;
    }

    return path;
}


var current_poll = null
var isOverlayOpen = false
let key = document.location.href.replace('://', ':')
if (key.endsWith('/'))
    key = key.substring(0, key.length - 1)

let getAddUrl = (x) => LIQUIO_URL + encodeURIComponent(x) + '/references'

let slug = (x) => {
    return x.replace(/-|–|\./g, '').replace(/[^a-zA-Z\d\s:\-]/g, '').replace(/^[^a-zA-Z\d]+|\[^a-zA-Z\d]+$/g, '').trim().replace(/ /g, '-').toLowerCase()
}

let colorOnGradient = (color_a, color_b, ratio) => {
    var hex = function(x) {
        x = x.toString(16);
        return (x.length == 1) ? '0' + x : x;
    };

    var r = Math.ceil(parseInt(color_a.substring(0, 2), 16) * ratio + parseInt(color_b.substring(0, 2), 16) * (1 - ratio))
    var g = Math.ceil(parseInt(color_a.substring(2, 4), 16) * ratio + parseInt(color_b.substring(2, 4), 16) * (1 - ratio))
    var b = Math.ceil(parseInt(color_a.substring(4, 6), 16) * ratio + parseInt(color_b.substring(4, 6), 16) * (1 - ratio))

    return hex(r) + hex(g) + hex(b)
}

if (!key.startsWith(LIQUIO_URL)) {
    setTimeout(() => {
        $(document).find('a').each((_, currentA) => {
            let url = currentA.origin + currentA.pathname
            if (url.endsWith('/'))
                url = url.substring(0, url.length - 1)

            let is_http = currentA.protocol === 'http:' || currentA.protocol === 'https:'
            let is_blank = currentA.target == "_blank"

            let a_hostname = currentA.hostname.split('.')
            let a_domain = a_hostname[a_hostname.length - 2]

            let current_hostname = window.location.hostname.split('.')
            let current_domain = current_hostname[current_hostname.length - 2]

            if (is_http && (a_domain !== current_domain || is_blank)) {
                $.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(url), (data) => {
                    let reliability_score = data.data.results && data.data.results.by_units["reliable"] && data.data.results.by_units["reliable"].average

                    if (reliability_score) {
                        let red = 'B51212'
                        let yellow = 'FCF119'
                        let green = '44DD25'
                        let color = reliability_score < 0.5 ? colorOnGradient(yellow, red, reliability_score * 2) : colorOnGradient(green, yellow, (reliability_score - 0.5) * 2)

                        let $a = $(currentA).css('border-top', '3px solid #' + color).css('padding-top', '2px')
                        $a.parent().css('overflow', 'visible')
                    }
                })
            }
        })
    }, 1500)

    $.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key), function(data) {
        let results = data.data.results
        let score = results.by_units['reliable'] ? results.by_units['reliable'].average : null
        if (score !== null) {
            chrome.runtime.sendMessage({ name: 'score', score: score })
        } else {
            // domain wide check?
        }
    })
}

$.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(key) + '?depth=2', function(data) {
    let node = data.data
    var nodes_by_text = {}

    node.references.forEach(function(reference) {
        reference.inverse_references.forEach(function(inverse_reference) {
            let topic = inverse_reference.path.join('/')
            if (topic.startsWith(key + '/')) {
                let remainder = topic.substring(key.length + 1)
                if (remainder.length > 0) {
                    let text = remainder.replace(/-/g, ' ')
                    if (!(text in nodes_by_text))
                        nodes_by_text[text] = []
                    nodes_by_text[text].push(reference)
                }
            }
        })
    })

    var nodes_by_container_id = {}
    var containers_by_id = {}
    for (var text in nodes_by_text) {
        let foundin = $('*:icontains("' + text + '")').last()
        if (foundin.length > 0) {
            let key = foundin.getPath()
            if (!nodes_by_container_id.hasOwnProperty(key))
                nodes_by_container_id[key] = []
            _.each(nodes_by_text[text], (node_in_container) => {
                if (!_.some(nodes_by_container_id[key], (n) => n.key == node_in_container.key))
                    nodes_by_container_id[key].push(node_in_container)
            })
            containers_by_id[key] = foundin
        }
    }

    for (var container_id in containers_by_id) {
        let container = containers_by_id[container_id]
        let nodes = nodes_by_container_id[container_id]

        let $button = '<a class="liquio-button"><img src="' + chrome.extension.getURL('icon128.png') + '"></img></a>'
        let textNode = container.contents().filter(function() {
            return this.nodeType == Node.TEXT_NODE;
        })
        if (textNode.length > 0) {
            textNode.after($button)
        } else {
            container.prepend($button)
        }

        $button = container.children('.liquio-button')

        let $content = _.map(nodes, (node) => {
            let units = node.results ? Object.values(node.results.by_units) : []
            let bestUnit = _.maxBy(units, (u) => u.turnout_ratio)
            let $a = '<a href="' + LIQUIO_URL + '/' + encodeURIComponent(node.path.join('/')) + '" target="_blank" class="title">' + node.path.join('/').replace(/-/g, ' ') + '</a>'
            return '<div class="liquio-node">' + (bestUnit && bestUnit.turnout_ratio > 0 ? '<div class="liquio-value">' + bestUnit.embeds.value + '</div>' : '') + '<div class="liquio-link">' + $a + '</div></div>'
        }).join('')
        let $note = '<div class="liquio-note">' + $content + '</div>'
        container.append($note)
        $note = container.children('.liquio-note')

        $button.click((e) => {
            let isShown = $note.is(':visible')
            $('.liquio-note').hide();
            if (!isShown) {
                //$note.css('top', ($button.offset().top + 35) + 'px')
                $note.css('top', '20px')
                $note.css('left', (Math.max(10, $button.offset().left - 495)) + 'px')
                $note.fadeIn(300)
                e.preventDefault()
                e.stopPropagation()
            }
        })
        $note.click((e) => {
            if (!e.target || e.target.tagName !== 'A')
                e.preventDefault()
            e.stopPropagation()
        })
    }
    $('body').click((e) => {
        $('.liquio-note').hide()
    })

    if (key.startsWith("https:www.youtube.com/watch")) {
        setupYoutube(nodes_by_text)
    }
})

function setupYoutube(nodes_by_text) {
    let player = document.getElementsByTagName('video')[0]
    let $player = $('#movie_player')
    $player.prepend('<div class="liquio-video-note"></div>')
    let $overlay = $player.children('.liquio-video-note')

    let update = function() {
        let time = player.currentTime
        chrome.runtime.sendMessage({ name: 'videoTime', time: player.currentTime })

        var new_poll = null
        for (var key in nodes_by_text) {
            let key_parts = key.replace('/', '').split(":")
            if (key_parts.length == 2) {
                let key_time = parseInt(key_parts[0]) * 60 + parseInt(key_parts[1])
                let delta = time - key_time
                if (delta >= 0 && delta <= 10) {
                    new_poll = nodes_by_text[key][0]
                }
            }
        }
        if (new_poll == null) {
            if (!isOverlayOpen)
                $overlay.fadeOut(1000)
        } else {
            if (current_poll == null || new_poll.id != current_poll.id) {
                $overlay.hide()
                let html = '<div class="liquio-node"><div class="liquio-value">' + (new_poll.results.by_units['count'] ? new_poll.results.by_units['count'].embeds.value : '') + '</div><a class="liquio-link" target="_blank" href="https://liqu.io/' + encodeURIComponent(new_poll.path.join('/')) + '">' + new_poll.path.join('/').replace(/-/g, ' ') + '</a></div>'
                $overlay.html(html)
                $overlay.fadeIn(1000)
            }
        }
        current_poll = new_poll
    }

    setInterval(update, 1000)
    $player.click(function(event) { update() })
}

(function(d, script) {
    script = d.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.onload = function() {
        // remote script has loaded
    };
    script.src = 'http://www.google-analytics.com/ga.js';
    d.getElementsByTagName('head')[0].appendChild(script);
}(document));