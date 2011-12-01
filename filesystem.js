function EntryEmul()
{
}

function DirectoryReaderEmul()
{
}

function FileEmul()
{
}

function FileEntryEmul()
{
	this.file = ;
}

function DirectoryEntryEmul(path)
{
	this.path = path;
	
	this.createReader: function()
	{
		return new DirectoryReaderEmul();
	};
	
	this.getFile: function(path, options, successCallback, errorCallback)
	{ // DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
		var pathList = this.getPath(path);
		
		var entry = this.findPath(pathList);
		
		if( !entry instanceof FileEntryEmul )
		
		setTimeout(successCallback.handleEvent(entry, 0);
	};
	this.getDirectory: function(path, options, successCallback, errorCallback)
	{ // DOMString, optional Flags, optional EntryCallback, optional ErrorCallback
	
	};
	this.removeRecursively: function(successCallback, errorCallback)
	{ // VoidCallback, optional ErrorCallback
	};
}

function FileSystemEmul()
{
	this.name: "whatever",
	this.root = new DirectoryEntryEmul("/");
}

LocalFileSystemEmul.TEMPORARY  = 0;
LocalFileSystemEmul.PERSISTENT = 1;

function LocalFileSystemEmul()
{
	this.requestFileSystem = function(type, size, successCallback, errorCallback)
	{ //unsigned short, unsigned long long, FileSystemCallback, optional ErrorCallback
		if( !PERSISTENT )
		{ // Not supported
			if( errorCallback )
				setTimeout(errorCallback.handleEvent(), 0);
			return;
		}
		else if( not storage )
		{
			
		}
		
		this.filesystem = new FileSystemEmul();

		setTimeout(successCallback.handleEvent(this.filesystem);, 0);
	}
	return this;
}

// Hook up FileSystem API

window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem;

if( !window.requestFileSystem )
{ // No native support
	var emul = new LocalFileSystemEmul();
	window.requestFileSystem = emul.requestFileSystem;
}

