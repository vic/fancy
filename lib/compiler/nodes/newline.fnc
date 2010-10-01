def class AST {
  def class NewLine : Node {
    """
    Represents newlines in Fancy.
    """

    read_slots: ['line]
    def initialize: line {
      @line = line
    }

    def NewLine from_sexp: sexp {
      NewLine new: $ sexp second
    }

    def to_ruby_sexp: out {
      out print: $ "[:line, " ++ line ++ "]"
    }

    def to_ruby: out indent: ilvl {
      out print: "\n"
    }
  }
}
