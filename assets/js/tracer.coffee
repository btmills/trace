class Tree

	constructor: (@_parent, @_root, children) ->
		@_children = []
		@add child for child in children if children instanceof Array

	parent: (parent) =>
		if parent is undefined
			@_parent
		else
			@_parent = parent
			@

	root: (root) =>
		if root is undefined
			@_root
		else
			@_root = root
			@

	add: (child) ->
		@_children.push if child instanceof Tree then child.parent @ else new Tree @, child
		@

	toString: (ind) ->
		ind ?= 0
		str = ''
		str += (' ' for i in [0...(4*ind)]).join ''
		str += '('
		str += @_root
		if @_children.length
			str += ', ['
			str += '\n'
			str += child.toString(ind + 1) + ',\n' for child in @_children
			str += (' ' for i in [0...(4*ind)]).join ''
			str += ']'
		str += ')'
		return str

	toObject: ->
		return {
			root: @_root,
			children: (child.toObject() for child in @_children)
		}

	toJSON: ->
		return JSON.stringify @toObject(), null, 2


editor = ace.edit 'code'
editor.setTheme 'ace/theme/monokai'
editor.getSession().setMode 'ace/mode/javascript'
editor.setShowPrintMargin false
editor.getSession().on 'change', (event) ->
	try
		display treeify(parse editor.getValue()).toString()

output = ace.edit 'output'
output.setTheme 'ace/theme/monokai'
output.getSession().setMode 'ace/mode/json'
output.setReadOnly true
output.setHighlightActiveLine false
output.setShowPrintMargin false


parse = (code) ->
	try
		esprima.parse code
	catch err
		{ 'Parse error': err }


display = (data) ->
	try
		data = JSON.stringify(data, null, 2) unless typeof data == 'string'
	catch err
		data = { 'JSON error': err }
	output.setValue(data)
	output.clearSelection()


Syntax =
	ArrayExpression: ["elements"]
	AssignmentExpression: ["left", "right"]
	BinaryExpression: ["left", "right"]
	BlockStatement: ["body"]
	BreakStatement: ["label"]
	CallExpression: ["callee", "arguments"]
	CatchClause: ["param", "guard", "body"]
	ConditionalExpression: ["test", "alternate", "consequent"]
	ContinueStatement: ["label"]
	DebuggerStatement: []
	DoWhileStatement: ["init", "test", "update", "body"]
	EmptyStatement: []
	ExpressionStatement: ["expression"]
	ForInStatement: ["left", "right", "body"]
	ForStatement: ['init', 'test', 'update', "body"]
	FunctionDeclaration: ["id", "params", "defaults", "rest", "body"]
	FunctionExpression: ["id", "params", "defaults", "rest", "body"]
	Identifier: [] # Special
	IfStatement: ["test", "consequent", "alternate"]
	LabeledStatement: ["label", "body"]
	Literal: []
	LogicalExpression: ["left", "right"]
	MemberExpression: ["object", "property"]
	NewExpression: ["callee", "arguments"]
	ObjectExpression: ["properties"] # Special
	Pattern: []
	Program: ["body"]
	#Property: []
	ReturnStatement: ["argument"]
	SequenceExpression: ["expressions"]
	SwitchCase: ["test", "consequent"]
	SwitchStatement: ["discriminant", "cases"]
	ThisExpression: []
	ThrowStatement: ["argument"]
	TryStatement: ["block", "handler", "guardedHandlers", "finalizer"]
	UnaryExpression: ["argument"]
	UpdateExpression: ["argument"]
	VariableDeclaration: ["declarations"]
	VariableDeclarator: ["init"] # Special
	WhileStatement: ["test", "body"]
	WithStatement: ["object", "body"]
	#'ArrayPattern': ['elements'], # Harmony
	#'ComprehensionBlock': ['left', 'right'], # Harmony
	#'ComprehensionExpression': ['blocks', 'filter'], # Harmony
	#'ForOfStatement': ['left', 'right', 'body'], # Harmony, Special
	#'GeneratorExpression': ['blocks', 'filter'], # Harmony
	#'LetExpression': ['head', 'body'], # Harmony, Special
	#'LetStatement': ['head', 'body'], # Harmony
	#'ObjectPattern': ['properties'], # Harmony, Special
	#'YieldExpression': ['argument'] # Harmony


treeify = (block, scope, identifiers) ->
	scope = new Tree(null, []) unless scope?

	if not block then return scope

	if block instanceof Array
		treeify(el, scope, identifiers) for el in block
		return scope

	switch block.type
		when 'Identifier'
			if identifiers
				if -1 == scope.root().indexOf block.name
					scope.root().push block.name
				else
					#console.log 'Variable %s already defined', block.name
		when 'FunctionDeclaration', 'FunctionExpression'
			local = new Tree(scope, [])
			treeify block.id, scope
			treeify block.params, local, true
			treeify block.defaults, local
			treeify block.rest, local, true
			treeify block.body, local
			scope.add local
		when 'ObjectExpression'
			for prop in block.properties
				treeify prop.value, scope
		when 'VariableDeclarator'
			treeify block.id, scope, true
			treeify block.init, scope
		else
			if Syntax.hasOwnProperty block.type
				for prop in Syntax[block.type]
					treeify block[prop], scope
			else
				console.log 'No handler for type #{block.type}'

	scope