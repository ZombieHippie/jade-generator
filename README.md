# jade-generator

Generated jade code using a jade AST

[![Build Status](https://img.shields.io/travis/yangsu/jade-generator/master.svg)](https://travis-ci.org/yangsu/jade-generator)
[![Dependency Status](https://img.shields.io/gemnasium/yangsu/jade-generator.svg)](https://gemnasium.com/yangsu/jade-generator)
[![NPM version](https://img.shields.io/npm/v/jade-generator.svg)](https://www.npmjs.org/package/jade-generator)

## Installation

    npm install jade-generator

## Usage

```js
var lex = require('jade-lexer');
var parse = require('jade-parser');
var generator = require('jade-generator');

var ast = parse(lex('.my-class food'));

assert.deepEqual(parse(lex(generator(ast))), ast);
```

## TODOs

- [ ] correctly generate selfClosing properties on tags
- [ ] support inline tag syntaxt
- [ ] correctly generate line numbers

## License

  MIT
