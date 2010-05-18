#include "includes.h"

namespace fancy {

  NativeMethod::NativeMethod(string identifier,
                             FancyObject_p (&func)(FancyObject_p self, FancyObject_p *args, int argc, Scope *scope)) :
    FancyObject(MethodClass), _identifier(identifier), _func(func)
  {
  }

  NativeMethod::NativeMethod(string identifier,
                             string docstring,
                             FancyObject_p (&func)(FancyObject_p self, FancyObject_p *args, int argc, Scope *scope)) :
    FancyObject(MethodClass), _identifier(identifier), _func(func)
  {
    set_docstring(docstring);
  }

  NativeMethod::~NativeMethod()
  {
  }

  FancyObject_p NativeMethod::eval(Scope *scope)
  {
    errorln("calling eval() on NativeMethod .. ");
    return nil;
  }

  FancyObject_p NativeMethod::equal(const FancyObject_p other) const
  {
    if(!IS_NATIVEMETHOD(other)) {
      return nil;
    } else {
      NativeMethod_p other_bif = (NativeMethod_p)other;
      if(_identifier == other_bif->_identifier) {
        return t;
      } else {
        return nil;
      }
    }
  }

  OBJ_TYPE NativeMethod::type() const
  {
    return OBJ_NATIVEMETHOD;
  }

  string NativeMethod::to_s() const
  {
    return "<NativeMethod:'" + _identifier + "' Doc:'" + _docstring + "'>";
  }

  FancyObject_p NativeMethod::call(FancyObject_p self, FancyObject_p *args, int argc, Scope *scope)
  {
    return _func(self, args, argc, scope);
  }

  FancyObject_p NativeMethod::call(FancyObject_p self, Scope *scope)
  {
    return _func(self, 0, 0, scope);
  }

}
