`"use strict";`
# Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem
window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder

if not window.requestFileSystem
	# No native support
	
	class jsFileException extends Error
		@base_exception: undefined
		
		constructor: (code, secondary) ->
			if secondary instanceof String
				super @msg
			else if secondary instanceof Error
				@base_exception = secondary
				super ''
			else
				super ''
			
			@code = code
		
		valueOf: () ->
			@code
	
	callEventLiberal = (fnct, arg) ->
		if fnct.handleEvent is undefined
			call = () ->
				fnct arg
		else
			call = () ->
				fnct.handleEvent arg
		call()
	
	callLaterOn = (func) ->
		setTimeout func, 0
	
	defStaticReadonly = (clazz, name, value) ->
		Object.defineProperty clazz.prototype, name, { value: value }
		
	defStaticReadonly jsFileException, 'NOT_FOUND_ERR'              ,  1
	defStaticReadonly jsFileException, 'SECURITY_ERR'               ,  2
	defStaticReadonly jsFileException, 'ABORT_ERR'                  ,  3
	defStaticReadonly jsFileException, 'NOT_READABLE_ERR'           ,  4
	defStaticReadonly jsFileException, 'ENCODING_ERR'               ,  5
	defStaticReadonly jsFileException, 'NO_MODIFICATION_ALLOWED_ERR',  6
	defStaticReadonly jsFileException, 'INVALID_STATE_ERR'          ,  7
	defStaticReadonly jsFileException, 'SYNTAX_ERR'                 ,  8
	defStaticReadonly jsFileException, 'QUOTA_EXCEEDED_ERR'         , 10
	
	# Check whether there is already a FileError available from
	# FileWriter
	class FileError extends jsFileException
		constructor: (code, secondary) ->
			super code, secondary
	
	if not window.FileError
		window.FileError = FileError
	
	defErrorCode = (name, value) ->
		if not window.FileError[name]
			Object.defineProperty window.FileError, name, { value: value }
	
	defErrorCode 'NOT_FOUND_ERR'              ,  1
	defErrorCode 'SECURITY_ERR'               ,  2
	defErrorCode 'ABORT_ERR'                  ,  3
	defErrorCode 'NOT_READABLE_ERR'           ,  4
	defErrorCode 'ENCODING_ERR'               ,  5
	defErrorCode 'NO_MODIFICATION_ALLOWED_ERR',  6
	defErrorCode 'INVALID_STATE_ERR'          ,  7
	defErrorCode 'SYNTAX_ERR'                 ,  8
	defErrorCode 'INVALID_MODIFICATION_ERR'   ,  9
	defErrorCode 'QUOTA_EXCEEDED_ERR'         , 10
	defErrorCode 'TYPE_MISMATCH_ERR'          , 11
	defErrorCode 'PATH_EXISTS_ERR'            , 12
	
	createFileError = (code, second) ->
		new FileError code, second
	
	class jsRequest
	
	class jsDataStorage
		#DSRequestEmul
		@put   : undefined
		#DSRequestEmul
		@get   : undefined
		@clear : undefined
		@remove: undefined

	class jsLocalDataStorage extends jsDataStorage
		constructor: (localStorage) ->
			super
			@storage = localStorage
		
		pathToKey: (path) ->
			path

		#DSRequestEmul
		get: (path) ->
			data = @storage.getItem pathToKey path
			JSON.parse data
		
		#DSRequestEmul
		put: (path, data) ->
			@storage.setItem pathToKey path, data
		
		clear: () ->
			@storage.clear

		remove: (path) ->
			@storage.removeItem pathToKey path
	
	class jsDatabaseRequest
		constructor: (dbrequest) ->
			@dbrequest = dbrequest
			Object.defineProperty this, 'readyState', { get: () -> @dbrequest.readyState }
			Object.defineProperty this, 'LOADING'   , { value: @dbrequest.LOADING }
			Object.defineProperty this, 'DONE'      , { value: @dbrequest.DONE    }
		
		@onsuccess: undefined
		@onerror  : undefined
	
	class jsDatabaseDataStorage extends jsDataStorage
		constructor: (database) ->
			@objectStore = database.createObjectStore "FileSystem"
			super
		
		pathToKey: (path) ->
			path
		
		#DSRequestEmul
		put: (path, data) ->
			new jsDatabaseRequest @objectStore.put data, pathToKey path

		#DSRequestEmul
		get: (path, data) ->
			new jsDatabaseRequest @objectStore.get pathToKey path

		clear: () ->
			new jsDatabaseRequest @objectStore.clear

		remove: (path) ->
			new jsDatabaseRequest @objectStore.delete pathToKey path
	
	class jsMetadata
		constructor: () ->
			@_modificationTime = new Date()
			Object.defineProperty this, "modificationTime", { get: -> @_modificationTime }
	
	callInvalidNameError = (errorCallback) ->
		callEventLiberal errorCallback, createFileError window.FileError.SYNTAX_ERR, "Wrong characters in name"
	
	charRegex = `/[/\\]+|\u0000/`
	# According to spec
	#charRegex = new RegExp '([/\\<>:?*\"|]+|\\.$| $)'
		
	validateName = (name) ->
		if not name
			return
		#if not charRegex.test name
		result = charRegex.test name
		if not result
			return
		
		throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Name contains invalid characters."
	


	# Following the valid type flags
	FILE_ENTRY      = 1
	DIRECTORY_ENTRY = 2
	SEPERATOR = '/'

	class jsBase
		callAsync: (func, successCallback, errorCallback) ->
			func = func.bind this
			
			callLaterOn ->
				result
				try
					result = func()
				catch e
					# Just catch our FileExceptions	
					if e.code
						callEventLiberal errorCallback, e
						return
					throw e
		
				callEventLiberal successCallback, result
	
	class jsEntry extends jsBase
		constructor: (parent, name, typeFlag) ->
			@_byteCount = 0
			if parent.reserveBytes
				filesystem = parent
				# According to spec this indicates the root
				parent     = this
			else
				filesystem = parent.filesystem
			@_parent = parent
			@_name   = name
			Object.defineProperty this, "parent"    , { get: -> @_parent }
			Object.defineProperty this, "filesystem", { value : filesystem }
			Object.defineProperty this, "name"      , { get: -> @_name }
			
			#TODO: Move isRoot handling off - it's ugly design
			isRoot = @parent is this
			if isRoot
				fullpath = SEPERATOR
			else if parent.name is ''
				fullpath = parent.fullPath
			else
				fullpath = parent.fullPath + SEPERATOR
			
			fullpath += @name
			
			Object.defineProperty this, "fullPath", { value : fullpath }
			
			Object.defineProperty this, "isFile"     , { value : typeFlag is FILE_ENTRY }
			Object.defineProperty this, "isDirectory", { value : typeFlag is DIRECTORY_ENTRY }
			
			@_metadata = new jsMetadata()
			
			filesystem.reserveBytes this
			
			if not isRoot
				@parent.children.push this
			
			@copyTo      = @_copyToAsync
			@getParent   = @_getParentAsync
			@getMetadata = @_getMetadataAsync
			@moveTo      = @_moveToAsync
			@remove      = @_removeAsync
			
		
		clone: (entry) ->
			entry._metadata =  @_metadata
		
		@findEntry: (currentEntry, list) ->
			
			for list_entry in list
				
				if list_entry is '..'
					currentEntry = currentEntry.parent
				else
					currentEntry = currentEntry.getChildren list_entry
				
				if currentEntry is null
					return null
			currentEntry
		
		validateRemoved = (object, message) ->
			if object.parent
				return
			
			message = message || "Entry was removed."
			throw createFileError window.FileError.NOT_FOUND_ERR, message
		
		_getMetadataSync: ->
			validateRemoved this
			@_metadata
		
		# MetadataCallback, optional ErrorCallback
		_getMetadataAsync: (successCallback, errorCallback) ->
			if not successCallback
				throw new Error "getMetadata needs a successCallback argument."
			func = ->
				@_getMetadataSync()
			@callAsync func, successCallback, errorCallback
		
		@_isParent: (parent, testEntry) ->
			result = false
			parentEntry = parent
			testParent = () ->
				testEntry = testEntry.parent
				if testEntry is parentEntry
					result = true
					parentEntry = parentEntry.parent
				else
					parentEntry = parent
			
			testParent() while not(testEntry.filesystem.root is testEntry)
			result and parentEntry is testEntry.filesystem.root
		
		_moveToSync: (newParent, newName) ->
			validateRemoved this
			validateRemoved newParent, "New parent was removed."
			validateName newName
				
			newName = newName || @name
			
			if @parent is newParent and @name is newName
				throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot move entry on itself."
			
			if jsEntry._isParent this, newParent
				throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot move entry on children."
				
			newEntry = jsEntry.findEntry newParent, [ newName ]
			
			if newEntry
				if @isFile is newEntry.isDirectory
					throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot replace directory by file."
				if @isDirectory and newEntry.isFile
					throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot replace file by directory."
				if newEntry.isDirectory and not(newEntry.children.length is 0)
					throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot replace directory containing children."
				
				newEntry._deleteFromParent()
			
			@_deleteFromParent()
			@_parent = newParent
			@_name   = newName
			@parent.children.push this
			this
		
		_copyToSync: (newParent, newName) ->
			validateRemoved this
			validateRemoved newParent, "New parent was removed."
			validateName newName
			
			newName = newName || @name
			
			if @parent is newParent and @name is newName
				throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot copy Entry on itself."
			
			if jsEntry._isParent this, newParent
				throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Cannot copy Entry on children."
			
			newEntry = jsEntry.findEntry newParent, [ newName ]
			
			if newEntry
				err = window.FileError.INVALID_MODIFICATION_ERR
				if @isFile is newEntry.isDirectory
					throw createFileError err, "Cannot copy directory onto file."
				if @isDirectory and newEntry.isFile
					throw createFileError err, "Cannot copy file onto directory."
				if newEntry.isDirectory and not(newEntry.children.length is 0)
					throw createFileError err, "Cannot replace directory containing children."
				
				newEntry._deleteFromParent()
			
			@clone newParent, newName
			
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		_moveToAsync: (parent, newName, successCallback, errorCallback) ->
			func = ->
				@_moveToSync parent, newName
			@callAsync func, successCallback, errorCallback
		
		# DirectoryEntry, optional DOMString, optional EntryCallback, optional ErrorCallback
		_copyToAsync: (parent, newName, successCallback, errorCallback) ->
			func = ->
				@_copyToSync parent, newName
			@callAsync func, successCallback, errorCallback
		
		toURL: (mimeType) ->
			result = "filesystem:file:///"
			
			switch @filesystem._type
				when window.PERSISTENT
					result += "persistent"
				when window.TEMPORARY
					result += "temporary"
			result += @fullPath
		
		_deleteFromParent: ->
			if not @parent
				return # Seems like is was already unparented
			index = @parent.children.indexOf this
			@parent.children.splice index, 1
			@_parent = null
		
		_removeSync: ->
			@_deleteFromParent()
		
		# VoidCallback, optional ErrorCallback
		_removeAsync: (successCallback, errorCallback) ->
			if not successCallback
				throw new Error "remove needs a successCallback argument"
			
			func = ->
				@_removeSync()
			@callAsync func, successCallback, errorCallback
		
		_getParentSync: ->
			@parent
		
		# EntryCallback, optional ErrorCallback
		_getParentAsync: (successCallback, errorCallback) ->
			func = ->
				@_getParentSync()
			@callAsync func, successCallback, errorCallback
	
	class jsFile
		constructor: (@_entry, @_blobBuilder) ->
			@_blob = @_blobBuilder.getBlob()
			Object.defineProperty this, "name", { get: -> @_entry.name }
			Object.defineProperty this, "lastModifiedDate", { get: -> @_entry.lastModifiedDate }
			Object.defineProperty this, "size", { get: -> @_blob.size }
			Object.defineProperty this, "type", { value: "text/plain" }
			
		slice: (start, end, contentType) ->
			@_blob.slice start, end, contentType
		
	class jsFileSaver
		defStaticReadonly jsFileSaver, 'WRITE_START', 'FileSaverWriteStart'
		defStaticReadonly jsFileSaver, 'PROGRESS'   , 'FileSaverProgress'
		defStaticReadonly jsFileSaver, 'WRITE'      , 'FileSaverWrite'
		defStaticReadonly jsFileSaver, 'ABORT'      , 'FileSaverAbort'
		defStaticReadonly jsFileSaver, 'ERROR'      , 'FileSaverError'
		defStaticReadonly jsFileSaver, 'WRITE_END'  , 'FileSaverWriteEnd'
	
		defStaticReadonly jsFileSaver, 'INIT'   , 0
		defStaticReadonly jsFileSaver, 'WRITING', 1
		defStaticReadonly jsFileSaver, 'DONE'   , 2
		
		registerFunctions: (fileReader) ->
			fileReader.onabort = (event) ->
				if @onabort
					@onabort event
			
			fileReader.onloadstart = (event) ->
				if @onwritestart
					@onwritestart event
			
			fileReader.onprogress = (event) ->
				if @onprogress
					@onprogress event
			
			fileReader.onload = (event) ->
				@onload event
				if @onwrite
					@onwrite event
			
			fileReader.onabort = (event) ->
				if @onabort
					@onabort event
			
			fileReader.onerror = (event) ->
				if @onerror
					@onerror event
			
			fileReader.onloadend = (event) ->
				if @onwriteend
					@onwriteend event
		
		dispatch: (eventName) ->
			# If your browser does not support CustomEvent I don't like you!
			event = document.createEvent 'CustomEvent'
			event.initCustomEvent eventName, true, true, null
			document.dispatchEvent event
		
		@reader = new FileReader
		@_readyState = jsFileSaver.prototype.INIT
		@_error =      null
		
		constructor: () ->
			registerFunctions @reader
			
			fnct = () ->
				if @onwritestart
					@onwritestart
			document.addEventListener WRITE_START, fnct, false
			
			fnct = () ->
				if @onprogress
					@onprogress
			document.addEventListener PROGRESS   , fnct, false
			
			fnct = () ->
				if @onwrite
					@onwrite
			document.addEventListener WRITE      , fnct, false
			
			fnct = () ->
				if @onabort
					@onabort
			document.addEventListener ABORT      , fnct, false
			
			fnct = () ->
				if @onerror
					@onerror
			document.addEventListener ERROR      , fnct, false
			
			fnct = () ->
				if @onwriteend
					@onwriteend
			document.addEventListener WRITE_END  , fnct, false
			
			Object.defineProperty this, 'readyState', { get: -> @_readyState }
			Object.defineProperty this, 'error'     , { get: -> @_error      }
		
		setError = (error) ->
			#only enable error setting here
			@_error = error
		
		setReadyState = (state) ->
			@_readyState = state
		
		abort: () ->
			@reader.abort
		
		@onwritestart: null
		@onprogress:   null
		@onwrite:      null
		@onabort:      null
		@onerror:      null
		@onwriteend:   null
	
	class jsFileWriter extends jsFileSaver
		defStaticReadonly jsFileWriter, 'DO_WRITE', 'FileWriterDoWrite'
		
		@_data     = null
		@_position = -1
		@_length   =  0
		
		setLength = (length) ->
				@_length = length
		
		constructor: () ->
			super
			
			fnct = () ->
				if size is not @length
					# Needs to do something
					if size < @length
						@_data = @_data.subarray 0, size
					else
						@_data = new Uint8Array @_data, 0, size
					
					setLength size
				
				@readyState = DONE
				dispatch WRITE
				dispatch WRITE_END
			document.addEventListener DO_WRITE, fnct, false
			
			defineProperty this, 'length'  , { get: -> @_length   }
			defineProperty this, 'position', { get: -> @_position }
			
		add = (arraybuffer) ->
			if @_data
				oldData = @_data;
				@_length = oldData.byteLength + arraybuffer.byteLength
				@_data = new Uint8Array @length
			
				# Copy old data
				@_data.set oldData
				@_data.set arraybuffer, @position
				@_position += arraybuffer.byteLength
			else
				@_length arraybuffer.byteLength
				@_data = arraybuffer
				@_position = arraybuffer.byteLength
		
		handleError = (fileError) ->
			setError fileError
			@_readyState = DONE
			
			dispatch ERROR
			dispatch WRITE_END
		
		#Blob 
		write: (data) -> #raises (FileException)
			if @readyState is WRITING
				throw new FileException FileException.INVALID_STATE_ERR
			
			@_readyState = WRITING
			
			dispatch WRITE_START
			@reader.onload = () ->
				add @reader.result
				@_readyState = DONE
				dispatch WRITE
				dispatch WRITE_END
			
			@reader.onprogress = (progressEvent) ->
				# TODO: see whether this is benefitial
				# Make progress notifications. On getting, while processing the write method, the length and position attributes should indicate the progress made in writing the file as of the last progress notification
			
			@reader.onerror = () ->
				handleError createFileError window.FileError.ABORT_ERR, @reader.error
				
				# TODO: Not yet implemented:
				# On getting, the length and position attributes should indicate any fractional data successfully written to the file.
			
			@reader.readAsArrayBuffer data
		
		seek: (offset) -> #raises (FileException)
			if @readyState is WRITING
				throw new jsFileException jsFileException.INVALID_STATE_ERR
			
			if offset > @length
				offset = @length
			else if offset < 0 # Limit to file index
				offset += @length # Negative is from other end
				offset = Math.min offset, 0
			
			@_position = offset
		
		truncate: (size) -> #raises (FileException)
			
			# Since in the spec there is no shortcut for length == size
			# we won't implement one
			#if size is @_data.length
				
			if @readyState is WRITING
				throw new jsFileException jsFileException.INVALID_STATE_ERR
			
			@_readyState = WRITING
			
			dispatch WRITE_START
			
			dispatch DO_WRITE
	
	class jsFileEntry extends jsEntry
		constructor: (parent, name) ->
			super parent, name, FILE_ENTRY
			@file         = @_fileAsync
			@createWriter = @_createWriterAsync
		
		clone: (parent, name) ->
			entry = new jsFileEntry parent, name
			super entry
			entry
		
		_createWriterSync: ->
			new FileWriter this
		
		# FileWriterCallback, optional ErrorCallback
		_createWriterAsync: (successCallback, errorCallback) ->
			func = ->
				@createWriterSync
			@callAsync func, successCallback, errorCallback
		
		_fileSync: ->
			builder = new window.BlobBuilder
			new jsFile this, builder
		
		# FileCallback, optional ErrorCallback
		_fileAsync: (successCallback, errorCallback) ->
			func = ->
				@_fileSync()
			@callAsync func, successCallback, errorCallback
		
	createNoParentError = ->
		createFileError window.FileError.NOT_FOUND_ERR, "Parent directory does not exist."
		
	createExclusiveError = ->
		createFileError window.FileError.INVALID_MODIFICATION_ERR, "File already exists."

	class jsDirectoryEntry extends jsEntry
		constructor: (parent, name) ->
			@children = []
			super parent, name, DIRECTORY_ENTRY
			@getDirectory      = @_getDirectoryAsync
			@getFile           = @_getFileAsync
			@removeRecursively = @_removeRecursivelyAsync
		
		_cloneChildrenRecursively: (clonedEntry) ->
			for child in @children
				clonedEntry.children.push child.clone clonedEntry, child.name
			
		
		clone: (parent, name) ->
			entry = new jsDirectoryEntry parent, name
			super entry
			this._cloneChildrenRecursively entry
			entry
		
		slashReplaceRegex = `/[/]\.[/]/`           # -> /
		deleteRegex       = `/^\.[/]|^\.$|[/]\.$/` # -> 
		foldPath: (path) ->
			path = path.replace slashReplaceRegex, SEPERATOR
			path = path.replace deleteRegex, ''
			path
		
		getChildren: (name_entry) ->
			for child in this.children
				if child.name is name_entry
					return child
			null
		
		createReader: () ->
			return new jsDirectoryReader this
		
		_getEntry: (path, createCallback, options) ->
			options = options || {} #Make sure we always have options
			
			path = @foldPath path
			path = path.split SEPERATOR
				
			if path[0] is ''
				path.splice 0, 1
				currentEntry = @filesystem.root
			else
				currentEntry = this
				
			for subpath in path
				validateName subpath
				
			entry = jsDirectoryEntry.findEntry currentEntry, path
			
			if entry 
				if options.create and options.exclusive
					throw createExclusiveError()
			else
				if not options.create
					throw createFileError window.FileError.NOT_FOUND_ERR, "Directory does not exist."
				
				name = path.pop()
				parentEntry = jsDirectoryEntry.findEntry currentEntry, path
				
				if parentEntry
					entry = createCallback parentEntry, name
				else
					throw createNoParentError()
			
			if entry is entry.filesystem.root
				throw createFileError window.FileError.SECURITY_ERR, "Access to root not allowed"
			
			entry
		
		createFileFunc = (parent, name) ->
				new jsFileEntry parent, name
		
		_getFileSync: (path, options) ->
			entry = @_getEntry path, createFileFunc, options
			
			if not entry.isFile
				code = window.FileError.TYPE_MISMATCH_ERR
				message = "Trying to get directory as a file"
				throw createFileError code, message
			entry
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		_getFileAsync: (path, options, successCallback, errorCallback) ->
			if not path
				throw new Error "getFile needs path argument"
			func = ->
				@_getFileSync path, options
			@callAsync func, successCallback, errorCallback
		
		createDirectoryFunc = (parent, name) ->
			new jsDirectoryEntry parent, name
		
		_getDirectorySync: (path, options) ->
			entry = @_getEntry path, createDirectoryFunc, options
			
			if not entry.isDirectory
				code = window.FileError.TYPE_MISMATCH_ERR
				message = "Trying to get file as directory"
				throw createFileError code, message
			entry
		
		# DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		_getDirectoryAsync: (path, options, successCallback, errorCallback) ->
			if not path
				throw new Error "getDirectory needs path argument"
			func = ->
				@_getDirectorySync path, options
			@callAsync func, successCallback, errorCallback
		
		_removeSync: ->
			# According to spec removing with children is not allowed
			if @children.length is 0
				super
				return
			throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Removing directory containing children not allowed."
		
		_removeRecursivelySync: ->
			@children.length = 0
			@_removeSync()
		
		# VoidCallback, optional ErrorCallback
		_removeRecursivelyAsync: (successCallback, errorCallback) ->
			func = ->
				@_removeRecursivelySync()
			@callAsync func, successCallback, errorCallback
			
	class jsRootDirectoryEntry extends jsDirectoryEntry
		constructor: (filesystem, path, name) ->
			super filesystem, name
			@_removeRecursivelySync = @_removeSync
		
		_removeSync: (successCallback, errorCallback) ->
			throw createFileError window.FileError.INVALID_MODIFICATION_ERR, "Removing root directory not allowed."
		
	class jsDirectoryReader extends jsBase
		constructor: (dirEntry) ->
			Object.defineProperty this, "dirEntry", {value : dirEntry }
			@readEntries = @_readEntriesAsync
		
		@_allRead: false
		
		_readEntriesSync: ->
			if @_allRead
				return []
			else
				@_allRead = true;
				# Return copy so we can be sure that children are not modified
				# by invoker
				return @dirEntry.children.slice 0
		
		# EntriesCallback, optional ErrorCallback 
		_readEntriesAsync: (successCallback, errorCallback) ->
			func = ->
				@_readEntriesSync()
			@callAsync func, successCallback, errorCallback

	class jsFileSystem
		@_maxByteCount   = 0
		@_availByteCount = 0
		@_usedByteCount  = 0
		
		constructor: (type, byte_count, dataStorage) ->
			@_type = type
			@_maxByteCount = byte_count
			@_availByteCount = @_maxByteCount
			
			Object.defineProperty this, "name", { value : "whatever" }
			
			rootEntry = new jsRootDirectoryEntry this, "/", ''
			Object.defineProperty this, 'root', { get: -> rootEntry }
			
		reserveBytes: (byteCount) ->
			
			if not byteCount instanceof Number
				# Assume this is an Entry
				byteCount = byteCount._byteCount
			
			if (@_usedByteCount + byteCount) > @_maxByteCount
				return false
			
			@_usedByteCount += byteCount
			@_availByteCount -= byteCount
			return true

	window.TEMPORARY  = 0
	window.PERSISTENT = 1
	
	class jsLocalFileSystem
		constructor: () ->
		filesystems = []
		
		createFilesystem = (type, size, dataStorage) ->
			fs = new jsFileSystem type, size, dataStorage
			filesystems.push fs
			fs
		
		# unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		@requestFileSystem: (type, size, successCallback, errorCallback) ->
			if not (type is PERSISTENT or type is TEMPORARY)
				throw new Error "Wrong type. <" + type + "> is not supported."
			if not size
				throw new Error "requestFileSystem needs size argument."
			if not successCallback
				throw new Error "requestFileSystem needs successCallback argument."
			if window.indexedDB
				request = window.indexedDB.open "filesystem.js_"
				request.onsuccess = ->
					fs = createFilesystem type, size, new jsDatabaseDataStorage request.result
					callEventLiberal successCallback, fs
				
				request.onerror = ->
					error = createFileError window.FileError.ABORT_ERR, ""
					callEventLiberal errorCallback, error
				
			else if window.localStorage
				callLaterOn ->
					fs = createFilesystem type, size, new jsLocalDataStorage window.localStorage
					callEventLiberal successCallback, fs
			else
				callLaterOn ->
					error = createFileError window.FileError.ABORT_ERR, "IndexedDB and localStorage are not supported."
					callEventLiberal errorCallback, error
		
		urlRegex = `/^filesystem:file:///(persistent|temporary)//`
		@resolveLocalFileSystemURL: (url, successCallback, errorCallback) ->
			if url is null or url is undefined
				throw new Error "resolveLocalFileSystemURL needs a url argument."
			if successCallback is null or successCallback is undefined
				return # Handle like Chrome. Should rather throw an exception.
				#throw new Error "resolveLocalFileSystemURL needs a successCallback argument."
			
			callLaterOn ->
				if not urlRegex.test url
					callLaterOn ->
						error = createFileError window.FileError.SYNTAX_ERR, "Could not interpret url."
						callEventLiberal errorCallback, error
					return
				
				array = url.split ":///", 3
				
				type = window.PERSISTENT
				size = 100 # need function to get last size
				successFunc = (filesystem) ->
					try
						entry = filesystem.root.getEntry path
						callEventLiberal successCallback, entry
					catch e
						callEventLiberal errorCallback, e
				# There is no sync version of this since indexedDB cannot be accessed synced
				# So we have to wait for second later execution
				jsLocalFileSystemSync.requestFileSystem type, size, successFunc, errorCallback
		

	window.requestFileSystem = jsLocalFileSystem.requestFileSystem
	window.resolveLocalFileSystemURL = jsLocalFileSystem.resolveLocalFileSystemURL
	window.useFileSystemEmulation = true

