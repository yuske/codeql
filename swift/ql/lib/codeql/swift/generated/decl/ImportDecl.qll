// generated by codegen/codegen.py
private import codeql.swift.generated.Synth
private import codeql.swift.generated.Raw
import codeql.swift.elements.decl.Decl
import codeql.swift.elements.decl.ModuleDecl
import codeql.swift.elements.decl.ValueDecl

class ImportDeclBase extends Synth::TImportDecl, Decl {
  override string getAPrimaryQlClass() { result = "ImportDecl" }

  predicate isExported() { Synth::convertImportDeclToRaw(this).(Raw::ImportDecl).isExported() }

  ModuleDecl getImmediateImportedModule() {
    result =
      Synth::convertModuleDeclFromRaw(Synth::convertImportDeclToRaw(this)
            .(Raw::ImportDecl)
            .getImportedModule())
  }

  final ModuleDecl getImportedModule() { result = getImmediateImportedModule().resolve() }

  final predicate hasImportedModule() { exists(getImportedModule()) }

  ValueDecl getImmediateDeclaration(int index) {
    result =
      Synth::convertValueDeclFromRaw(Synth::convertImportDeclToRaw(this)
            .(Raw::ImportDecl)
            .getDeclaration(index))
  }

  final ValueDecl getDeclaration(int index) { result = getImmediateDeclaration(index).resolve() }

  final ValueDecl getADeclaration() { result = getDeclaration(_) }

  final int getNumberOfDeclarations() { result = count(getADeclaration()) }
}
