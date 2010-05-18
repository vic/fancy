#include "includes.h"

namespace fancy {

  String::String(const string &value) :
    FancyObject(StringClass), _value(value)
  {
  }

  String::~String()
  {
  }

  FancyObject_p String::equal(const FancyObject_p other) const
  {
    if(!IS_STRING(other))
      return nil;

    String_p other_string = (String_p)other;
    if(_value == other_string->_value)
      return t;
    return nil;
  }

  OBJ_TYPE String::type() const
  {
    return OBJ_STRING;
  }

  string String::to_s() const
  {
    return _value;
  }

  string String::inspect() const
  {
    return "\"" + _value + "\"";
  }

  string String::value() const
  {
    return _value;
  }

  map<string, String_p> String::value_cache;
  String_p String::from_value(const string &value)
  {
    if(value_cache.find(value) != value_cache.end()) {
      return value_cache[value];
    } else {
      // insert new value into value_cache & return new number value
      String_p new_string = new String(value);
      value_cache[value] = new_string;
      return new_string;
    }
  }

}
