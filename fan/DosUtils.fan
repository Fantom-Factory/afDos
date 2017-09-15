
internal class DosUtils {

	static Uri? toFileUri(Str path) {
		dot := false
		if (path.endsWith("/.") || path.endsWith("\\.")) {
			dot = true
			path = path[0..<-2]
		}
		
		uri := Uri.fromStr(path, false)
		if (uri == null) return null

		try
			if (!path.startsWith("file:") && (path.containsChar('\\') || path.containsChar(':')))
				uri = File.os(path).uri
		// sys::IOErr: Must use trailing slash for dir: ..
		catch (IOErr err) { /* meh */ }
		// sys::ParseErr: Invalid Uri: '//:c'
		catch (ParseErr err) { /* meh */ }

		if (dot)
			uri = uri.plus(``.plusName("."))
	
		if (uri.scheme != null && uri.scheme != "file")
			return null

		// paths such as `d:` or `/c:` aren't handled correctly, so do it manually
		if (path.size == 2 && path[0].isAlpha && path[1] == ':')
			uri = File(`/${path}/`).normalize.uri
		else 
		if (path.size == 3 && path[0] == '/' && path[1].isAlpha && path[2] == ':')
			uri = File(`${path}/`).normalize.uri

		// Windows strips off trailing slashes for dirs
		if (!uri.isDir && (path.getSafe(-1) == '/' || path.getSafe(-1) == '\\'))
			uri = uri.plusSlash
		return uri
	}
}
