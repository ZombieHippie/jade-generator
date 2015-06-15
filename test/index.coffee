fs = require('fs')
path = require('path')
Q = require('q')
_ = require('lodash')
{assert} = require('chai')
parse = require('jade-parser')
lex = require('jade-lexer')
lib = require('../')

casesPath = "#{__dirname}/cases"

dirfile = (f) -> path.join(casesPath, f)
readFile = (f) -> fs.readFileSync(dirfile(f), 'utf8')
writeFile = (f, content) -> fs.writeFileSync(dirfile(f), content, 'utf8')

cases = _.filter fs.readdirSync(casesPath), (testCase) ->
  not /\.generated/.test(testCase) and
  /^text\.jade$/.test(testCase) and
  # TODO: support inline-tag
  testCase isnt 'inline-tag.jade'

stripUnsupportedProperties = (ast = {}) ->
  for key, val of ast
    if _.isObject(val)
      ast[key] = stripUnsupportedProperties(val)
    else if _.isArray(val)
      ast[key] = _.map val, stripUnsupportedProperties
  ast #_.omit(ast, 'line', 'selfClosing')

describe 'cases', ->
  _.each cases, (testCase, i) ->
    describe "#{i}. #{testCase}:", ->
      it "resulting source should have the same ast as the original", ->
        ast = parse(lex(readFile(testCase), testCase))
        writeFile(testCase.replace('.jade', '.json'), JSON.stringify(ast, null, 2))
        result = lib(ast)
        writeFile(testCase.replace('.jade', '.generated.jade'), result)
        newAst = parse(lex(result, testCase))
        writeFile(testCase.replace('.jade', '.generated.json'), JSON.stringify(newAst, null, 2))
        assert.deepEqual stripUnsupportedProperties(newAst), stripUnsupportedProperties(ast)
