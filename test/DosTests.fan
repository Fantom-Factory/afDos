using afIoc::Registry
using afIoc::RegistryBuilder
using afIoc::Scope

class DosTests : Test {

	Registry?	reg
	Scope?		scope
	
	override Void setup() {
		reg = RegistryBuilder() {
			addModule(DosModule#)
			addModulesFromPod("afIocConfig")
			addScope("dos", true)
			bobReg(it) 
		}.build
		scope = reg.activeScope.createChild("dos")
		reg.setActiveScope(scope)
		scope.inject(this)
	}
	
	override Void teardown() {
		reg.shutdown
	}
	
	virtual Void bobReg(RegistryBuilder bob) { }
}
