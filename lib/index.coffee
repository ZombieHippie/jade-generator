_ = require('lodash')
serializers = require('./serializers')
{inspect} = require('util')

spaces = (n = 2) -> _.repeat(' ', n)

indent = (options, indentLevel = 0) ->
  space = spaces(options.spaces)
  _.repeat(space, Math.max(indentLevel - 1, 0))

NO_PREFIX = {noPrefix: true}

serializeNode = (node, options, lnDiff, indentLevel) ->
  serializer = serializers[node.type]
  if serializer?
    serialized = serializer(node, options, lnDiff)
    if serialized.length and serialized isnt '\n'
      newLines = lnDiff
      if newLines-- > 0 # lnDiff is greater than 0
        serialized = '\n' + indent(options, indentLevel) + serialized
      while newLines-- > 0
        serialized = '\n' + serialized
    do ->
      lnCount = serialized.split("\n").length - 1
      if lnCount isnt lnDiff
        throw "serialized error on lnDiff, expected: #{lnDiff} lns, got: #{lnCount} lns."
    return serialized
  else
    throw new Error("unexpected token '#{node.type}'")

# returns a `part` which consists of:
#   ln: the last line number of the part,
#   str: the string value of the part
# We need to return the `ln` because the serializers.coffee handles newlines
serializeAST = (ast, options, prevLine = 1, indentLevel = 0) ->
  currLine = ast.line or prevLine
  result = do ->
    lnDiff = currLine - prevLine
    console.log currLine, prevLine, lnDiff, ast.type
    serializeNode(ast, options, lnDiff, indentLevel)

  addASTResult = ({ln, str}) ->
    currLine = ln
    result += str

  switch ast.type
    when 'NamedBlock', 'Block'
      children = _.chain(ast.nodes)
        .map (node) ->
          if node.type is 'Block' and not node.yield
            newIndentLevel = indentLevel
          else
            newIndentLevel = indentLevel + 1
          part = serializeAST(node, options, currLine, newIndentLevel)
          currLine = part.ln # update current line with recent
          part
        .filter((part) -> _.isString(part.str) and part.str isnt '\n')
        .value()

      if children.length
        for part in children
          result += part.str

      return { str: result, ln: currLine }

    when 'Case', 'Each', 'When', 'Code'
      addASTResult(serializeAST(ast.block, options, currLine, indentLevel)) if ast.block
      if ast.alternative
        result += "\n#{indent(options, indentLevel)}else"
        currLine += 1
        addASTResult serializeAST(ast.alternative, options, currLine, indentLevel)
      # NOTE no indent need for code
      addASTResult serializeAST(ast.code, options, currLine, 0) if ast.code
    when 'BlockComment', 'Filter'
      addASTResult serializeAST(ast.block, _.extend({}, options, NO_PREFIX), currLine, indentLevel) if ast.block
    when 'Mixin', 'Tag'
      if ast.block
        blockOptions = _.clone(options)
        if ast.textOnly
          result += '.'
          _.extend(blockOptions, NO_PREFIX)
        addASTResult serializeAST(ast.block, blockOptions, currLine, indentLevel)

      # NOTE no indent need for code
      addASTResult serializeAST(ast.code, options, currLine, 0) if ast.code
    when 'Include'
      addASTResult serializeAST(ast.block, options, currLine, indentLevel) if ast.block
    when 'Extends', 'Attrs', 'Comment', 'Doctype', 'Literal', 'MixinBlock', 'Text'
      return { str: result, ln: currLine }
    when 'NewLine'
      return undefined
    else
      throw new Error("Unexpected node type #{ast.type}")

  return { str: result, ln: currLine }

module.exports = (ast, options = {}) ->
  console.log(inspect(ast, {depth: 20})) if options.debug
  serializeAST(ast, options).str

