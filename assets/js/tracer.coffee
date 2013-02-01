editor = ace.edit 'code'
editor.setTheme 'ace/theme/monokai'
editor.getSession().setMode 'ace/mode/javascript'
editor.setShowPrintMargin false
editor.getSession().on 'change', (event) ->
	display parse editor.getValue()

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
