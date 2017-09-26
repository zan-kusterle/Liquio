from bs4 import BeautifulSoup

html_doc = """
<!DOCTYPE html>
<html>

<head>
    <meta property="liquio:pubkey" content="pdu5cjZTi7kf7nC78l2b3+eCyh4Oa5f64zoIqQSiyLY="></meta>
</head>

<body>
    <a href="https://liqu.io/" choice="0.9">Human activity is causing global warming</a>

    <div>
        <h2 liquio-node="Net-dept-in-the-USA" unit="Money(USD)" choice="2016:120B | 2017:52B">
            Trump has cut the U.S. debt burden by $68 billion dollars.
        </h2>
    </div>

    <script>
        (function(d, script) {
            script = d.createElement('script');
            script.type = 'text/javascript';
            script.async = true;
            script.onload = function() {};
            script.src = 'C:/Users/zan/Documents/LiquioInject/inject.js';
            d.getElementsByTagName('head')[0].appendChild(script);
        }(document));
    </script>
</body>

</html>
"""

soup = BeautifulSoup(html_doc, 'html.parser')


liquio_nodes = soup.findAll(lambda tag: tag.has_attr('liquio-node'))
for liquio_node in liquio_nodes:
	vote = {
		'name': liquio_node.text.replace('\n', '').strip(),
		'unit': liquio_node["unit"],
		'choice': liquio_node["choice"]
	}
	print(vote)
#print(soup.prettify())