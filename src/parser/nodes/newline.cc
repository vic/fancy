#include "../../../vendor/gc/include/gc.h"
#include "../../../vendor/gc/include/gc_cpp.h"
#include "../../../vendor/gc/include/gc_allocator.h"

#include "newline.h"
#include "../../scope.h"
#include "../../bootstrap/core_classes.h"
#include "../../number.h"
#include "../../utils.h"
#include "../../errors.h"

namespace fancy {
  namespace parser {
    namespace nodes {

      NewLine::NewLine(const int line) :
        _line(line)
      {
      }

      FancyObject* NewLine::eval(Scope *scope)
      {
        return scope->current_self();
      }

      string NewLine::to_sexp() const
      {
        return "['line, " + Number::from_int(_line)->to_s() + "], ";
      }
    }
  }
}
