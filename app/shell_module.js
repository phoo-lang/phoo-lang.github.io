import { term } from './main.js';
import { Module } from '/phoo/src/namespace.js';
import { naiveCompile } from '/phoo/src/index.js';
export const module = new Module('__shell__');

module.words.add('echo', function ech() {
    term.echo(this.pop());
});

module.words.add('recho', function rech() {
    term.echo(this.pop(), { raw: true });
});

module.words.add('alert', function a() {
    alert(this.pop());
});

module.words.add('confirm', function c() {
    this.push(confirm(this.pop()));
});

module.words.add('prompt', function p() {
    this.push(prompt(this.pop()));
});

module.words.add('input', async function i() {
    term.resume();
    this.push(await term.read(this.pop()));
});

module.words.add('nl', function nl() {
    term.echo();
});

module.words.add('sp', function sp() {
    term.echo(' ', { newline: false });
});

module.words.add('cc', function cc() {
    term.clear();
});

module.words.add('delay', async function d() {
    var x = this.pop();
    await new Promise(r => setTimeout(r, x));
});

module.words.add('emptystack', naiveCompile('stacksize while drop again'));