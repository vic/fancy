#include "includes.h"

namespace fancy {

  Regex::Regex(const string &pattern) : FancyObject(RegexClass), _pattern(pattern)
  {
  }

  Regex::~Regex()
  {
  }

  FancyObject_p Regex::equal(const FancyObject_p other) const
  {
    if(!IS_REGEX(other))
      return nil;
  
    Regex_p other_regex = (Regex_p)other;
    if(_pattern == other_regex->_pattern)
      return t;
    return nil;
  }

  OBJ_TYPE Regex::type() const
  {
    return OBJ_REGEX;
  }

  string Regex::to_s() const
  {
    return "/" + _pattern + "/";
  }

  string Regex::pattern() const
  {
    return _pattern;
  }

  FancyObject_p Regex::match(String_p string) const
  {
    // if match -> return t else nil
    // TODO: implement Regex matching! (via boost::regex?)
    return nil;
  }

}
