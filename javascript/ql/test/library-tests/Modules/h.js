function f() {
	return 42;
}

exports = f;  // Not exported, only available in the module, 
              // see https://nodejs.org/api/modules.html#modules_exports_shortcut