editor = ace.edit 'code'
editor.setTheme 'ace/theme/monokai'
editor.getSession().setMode 'ace/mode/javascript'
editor.setShowPrintMargin false
editor.getSession().on 'change', (event) ->
	try
		output.setValue JSON.stringify esprima.parse(editor.getValue()), null, 2
		output.clearSelection()

output = ace.edit 'output'
output.setTheme 'ace/theme/monokai'
output.getSession().setMode 'ace/mode/json'
output.setReadOnly true
output.setHighlightActiveLine false
output.setShowPrintMargin false