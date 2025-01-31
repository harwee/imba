var sha1 = require '../../vendor/sha1'

var ansiMap =
	reset: [0, 0],
	bold: [1, 22],
	dim: [2, 22],
	italic: [3, 23],
	underline: [4, 24],
	inverse: [7, 27],
	hidden: [8, 28],
	strikethrough: [9, 29]
	
	black: [30, 39],
	red: [31, 39],
	green: [32, 39],
	yellow: [33, 39],
	blue: [34, 39],
	magenta: [35, 39],
	cyan: [36, 39],
	white: [37, 39],
	gray: [90, 39],
	
	redBright: [91, 39],
	greenBright: [92, 39],
	yellowBright: [93, 39],
	blueBright: [94, 39],
	magentaBright: [95, 39],
	cyanBright: [96, 39],
	whiteBright: [97, 39]

export var ansi =
	bold: do |text| '\u001b[1m' + text + '\u001b[22m'
	red: do |text| '\u001b[31m' + text + '\u001b[39m'
	green: do |text| '\u001b[32m' + text + '\u001b[39m'
	yellow: do |text| '\u001b[33m' + text + '\u001b[39m'
	gray: do |text| '\u001b[90m' + text + '\u001b[39m'
	white: do |text| '\u001b[37m' + text + '\u001b[39m'
	f: do |name,text|
		let pair = ansiMap[name]
		return '\u001b['+pair[0]+'m' + text + '\u001b['+pair[1]+'m'

ansi:warn = ansi:yellow
ansi:error = ansi:red

export def brace str
	var lines = str.match(/\n/)
	# what about indentation?

	if lines
		'{' + str + '\n}'
	else
		'{\n' + str + '\n}'

export def normalizeIndentation str
	var m
	var reg = /\n+([^\n\S]*)/g
	var ind = null

	while m = reg.exec(str)
		var attempt = m[1]
		if ind is null or 0 < attempt:length < ind:length
			ind = attempt

	str = str.replace(RegExp("\\n{ind}","g"), '\n') if ind
	return str

export def flatten arr
	var out = []
	arr.forEach do |v| v isa Array ? out:push.apply(out,flatten(v)) : out.push(v)
	return out


export def pascalCase str
	str.replace(/(^|[\-\_\s])(\w)/g) do |m,v,l| l.toUpperCase

export def camelCase str
	str = String(str)
	# should add shortcut out
	str.replace(/([\-\_\s])(\w)/g) do |m,v,l| l.toUpperCase

export def dashToCamelCase str
	str = String(str)
	if str.indexOf('-') >= 0
		# should add shortcut out
		str = str.replace(/([\-\s])(\w)/g) do |m,v,l| l.toUpperCase
	return str

export def snakeCase str
	var str = str.replace(/([\-\s])(\w)/g,'_')
	str.replace(/()([A-Z])/g,"_$1") do |m,v,l| l.toUpperCase

export def setterSym sym
	dashToCamelCase("set-{sym}")

export def quote str
	'"' + str + '"'

export def singlequote str
	"'" + str + "'"

export def symbolize str
	str = String(str)
	var end = str.charAt(str:length - 1)

	if end == '='
		str = 'set' + str[0].toUpperCase + str.slice(1,-1)

	if str.indexOf("-") >= 0
		str = str.replace(/([\-\s])(\w)/g) do |m,v,l| l.toUpperCase
			
	return str


export def indent str
	String(str).replace(/^/g,"\t").replace(/\n/g,"\n\t").replace(/\n\t$/g,"\n")

export def bracketize str, ind = yes
	str = "\n" + indent(str) + "\n" if ind
	'{' + str + '}'
	
export def parenthesize str
	'(' + String(str) + ')'

export def unionOfLocations *locs
	var a = Infinity
	var b = -Infinity

	for loc in locs
		if loc and loc.@loc != undefined
			loc = loc.@loc

		if loc and loc:loc isa Function
			loc = loc.loc

		if loc isa Array
			a = loc[0] if a > loc[0]
			b = loc[1] if b < loc[0]
		elif loc isa Number
			a = loc if a > loc
			b = loc if b < loc

	return [a,b]
				


export def locationToLineColMap code
	var lines = code.split(/\n/g)
	var map = []

	var chr
	var loc = 0
	var col = 0
	var line = 0

	while chr = code[loc]
		map[loc] = [line,col]

		if chr == '\n'
			line++
			col = 0
		else
			col++

		loc++

	return map

export def markLineColForTokens tokens, code
	self

export def parseArgs argv, o = {}
	var aliases = o:alias ||= {}
	var groups = o:groups ||= []
	var schema = o:schema || {}

	schema:main = {}

	var options = {}
	var explicit = {}
	argv = argv || process:argv.slice(2)
	var curr = null
	var i = 0
	var m

	while(i < argv:length)
		var arg = argv[i]
		i++

		if m = arg.match(/^\-([a-zA-Z]+)$/)
			curr = null
			let chars = m[1].split('')

			for item,i in chars
				# console.log "parsing {item} at {i}",aliases
				var key = aliases[item] or item
				chars[i] = key
				options[key] = yes

			if chars:length == 1
				curr = chars

		elif m = arg.match(/^\-\-([a-z0-9\-\_A-Z]+)$/)
			var val = true
			var key = m[1]

			if key.indexOf('no-') == 0
				key = key.substr(3)
				val = false

			for g in groups
				if key.substr(0,g:length) == g
					console.log 'should be part of group'

			key = dashToCamelCase(key)

			options[key] = val
			curr = key

		else
			var desc = schema[curr]

			unless curr and schema[curr]
				curr = 'main'

			if arg.match(/^\d+$/)
				arg = parseInt(arg)

			var val = options[curr]
			if val == true or val == false
				options[curr] = arg
			elif val isa String or val isa Number
				options[curr] = [val].concat(arg)
			elif val isa Array
				val.push(arg)
			else
				options[curr] = arg
			
			unless desc and desc:multi
				curr = 'main'

	if options:env isa String
		options["ENV_{options:env}"] = yes

	return options
	
export def printExcerpt code, loc, hl: no, gutter: yes, type: 'warn', pad: 2
	var lines  = code.split(/\n/g)
	var locmap = locationToLineColMap(code)
	var lc = locmap[loc[0]] or [0,0]
	var ln = lc[0]
	var col = lc[1]
	var line = lines[ln]

	var ln0 = Math.max(0,ln - pad)
	var ln1 = Math.min(ln0 + pad + 1 + pad,lines:length)
	let lni = ln - ln0
	var l = ln0

	var out = while l < ln1
		lines[l++]

	if gutter
		out = out.map do |line,i|
			let prefix =  "{ln0 + i + 1}"
			let str
			while prefix:length < String(ln1):length
				prefix = " {prefix}"
			if i == lni
				str = "   -> {prefix} | {line}"
				str = ansi.f(hl,str) if hl
			else
				str = "      {prefix} | {line}"
				str = ansi.f('gray',str) if hl
			return str

	# if colors isa String
	# 	out[lni] = ansi.f(colors,out[lni])
	# elif colors
	# 	let color = ansi[type] or ansi:red
	# 	out[lni] = color(out[lni])

	let res = out.join('\n')
	return res

export def printWarning code, warn
	let msg = warn:message # b("{yellow('warn: ')}") + yellow(warn:message)
	let excerpt = printExcerpt(code,warn:loc, hl: 'whiteBright', type: 'warn', pad: 1)
	return msg + '\n' + excerpt

export def identifierForPath str
	var hash = sha1.create()
	hash.update(str)
	return hash.hex().slice(0, 8)