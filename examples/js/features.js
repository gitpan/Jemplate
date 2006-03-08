/* 
   This Javascript code was generated by Jemplate, the Javascript
   Template Toolkit. Any changes made to this file will be lost the next
   time the templates are compiled.

   Copyright 2006 - Ingy döt Net - All rights reserved.
*/

if (typeof(Jemplate) == 'undefined')
    throw('Jemplate.js must be loaded before any Jemplate template files');

Jemplate.templateMap['body.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
//line 1 "body.html"
output += context.process('header.html');
output += '\n\n';
//line 7 "body.html"

// FOREACH 
(function() {
    var list = [ 3, 6, 9 ];
    list = new Jemplate.Iterator(list);
    var retval = list.get_first();
    var value = retval[0];
    var done = retval[1];
    var oldloop;
    try { oldloop = stash.get('loop') } finally {}
    stash.set('loop', list);
    try {
        while (! done) {
            stash.data['x'] = value;
output += '\n';
//line 4 "body.html"
output += context.process('hacker.html', { 'name': 'miyagawa', 'number': 42 });
output += '\n';
//line 5 "body.html"
output += context.process('hacker.html', { 'name': 'ingy', 'number': 69 });
output += '\n';
//line 6 "body.html"
output += context.process('hacker.html', { 'name': '<yann>', 'number': 2 });
output += '\n';;
            retval = list.get_next();
            var value = retval[0];
            var done = retval[1];
        }
    }
    catch(e) {
        throw(context.set_error(e, output));
    }
    stash.set('loop', oldloop);
})();

output += '\n\n';
//line 9 "body.html"
stash.set('i', 3);
output += '\n';
//line 14 "body.html"
    
// WHILE
var failsafe = 1000;
while (--failsafe && (stash.get('i'))) {
output += '\n<h3>';
//line 11 "body.html"
output += stash.get('i');
output += '</h3>\n';
output += '\n';
//line 13 "body.html"
stash.set('i', stash.get('i') - 1);
output += '\n';
}
if (! failsafe)
    throw("WHILE loop terminated (> 1000 iterations)\n")

output += '\n\n';
//line 18 "body.html"

// WRAPPER
output += (function() {
    var output = '';
output += '\nLife is good\n';;
    var files = new Array('wrapper2.html', 'wrapper.html');
    for (var i = 0; i < files.length; i++) {
        output = context.include(files[i], { 'content': output });
    }
    return output;
})();

output += '\n\n';
//line 20 "body.html"
output += context.process('footer.html');
output += '\n\n';
//line 22 "body.html"
throw('Jemplate.STOP\n' + output);
output += '\nPlease Make It Stop\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

Jemplate.templateMap['footer.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
output += '<center><h3>The End</h3></center>\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

Jemplate.templateMap['hacker.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
//line 1 "hacker.html"
if (stash.get('number') % 2) {
output += 'Hello';
}
else {
output += 'Goodbye';
}

output += ' ';
//line 1 "hacker.html"

// FILTER
output += (function() {
    var output = '';


// FILTER
output += (function() {
    var output = '';

output += stash.get('name');

    return context.filter(output, 'upper', []);
})();


    return context.filter(output, 'html', []);
})();

output += '!!\n<hr>\n';
//line 3 "hacker.html"
return output;
output += '\n\nDon\'t show THIS!!\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

Jemplate.templateMap['header.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
output += '<h1>Enter the Dragons</h1>\n<hr>\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

Jemplate.templateMap['wrapper2.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
output += '<em>';
//line 1 "wrapper2.html"
output += stash.get('content');
output += '</em>\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

Jemplate.templateMap['wrapper.html'] = function(context) {
    if (! context) throw('Jemplate function called without context\n');
    var stash = context.stash;
    var output = '';

    try {
output += 'And Yann added: \n<blockquote>';
//line 2 "wrapper.html"
output += stash.get('content');
output += '</blockquote>\nAnd everyone agreed\n\n';
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    return output;
}

