module Fancy
  module Parser

    module Node
      def line
        0
      end
    end

    module Identifier
      include Node

      def ast
        Fancy::AST::Identifier.new(line, text)
      end
    end

  end
end
