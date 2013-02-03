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


Range = ace.require('ace/range').Range

editor = ace.edit 'code'
editor.setTheme 'ace/theme/monokai'
editor.getSession().setMode 'ace/mode/javascript'
editor.setShowPrintMargin false
editor.getSession().on 'change', (event) ->
	try
		display treeify(parse editor.getValue())
	catch err
		#console.error err
		$('#chain').html()
		$('#tree').html err.toString()


parse = (code) ->
	esprima.parse code,
		range: true
		loc: true


showChain = (tree) ->
	vars = []
	cur = tree
	while cur?
		for variable in cur.root().variables
			vars.push(variable) unless (item.name for item in vars when item.name == variable.name).length > 0
		cur = cur.parent()
	chain = $('#chain').html ''
	$.each vars, (index, variable) ->
		item = $('<li>')
			.addClass('variable')
			.text(variable.name)
			.on 'hover', (event) ->
				switch event.type
					when 'mouseenter'
						select variable.loc
					when 'mouseleave'
						deselect()
					else
						# Ignore
			.appendTo chain




select = (loc) ->
	{ start: { line: a, column: b }, end: { line: c, column: d }} = loc
	editor.getSelection().setSelectionRange(new Range a-1, b, c-1, d)


deselect = ->
	editor.clearSelection()


display = (data) ->

	render = (tree, nesting) ->
		nesting ?= 0

		scope = $('<div>')
			.addClass('scope')
			.addClass("nested-#{nesting}")
			.on 'click', (event) ->
				event.stopPropagation()
				showChain tree
		if tree.root().variables.length
			variables = $('<ul>')
				.addClass('variables')
				.appendTo(scope)
			# Need closure in loop
			$.each(tree.root().variables, (index, variable) ->
				$('<li>')
				.addClass('variable')
				.text(variable.name)
				.on 'hover', (event) ->
					switch event.type
						when 'mouseenter'
							select variable.loc

						when 'mouseleave'
							deselect()

						else
							# nothing
				.appendTo(variables)
			)
		for child in tree._children
			scope.append(render(child, nesting + 1))
		return scope

	$('#chain').html('')
	$('#tree').html render data



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


class Scope

	constructor: (@loc) ->
		@loc ?=
			start:
				column: 0
				line: 0
			end:
				column: 0
				line: 0
		@range = [@loc.start.line, @loc.start.column, @loc.end.line, @loc.end.column]
		@variables = []
		#console.log 'new Scope(%o)', @loc

	add: (variable) ->
		throw 'Variable must be an instance of Variable' unless variable instanceof Variable
		@variables.push variable

	has: (id) ->
		(variable.name for variable in @variables when variable.name == id).length > 0



class Variable

	constructor: (@name, @loc) ->
		@loc ?=
			start:
				column: 0
				line: 0
			end:
				column: 0
				line: 0
		@range = [@loc.start.line, @loc.start.column, @loc.end.line, @loc.end.column]
		#console.log 'new Variable("%s", %o)', @name, @loc



treeify = (block, scope, declaration) ->
	# In case block is optional in parent block
	if not block then return scope

	# In case block is an array of blocks
	if block instanceof Array
		treeify(el, scope, declaration) for el in block
		return scope

	switch block.type
		when 'Identifier'
			if declaration
				if not scope.root().has block.name
					scope.root().add new Variable block.name, block.loc
				else
					console.log 'Variable %s already defined', block.name
		when 'FunctionDeclaration', 'FunctionExpression'
			local = new Tree scope, new Scope block.loc
			treeify block.id, scope
			treeify block.params, local, true
			treeify block.defaults, local
			treeify block.rest, local, true
			treeify block.body, local
			scope.add local
		when 'ObjectExpression'
			for prop in block.properties
				treeify prop.value, scope
		when 'Program'
			# Program creates a new scope
			scope = new Tree null, new Scope
			treeify block.body, scope
		when 'VariableDeclarator'
			treeify block.id, scope, true
			treeify block.init, scope
		else
			if Syntax.hasOwnProperty block.type
				for prop in Syntax[block.type]
					treeify block[prop], scope
			else
				#console.log 'No handler for type %s of %o', block.type, block

	scope