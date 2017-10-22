export default {
    liquio: {
        'cursor': 'default',
        'font-family': 'Helvetica Neue, Helvetica, Arial, sans-serif',
        'position': 'fixed',
        'bottom': '20px',
        'right': '40px',
        'z-index': '1000',
        'color': 'black',

        '& > .score': {
            'width': '50px',
            'height': '50px',
            'line-height': '50px',
            'border-radius': '50%',
            'text-align': 'center',
            'font-size': '20px',
            'display': 'inline-block',
            'vertical-align': 'middle'
        },

        '& > .togglable': {
            'display': 'none',
            'background-color': 'rgba(0, 0, 0, 0.75)',
            'padding': '10px 25px',
            'margin-right': '20px',
            'border-radius': '2px',

            '& > .options': {
                'display': 'inline-block',
                'vertical-align': 'middle',
                'margin-right': '30px',

                '& > input': {
                    'width': '400px',
                    'border': 'none',
                    'outline': 'none',
                    'padding': '6px 12px',
                    'font-family': 'Helvetica Neue, Helvetica, Arial, sans-serif',

                    '&:focus': {
                        'box-shadow': 'none'
                    }
                }
            },

            '& > .view': {
                'display': 'inline-block',
                'vertical-align': 'middle',
                'font-size': '16px',
                'color': 'white',

                '&:hover': {
                    'color': '#ccc',
                    'cursor': 'pointer'
                }
            }
        }
    },
    button: {
        'display': 'inline-block',
        'vertical-align': 'middle',
        'width': '30px',
        'height': '30px',
        'opacity': 0.8
    },
    note: {
        'position': 'absolute',
        'left': '0px',
        'z-index': 100,
        'display': 'none',
        'cursor': 'default',
        'font-family': 'Helvetica Neue, Helvetica, Arial, sans-serif',
        'font-weight': 'normal',
        'color': 'white',
        'border-radius': '3px',
        'font-size': '14px',

        '& > .node': {
            'margin': '5px 0px',

            '& > .value': {
                'width': '150px',
                'height': '40px',
                'display': 'inline-block',
                'vertical-align': 'top',
                'font-weight': 'bold'
            },

            '& > .title': {
                'display': 'inline-block',
                'background-color': 'rgba(20, 20, 20, 0.9)',
                'padding': '0px 20px',
                'vertical-align': 'top',
                'height': '40px',

                '& > a': {
                    'color': 'white !important',
                    'vertical-align': 'middle',                    
                    'font-size': '14px !important',
                    'line-height': '38px',
                    'text-decoration': 'none !important',

                    '&:hover': {
                        'color': '#ddd !important'
                    }
                }
            }
        }
    }
}