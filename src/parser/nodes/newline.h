#ifndef _PARSER_NODES_NEWLINE_H
#define _PARSER_NODES_NEWLINE_H

#include "../../expression.h"

namespace fancy {
  namespace parser {
    namespace nodes {

      class NewLine : public Expression
      {
      public:
        static NewLine* node();
        static void init();
        NewLine(int line);
        ~NewLine() {}
        virtual string to_sexp() const;

      private:
        virtual FancyObject* eval(Scope *scope);
        virtual EXP_TYPE type() const { return EXP_NEWLINE; }
        int _line;
      };

    }
  }
}


#endif /* _PARSER_NODES_NEWLINE_H_ */
