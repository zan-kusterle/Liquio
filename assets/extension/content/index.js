jQuery.expr[':'].icontains = function(a, i, m) {
  return jQuery(a).text().toUpperCase()
      .indexOf(m[3].toUpperCase()) >= 0;
};

function pad(n, width, z) {
	z = z || '0';
	n = n + '';
	return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
}

var current_poll = null;
var isOverlayOpen = false;
let url = document.location.href;
let key = encodeURIComponent(url);

$.get('https://liqu.io/api/nodes/' + key, function(data) {
	let node = data.data;
	var nodes_by_text = {};
	node.references.forEach(function(reference) {
		reference.inverse_references.forEach(function(inverse_reference) {
			if(inverse_reference.url_key.startsWith(key)) {
				let remainder = inverse_reference.url_key.replace(key, '')
				if(remainder.length > 0) {
					let text = decodeURIComponent(remainder.replace(/-/g, ' '))
					if(!(text in nodes_by_text))
						nodes_by_text[text] = [];
					nodes_by_text[text].push(reference); 
				}
			}
		});
	});
	
	for(var text in nodes_by_text) {
		let node = nodes_by_text[text][0];
		console.log(node)
		let foundin = $('*:icontains("' + text + '")').last();
		foundin.find('br').remove();
		foundin.append('<a href="https://liqu.io/' + node.url_key + '" target="_blank" class="liquio-link-inline-button"><p class="title">' + node.title + '</p>' + node.results.embed + '</a>');
	}

	if(url.startsWith("https://www.youtube.com/watch")) {
		setupYoutube(nodes_by_text);
	}
});


function setupYoutube(nodes_by_text) {
	let player = document.getElementsByTagName('video')[0];
	let $player = $('#movie_player');
	$player.append('<div id="liquio-link-overlay"><div class="main"></div><div class="details"></div></div>');
	let $overlay = $('#liquio-link-overlay');
	let $overlay_main = $overlay.find('.main');
	let $overlay_details = $overlay.find('.details');
	$overlay_details.hide();
	$('.ytp-right-controls', $player).prepend('<button id="liquio-link-add" class="ytp-subtitlesa-button ytp-button" aria-pressed="false" title="Add poll at current time"></button>');
	let $add = $('#liquio-link-add');
	$add.html(`
	<svg height="100%" version="1.1" viewBox="-50 -50 200 200" width="100%">
		<line x1="14" y1="14" x2="30" y2="82" style="stroke: white; stroke-width: 8;"></line>
		<line x1="78" y1="45" x2="30" y2="82" style="stroke: white; stroke-width: 8;"></line>

		<circle cx="14" cy="14" r="14" fill="white"></circle>
		<circle cx="30" cy="82" r="18" fill="white"></circle>
		<circle cx="78" cy="45" r="22" fill="white"></circle>
	</svg>
	`);

	let set_overlay_open = function(isOpen) {
		let rect = $player[0].getBoundingClientRect();
		isOverlayOpen = isOpen;

		let $overlay_references = $overlay_details.find('.polls');
		if(rect.height >= 600) {
			$overlay_references.css({'max-height': '400px'});
		} else {
			$overlay_references.css({'max-height': '200px'});
		}

		if(isOpen) {
			$overlay_details.slideDown(200);
			$overlay.css({
				'padding': '20px 40px',
				'background-color': 'rgba(0, 0, 0, 0.5)',
				'border': '1px solid rgba(0, 0, 0, 0.7)',
				'border-left': 'none'
			});
		} else {
			$overlay_details.slideUp(200);
			$overlay.css({
				'padding': '10px 15px 10px 40px',
				'background-color': 'rgba(31, 141, 214, 0.3)',
				'border': 'none'
			});
		}
		
		var top;
		if(isOverlayOpen) {
			if(rect.height >= 600) {
				top = 150;
			} else {
				top = 50;
			}
		} else {
			if(rect.height >= 600) {
				top = rect.height - 250;
			} else {
				top = rect.height - 150;
			}
		}
		
		$overlay.css({'top': top+ 'px'});
	};

	$overlay.click(function() {
		set_overlay_open(!isOverlayOpen);
	});

	$add.click(function() {
		let time = player.currentTime;
		let time_s = Math.floor(time / 60) + ':' + pad(Math.floor(time - Math.floor(time / 60) * 60), 2);
		let url = 'https://liqu.io/' + encodeURIComponent(document.location.href) + '_' + encodeURIComponent(document.location.href + '/' + time_s) + '/references';
		var win = window.open(url, '_blank');
		if (win) {
			win.focus();
		}
	});

	let update = function() {
		let time = player.currentTime;
		set_overlay_open(isOverlayOpen);

		var new_poll = null;
		for(var key in nodes_by_text) {
			let key_parts = key.replace('/', '').split(":");
			if(key_parts.length == 2) {
				let key_time = parseInt(key_parts[0]) * 60 + parseInt(key_parts[1]);
				let delta = time - key_time;
				if(delta >= 0 && delta <= 10) {
					new_poll = nodes_by_text[key][0];
				}
			}
		}
		if(new_poll == null) {
			if(!isOverlayOpen)
				$overlay.fadeOut(1000);
		} else {
			if(current_poll == null || new_poll.id != current_poll.id) {
				$overlay.hide();
				let html = '<div class="poll" style="display: inline-block; width: 120px; height: 50px; margin-right: 10px;">' + new_poll.results.embed + '</div><p class="title">' + new_poll.title + '</p>';
				$overlay_main.html(html);
				$overlay_details.html('<div class="references"><div class="polls"></div></div><a href="https://liqu.io/' + new_poll.url_key + '" target="_blank">View on Liquio &nbsp;&rarr;</a>');
				let $overlay_references = $overlay_details.find('.references').find('.polls');
				new_poll.references.forEach(function(reference) {
					$overlay_references.append('<div class="poll">' + reference.poll.html + '<p class="title">' + reference.poll.title + '</p></div>');
				});
				$overlay.fadeIn(1000);
			}
		}
		current_poll = new_poll;
	};

	setInterval(update, 1000);
	$player.click(function(event) { update(); });
}
