
@NoDoc
class DosUtils {

	static Uri? toFileUri(Str path) {
		if (Env.cur.os == "win32") {
			// handle drive letters
			// note that we ignore drive relative paths such as C:Temp and instead convert them to 
			// absolute paths such as C:\Temp\  That's because we don't keep a current dir for each drive.
			if (path.getSafe(0).isAlpha && path.getSafe(1) == ':') {
				if (path.getSafe(2) != '/' && path.getSafe(2) != '\\')
					path = StrBuf().add(path).insert(2, "/").toStr
				uri := File.os("/${path}").normalize.uri.pathOnly		// pathOnly to drop the file: scheme
				// windows drops the trailing slash
				if (path[-1] == '/' || path[-1] == '\\')
					uri = uri.plusSlash
				return uri
			}

			if (path.getSafe(0) == '/' || path.getSafe(0) == '\\')
				if (path.getSafe(1).isAlpha && path.getSafe(2) == ':') {
					if (path.getSafe(3) != '/' && path.getSafe(3) != '\\')
						path = StrBuf().add(path).insert(3, "/").toStr
					uri := File.os("/${path}").normalize.uri.pathOnly	// pathOnly to drop the file: scheme
					// windows drops the trailing slash
					if (path[-1] == '/' || path[-1] == '\\')
						uri = uri.plusSlash
					return uri
				}
		}
		
		// let's not beat about the bush - just fcking do it!
		path = path.replace("\\", "/")

		uri	:= Uri.fromStr(path, false)
		if (uri == null) return null
		if (uri.scheme != null)
			return uri.scheme == "file" ? uri.pathOnly : null
		return uri

//		// file normalisation not needed ... ?
//		file := File.make(uri, false)
//		return file.uri.pathOnly
	}
}
