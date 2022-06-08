import { Phoo, initBuiltins, FetchLoader, ES6Loader, STACK_TRACE_SYMBOL, type } from '/phoo/src/index.js';
import stringify from './stringify.js';

var count = 0;
var run;
const esc = $.terminal.escape_brackets;
const naiveColorize = (text, color) => `[[;${color};]${esc(text)}]`;
// TODO: #5 fix font size getting bigger
const color = (text, color) => `<span style="color:${color};font-size:inherit">${text}</span>`;
var p, thread;

export const term = $('main').terminal(() => term.error('Hey! you should never see this'), {
    enabled: false,
    exit: false,
    greetings: 'Phoo is loading...',
    clear: false,
    prompt: () => naiveColorize(`(${count})--> `, 'magenta'),
    // autocompleteMenu: true,
    // async completion() {
    //     var text = this.get_command(), list = [];
    //     AAAAAAAAAAAA
    // },
});

$.terminal.syntax('phoo');
$.terminal.prism_formatters = {
    prompt: false,
    echo: false,
    command: true,
};

Object.assign(window, { stringify, color, term });

var loading = true;
(function () {
    var chars = '-\\|/';
    var i = 0;
    (function tick() {
        if (loading) {
            setTimeout(tick, 100);
            term.update(0, `Phoo is loading... ${chars[i]}`);
            if (++i == chars.length) i = 0;
        }
    })();
})();

// do load
(async () => {

    try {
        p = new Phoo({ loaders: [new FetchLoader('/phoo/lib/'), new ES6Loader('../lib/')] });

        thread = p.createThread('__main__');

        // patch console to show debug messages in terminal 
        window.console.debug = function patched(...items) {
            var joined = items.map(x => type(x) === 'string' ? x : stringify(x, { colorize: color })).join(' ');
            term.echo(color(`[DEBUG] ${joined}`, 'lime'), { raw: true });
        }

        await initBuiltins(thread, '/phoo/lib/builtins.ph');
        await thread.run(await (await fetch('/app/shell.ph')).text());

        loading = false;
        term.clear();
        term.enable();
        term.focus();
        await thread.run('__m__');
    } catch (e) {
        loading = false;
        term.error('\nEither an error occurred loading Phoo, or you\nmanaged to break the shell.');
        term.exception(e);
        term.error('Phoo stack trace:');
        term.error(e[STACK_TRACE_SYMBOL]);
        term.echo('Thread work stack:');
        term.echo(color(stringify(thread.workStack, { colorize: color }), 'inherit'), { raw: true });
        term.echo('If this continues to occur, please report it:');
        term.echo('https://github.com/phoo-lang/phoo/issues');
        term.disable();
        term.freeze();
        throw e;
    }
})();
