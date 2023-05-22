// generated by codegen/codegen.py
private import codeql.swift.generated.Synth
private import codeql.swift.generated.Raw
import codeql.swift.elements.stmt.BraceStmt
import codeql.swift.elements.stmt.Stmt

module Generated {
  class DeferStmt extends Synth::TDeferStmt, Stmt {
    override string getAPrimaryQlClass() { result = "DeferStmt" }

    /**
     * Gets the body of this defer statement.
     *
     * This includes nodes from the "hidden" AST. It can be overridden in subclasses to change the
     * behavior of both the `Immediate` and non-`Immediate` versions.
     */
    BraceStmt getImmediateBody() {
      result =
        Synth::convertBraceStmtFromRaw(Synth::convertDeferStmtToRaw(this).(Raw::DeferStmt).getBody())
    }

    /**
     * Gets the body of this defer statement.
     */
    final BraceStmt getBody() { result = this.getImmediateBody().resolve() }
  }
}
