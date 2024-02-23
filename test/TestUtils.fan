
internal class TestDosUtils : Test {
	
	Void testToFileUri() {
		
		// test drive letters
		verifyEq(toFileUri("c:"			), `/C:/`)
		verifyEq(toFileUri("c:/"		), `/C:/`)
		verifyEq(toFileUri("c:\\"		), `/C:/`)
		verifyEq(toFileUri("/c:"		), `/C:/`)
		verifyEq(toFileUri("/c:/"		), `/C:/`)
		verifyEq(toFileUri("/c:\\"		), `/C:/`)
		verifyEq(toFileUri("\\c:"		), `/C:/`)
		verifyEq(toFileUri("\\c:/"		), `/C:/`)
		verifyEq(toFileUri("\\c:\\"		), `/C:/`)

		// test drive urls are absolute
		verifyEq(toFileUri("c:fred"		), `/C:/fred`)
		verifyEq(toFileUri("c:/fred"	), `/C:/fred`)
		verifyEq(toFileUri("c:\\fred"	), `/C:/fred`)
		verifyEq(toFileUri("/c:fred"	), `/C:/fred`)
		verifyEq(toFileUri("/c:/fred"	), `/C:/fred`)
		verifyEq(toFileUri("/c:\\fred"	), `/C:/fred`)
		verifyEq(toFileUri("\\c:fred"	), `/C:/fred`)
		verifyEq(toFileUri("\\c:/fred"	), `/C:/fred`)
		verifyEq(toFileUri("\\c:\\fred"	), `/C:/fred`)

		// win32 os paths strip off trailing slashes
		verifyEq(toFileUri("\\c:\\fred\\"	), `/C:/fred/`)
		verifyEq(toFileUri("\\c:\\temp\\"	), `/C:/temp/`)
		
		// test rel files
		verifyEq(toFileUri("fred"	), `fred`)
		verifyEq(toFileUri("fred/"	), `fred/`)
		
		// test abs files
		verifyEq(toFileUri("/fred"	), `/fred`)
		verifyEq(toFileUri("/fred/"	), `/fred/`)
		
		// test awkward . and ..
		verifyEq(toFileUri("fred/."		), `fred/.`)
		verifyEq(toFileUri("fred/.."	), `fred/..`)
		verifyEq(toFileUri("fred/.."	), `fred/..`)

		// test \\ agnostic
		verifyEq(toFileUri("fred"		), `fred`)
		verifyEq(toFileUri("fred\\"		), `fred/`)
		verifyEq(toFileUri("\\fred"		), `/fred`)
		verifyEq(toFileUri("\\fred\\"	), `/fred/`)
		verifyEq(toFileUri("fred\\."	), `fred/.`)
		verifyEq(toFileUri("fred\\.."	), `fred/..`)
		
		// special cases
		verifyEq(toFileUri("poo:=8"		), null)
	}
	
	Uri? toFileUri(Str path) {
		DosUtils.toFileUri(path)
	}
}
