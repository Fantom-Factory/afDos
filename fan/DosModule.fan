using afIoc
using afIocConfig

@NoDoc
const class DosModule {
	
	Void defineServices(RegistryBuilder bob) {
	}
	
	@Build
	DosTerminal buildDosTerminal(ConfigSource config, DosOps dosOps) {
		DosTerminal {
			it.currentDirStackMaxSize	= config.get("afDos.currentDirStackSize", Int#)
			it.zipBufferSize			= config.get("afDos.zipBufferSize", Int#)
			it.fileOps					= dosOps
		}
	}
	
	@Build
	DosOps buildDosOps(ConfigSource config) {
		DosOps {
			// TODO make exeExts a contributable service
			it.exeExts = "bat cmd com exe".split
			it.osRootsCacheTimeout = config.get("afDos.osRootsCacheTimeout", Duration#)
		}
	}

	@Contribute { serviceType=FactoryDefaults# }
	Void contributeFactoryDefaults(Configuration config) {
		config["afDos.currentDirStackSize"] = 25
		config["afDos.osRootsCacheTimeout"] = 2sec
		config["afDos.zipBufferSize"]		= 16*1024
	}
}
