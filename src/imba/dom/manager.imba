var Imba = require("../imba")

class Imba.TagManagerClass
	def initialize
		@tryMounting = no
		@tryUnmounting = no
		@mounted = []
		@mountables = 0
		@unmountables = 0
		@unmounting = 0
		self

	def mounted
		@mounted

	def insert node, parent
		@tryMounting = yes if node and node:mount
		regMountable(node) if node and node:mount
		# unless node.FLAGS & Imba.TAG_MOUNTABLE
		# 	node.FLAGS |= Imba.TAG_MOUNTABLE
		# 	@mountables++
		return

	def remove node, parent
		@tryUnmounting = yes if node and node:mount

	def changes
		@tryMounting or @tryUnmounting

	def mount node
		return

	def refresh force = no
		return if $node$
		return if !force and changes === no
		# console.time('resolveMounts')
		if (@tryMounting and @mountables > @mounted:length) or force
			tryMount

		if (@tryUnmounting or force) and @mounted:length
			tryUnmount
		# console.timeEnd('resolveMounts')

		self

	def unmount node
		self
	
	def regMountable node
		unless node.FLAGS & Imba.TAG_MOUNTABLE
			node.FLAGS |= Imba.TAG_MOUNTABLE
			@mountables++
		

	def tryMount
		@tryMounting = no # Ensure new mount Requests are processed on next refresh
		var count = 0
		var root = document:body
		var items = root.querySelectorAll('.__mount')
		# what if we end up creating additional mountables by mounting?
		for el in items
			if el and el.@tag
				if @mounted.indexOf(el.@tag) == -1
					mountNode(el.@tag)
		return self

	def mountNode node
		if @mounted.indexOf(node) == -1
			regMountable(node)
			@mounted.push(node)
				
			node.FLAGS |= Imba.TAG_MOUNTED
			node.mount if node:mount
			# Mark all parents as mountable for faster unmount
			# let el = node.dom:parentNode
			# while el and el.@tag and !el.@tag:mount and !(el.@tag.FLAGS & Imba.TAG_MOUNTABLE)
			# 	el.@tag.FLAGS |= Imba.TAG_MOUNTABLE
			# 	el = el:parentNode
		return

	def tryUnmount
		@tryUnmounting = no # Ensure new unmount Requests are processed on next refresh
		@unmounting++
		
		var unmount = []
		var root = document:body
		for item, i in @mounted
			continue unless item
			unless document:documentElement.contains(item.@dom)
				unmount.push(item)				
				@mounted[i] = null

		@unmounting--
		
		if unmount:length
			@mounted = @mounted.filter do |item| item and unmount.indexOf(item) == -1
			for item in unmount
				item.FLAGS = item.FLAGS & ~Imba.TAG_MOUNTED
				if item:unmount and item.@dom
					item.unmount
				elif item.@scheduler
					item.unschedule
		self
