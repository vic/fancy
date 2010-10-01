%{
  #include "../../vendor/gc/include/gc.h"
  #include "../../vendor/gc/include/gc_cpp.h"
  #include "../../vendor/gc/include/gc_allocator.h"

  #include "includes.h"

  using namespace fancy;
  using namespace parser;
  /* using namespace fancy::parser::nodes; */

  int yyerror(char *s);
  int yylex(void);

  nodes::key_val_node* key_val_obj(Expression* key,
                                   Expression* val,
                                   nodes::key_val_node *next);

  expression_node* expr_node(Expression* expr,
                             expression_node *next);

  nodes::identifier_node* ident_node(Identifier* ident,
                                     nodes::identifier_node *next);

  nodes::block_arg_node* blk_arg_node(nodes::Identifier* argname,
                                      nodes::block_arg_node *next);

  nodes::send_arg_node* msend_arg_node(nodes::Identifier* argname,
                                       Expression* argexpr,
                                       nodes::send_arg_node *next);

  nodes::except_handler_list* except_handler_node(nodes::Identifier* classname,
                                                  nodes::Identifier* localname,
                                                  ExpressionList* body,
                                                  nodes::except_handler_list *next);

  list< pair<nodes::Identifier*, nodes::Identifier*> > method_args;
  list<nodes::Identifier*> block_args;
  list<Expression*> expression_list;
%}

%union{
  fancy::parser::nodes::key_val_node      *key_val_list;
  array_node               *value_list;
  expression_node          *expr_list;
  identifier_node          *ident_list;
  fancy::parser::nodes::block_arg_node    *block_arg_list;
  fancy::parser::nodes::send_arg_node     *send_arg_list;
  fancy::parser::nodes::except_handler_list *except_handler_list;
  /* method_arg_node   *method_args; */

  FancyObject           *object;
  fancy::parser::nodes::Identifier     *identifier;
  Number                *number;
  Regexp                *regexp;
  FancyString           *string;
  Symbol                *symbol;
  Array                 *array;
  Expression            *expression;

  NewLine               *newline;
}

%start	programm

%token                  LPAREN
%token                  RPAREN
%token                  LCURLY
%token                  RCURLY
%token                  LBRACKET
%token                  RBRACKET
%token                  LHASH
%token                  RHASH
%token                  STAB
%token                  ARROW
%token                  COMMA
%token                  SEMI
%token                  NL
%token                  COLON
%token                  RETURN_LOCAL
%token                  RETURN
%token                  REQUIRE
%token                  TRY
%token                  CATCH
%token                  FINALLY
%token                  RETRY
%token                  SUPER
%token                  PRIVATE
%token                  PROTECTED
%token                  DEFCLASS
%token                  DEF
%token                  DOT
%token                  DOLLAR
%token                  EQUALS
%token                  RB_ARGS_PREFIX

%token <number>             INTEGER_LITERAL
%token <number>             DOUBLE_LITERAL
%token <string>             STRING_LITERAL
%token <symbol>             SYMBOL_LITERAL
%token <regexp>             REGEXP_LITERAL
%token <identifier>         IDENTIFIER
%token <identifier>         OPERATOR

%left                   DOT
%right                  DOLLAR

%type  <expression>         literal_value
%type  <expression>         block_literal
%type  <block_arg_list>     block_args
%type  <block_arg_list>     block_args_without_comma
%type  <block_arg_list>     block_args_with_comma
%type  <expression>         hash_literal
%type  <expression>         array_literal
%type  <expression>         empty_array

%type  <key_val_list>       key_value_list
%type  <expr_list>          exp_comma_list
%type  <expr_list>          method_body


%type  <object>             code
%type  <object>             exp
%type  <expression>         assignment
%type  <expression>         multiple_assignment
%type  <ident_list>         identifier_list
%type  <expression>         return_local_statement
%type  <expression>         return_statement
%type  <expression>         require_statement

%type  <expr_list>          class_body
%type  <expression>         class_def
%type  <expression>         class_no_super
%type  <expression>         class_super
%type  <expression>         class_method_w_args
%type  <expression>         class_method_no_args

%type  <expression>         method_def
%type  <expression>         method_w_args
%type  <expression>         method_no_args
%type  <expression>         operator_def
%type  <expression>         class_operator_def

%type  <expression>         message_send
%type  <expression>         operator_send
%type  <send_arg_list>      send_args
%type  <expression>         receiver
%type  <expression>         arg_exp

%type  <expression>         try_catch_block
%type  <except_handler_list> catch_blocks
%type  <expr_list>          finally_block
%type  <expr_list>          catch_block_body

%type  <newline>            nls

%%

programm:       /* empty */
                | code {
                  Expression* expr = $1;
                  if(output_sexp) {
                    (*parser::out_stream) << expr->to_sexp() << ", ";
                  } else {
                    last_value = expr->eval(global_scope);
                  }
                }
                | programm delim code {
                  Expression* expr = $3;
                  if(output_sexp) {
                    (*parser::out_stream) << expr->to_sexp() << ", ";
                  } else {
                    last_value = expr->eval(global_scope);
                  }
                }
                | programm delim { }
                ;

delim:          nls
                | SEMI
                | delim delim
                ;

nls:            NL {
                  $$ = new nodes::NewLine(yylineno);
                  if(output_sexp) {
                    (*parser::out_stream) << $$->to_sexp();
                  }
                }
                | nls NL
                ;

space:          /* */
                | nls
                ;

code:           statement
                | exp
                ;

statement:      assignment
                | return_local_statement
                | return_statement
                | require_statement
                ;

exp:            method_def
                | class_def
                | message_send
                | operator_send
                | try_catch_block
                | literal_value
                | IDENTIFIER
                | LPAREN exp RPAREN { $$ = $2; }
                ;

assignment:     IDENTIFIER EQUALS space exp {
                  $$ = new nodes::AssignmentExpr($1, $4);
                }
                | multiple_assignment
                ;

multiple_assignment: identifier_list EQUALS exp_comma_list {
                  $$ = new nodes::AssignmentExpr($1, $3);
                }
                ;

identifier_list: IDENTIFIER { $$ = ident_node($1, NULL); }
                | identifier_list COMMA IDENTIFIER {
                  $$ = ident_node($3, $1);
                }
                ;

return_local_statement: RETURN_LOCAL exp {
                  $$ = new nodes::ReturnStatement($2, true);
                }
                | RETURN_LOCAL {
                  $$ = new nodes::ReturnStatement(nil, true);
                }
                ;

return_statement: RETURN exp {
                  $$ = new nodes::ReturnStatement($2);
                }
                | RETURN {
                  $$ = new nodes::ReturnStatement(nil);
                }
                ;

require_statement: REQUIRE STRING_LITERAL {
                  $$ = new nodes::RequireStatement($2);
                }
                | REQUIRE IDENTIFIER {
                  $$ = new nodes::RequireStatement($2);
                }
                ;

class_def:      class_no_super
                | class_super
                ;

class_no_super: DEFCLASS IDENTIFIER LCURLY class_body RCURLY {
                  $$ = new nodes::ClassDefExpr($2, new ExpressionList($4));
                }
                ;

class_super:    DEFCLASS IDENTIFIER COLON IDENTIFIER LCURLY class_body RCURLY {
                  $$ = new nodes::ClassDefExpr($4, $2, new ExpressionList($6));
                }
                ;

class_body:     /* empty */ { $$ = expr_node(0, 0); }
                | class_body class_def delim { $$ = expr_node(new nodes::NestedClassDefExpr($2), $1); }
                | class_body method_def delim { $$ = expr_node($2, $1); }
                | class_body code delim { $$ = expr_node($2, $1); }
                | class_body delim { } /* empty expressions */
                ;

method_def:     method_w_args
                | method_no_args
                | class_method_w_args
                | class_method_no_args
                | operator_def
                | class_operator_def
                ;

method_args:    IDENTIFIER COLON IDENTIFIER {
                  method_args.push_back(pair<nodes::Identifier*, nodes::Identifier*>($1, $3));
                }
                | method_args IDENTIFIER COLON IDENTIFIER {
                  method_args.push_back(pair<nodes::Identifier*, nodes::Identifier*>($2, $4));
                }
                ;

method_body:    /* empty */ { $$ = expr_node(0, 0); }
                | code { $$ = expr_node($1, 0); }
                | method_body delim code { $$ = expr_node($3, $1); }
                | method_body delim { } /* empty expressions */
                ;

method_w_args:  DEF method_args LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($5);
                  Method* method = new Method(method_args, body);
                  // TODO: set method_args correctly
                  $$ = new nodes::MethodDefExpr(method_args, method);
                  method_args.clear();
                }
                | DEF PRIVATE method_args LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  Method* method = new Method(method_args, body);
                  // TODO: set method_args correctly
                  $$ = new nodes::PrivateMethodDefExpr(method_args, method);
                  method_args.clear();
                }
                | DEF PROTECTED method_args LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  Method* method = new Method(method_args, body);
                  // TODO: set method_args correctly
                  $$ = new nodes::ProtectedMethodDefExpr(method_args, method);
                  method_args.clear();
                }
                ;


method_no_args: DEF IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($5);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::MethodDefExpr($2, method);
                }
                | DEF PRIVATE IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::PrivateMethodDefExpr($3, method);
                }
                | DEF PROTECTED IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::ProtectedMethodDefExpr($3, method);
                }
                ;

class_method_w_args: DEF IDENTIFIER method_args LCURLY space method_body space RCURLY {
                  // TODO: change for class method specific stuff
                  ExpressionList* body = new ExpressionList($6);
                  Method* method = new Method(method_args, body);
                  // TODO: set method_args correctly
                  $$ = new nodes::ClassMethodDefExpr($2, method_args, method);
                  method_args.clear();
                }
                | DEF PRIVATE IDENTIFIER method_args LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method(method_args, body);
                  $$ = new nodes::PrivateClassMethodDefExpr($3, method_args, method);
                  method_args.clear();
                }
                | DEF PROTECTED IDENTIFIER method_args LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method(method_args, body);
                  $$ = new nodes::ProtectedClassMethodDefExpr($3, method_args, method);
                  method_args.clear();
                }
                ;

class_method_no_args: DEF IDENTIFIER IDENTIFIER LCURLY space method_body space RCURLY {
                  // TODO: change for class method specific stuff
                  ExpressionList* body = new ExpressionList($6);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::ClassMethodDefExpr($2, $3, method);
                }
                | DEF PRIVATE IDENTIFIER IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::PrivateClassMethodDefExpr($3, $4, method);
                }
                | DEF PROTECTED IDENTIFIER IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  list< pair<nodes::Identifier*, nodes::Identifier*> > empty_args;
                  Method* method = new Method(empty_args, body);
                  $$ = new nodes::ProtectedClassMethodDefExpr($3, $4, method);
                }
                ;

operator_def:   DEF OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  Method* method = new Method($2, $3, body);
                  $$ = new nodes::OperatorDefExpr($2, method);
                }
                | DEF PRIVATE OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method($3, $4, body);
                  $$ = new nodes::PrivateOperatorDefExpr($3, method);
                }
                | DEF PROTECTED OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method($3, $4, body);
                  $$ = new nodes::ProtectedOperatorDefExpr($3, method);
                }
                | DEF LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $4, body);
                  $$ = new nodes::OperatorDefExpr(nodes::Identifier::from_string("[]"), method);
                }
                | DEF PRIVATE LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($8);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $5, body);
                  $$ = new nodes::PrivateOperatorDefExpr(nodes::Identifier::from_string("[]"), method);
                }
                | DEF PROTECTED LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($8);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $5, body);
                  $$ = new nodes::ProtectedOperatorDefExpr(nodes::Identifier::from_string("[]"), method);
                }
                ;

class_operator_def: DEF IDENTIFIER OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  Method* method = new Method($3, $4, body);
                  $$ = new nodes::ClassOperatorDefExpr($2, $3, method);
                }
                | DEF PRIVATE IDENTIFIER OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($8);
                  Method* method = new Method($4, $5, body);
                  $$ = new nodes::PrivateClassOperatorDefExpr($3, $4, method);
                }
                | DEF PROTECTED IDENTIFIER OPERATOR IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($8);
                  Method* method = new Method($4, $5, body);
                  $$ = new nodes::ProtectedClassOperatorDefExpr($3, $4, method);
                }
                | DEF IDENTIFIER LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($8);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $5, body);
                  $$ = new nodes::ClassOperatorDefExpr($2, nodes::Identifier::from_string("[]"), method);
                }
                | DEF PRIVATE IDENTIFIER LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($9);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $6, body);
                  $$ = new nodes::PrivateClassOperatorDefExpr($3, nodes::Identifier::from_string("[]"), method);
                }
                | DEF PROTECTED IDENTIFIER LBRACKET RBRACKET IDENTIFIER LCURLY space method_body space RCURLY {
                  ExpressionList* body = new ExpressionList($9);
                  Method* method = new Method(nodes::Identifier::from_string("[]"), $6, body);
                  $$ = new nodes::ProtectedClassOperatorDefExpr($3, nodes::Identifier::from_string("[]"), method);
                }
                ;

message_send:   receiver IDENTIFIER { $$ = new nodes::MessageSend($1, $2); }
                | receiver send_args {
                   $$ = new nodes::MessageSend($1, $2);
                }
                | send_args {
                   $$ = new nodes::MessageSend(nodes::Self::node(), $1);
                }
                ;


operator_send:  receiver OPERATOR arg_exp {
                  $$ = new nodes::OperatorSend($1, $2, $3);
                }
                | receiver OPERATOR DOT space arg_exp {
                  $$ = new nodes::OperatorSend($1, $2, $5);
                }
                | receiver LBRACKET exp RBRACKET {
                  $$ = new nodes::OperatorSend($1, nodes::Identifier::from_string("[]"), $3);
                }
                ;

receiver:       LPAREN space exp space RPAREN { $$ = $3; }
                | exp { $$ = $1; }
                | IDENTIFIER { $$ = $1; }
                | SUPER { $$ = new nodes::Super(); }
                | exp DOT space { $$ = $1; }
                ;

send_args:      IDENTIFIER COLON arg_exp { $$ = msend_arg_node($1, $3, 0); }
                | IDENTIFIER COLON space arg_exp { $$ = msend_arg_node($1, $4, 0); }
                | send_args IDENTIFIER COLON arg_exp { $$ = msend_arg_node($2, $4, $1); }
                | send_args IDENTIFIER COLON space arg_exp { $$ = msend_arg_node($2, $5, $1); }
                ;

arg_exp:        IDENTIFIER { $$ = $1; }
                | LPAREN exp RPAREN { $$ = $2; }
                | literal_value { $$ = $1; }
                | DOLLAR exp { $$ = $2; }
                ;

try_catch_block: TRY LCURLY method_body RCURLY catch_blocks {
                  ExpressionList* body = new ExpressionList($3);
                  $$ = new nodes::TryCatchBlock(body, $5);
                }
                | TRY LCURLY method_body RCURLY catch_blocks finally_block {
                  ExpressionList* body = new ExpressionList($3);
                  ExpressionList* finally = new ExpressionList($6);
                  $$ = new nodes::TryCatchBlock(body, $5, finally);
                }
                ;

catch_blocks:  /* empty */ { $$ = except_handler_node(0,0,0,0); }
                | CATCH LCURLY catch_block_body RCURLY {
                  ExpressionList* body = new ExpressionList($3);
                  $$ = except_handler_node(nodes::Identifier::from_string("Exception"), nodes::Identifier::from_string(""), body, 0);
                }
                | CATCH IDENTIFIER ARROW IDENTIFIER LCURLY catch_block_body RCURLY {
                  ExpressionList* body = new ExpressionList($6);
                  $$ = except_handler_node($2, $4, body, 0);
                }
                | catch_blocks CATCH IDENTIFIER ARROW IDENTIFIER LCURLY catch_block_body RCURLY {
                  ExpressionList* body = new ExpressionList($7);
                  $$ = except_handler_node($3, $5, body, $1);
                }
                ;

catch_block_body: /* empty */ { $$ = expr_node(0, 0); }
                | code { $$ = expr_node($1, 0); }
                | RETRY { $$ = expr_node(new nodes::Retry(), 0); }
                | catch_block_body delim code { $$ = expr_node($3, $1); }
                | catch_block_body delim RETRY { $$ = expr_node(new nodes::Retry(), $1); }
                | catch_block_body delim { } /* empty expressions */
                ;

finally_block:  FINALLY LCURLY method_body RCURLY {
                  $$ = $3;
                }
                ;

literal_value:  INTEGER_LITERAL	{ $$ = $1; }
                | DOUBLE_LITERAL { $$ = $1; }
                | STRING_LITERAL { $$ = $1; }
                | SYMBOL_LITERAL { $$ = $1; }
                | hash_literal { $$ = $1; }
                | array_literal { $$ = $1; }
                | REGEXP_LITERAL { $$ = $1; }
                | block_literal { $$ = $1; }
                ;

array_literal:  empty_array
                | LBRACKET space exp_comma_list space RBRACKET {
                    $$ = new nodes::ArrayLiteral($3);
                }
                | RB_ARGS_PREFIX array_literal {
                  $$ = new nodes::RubyArgsLiteral($2);
                }
                ;

exp_comma_list: exp { $$ = expr_node($1, 0); }
                | exp_comma_list COMMA space exp { $$ = expr_node($4, $1); }
                | exp_comma_list COMMA { }
                ;

empty_array:    LBRACKET space RBRACKET { $$ = new nodes::ArrayLiteral(0); }
                ;

hash_literal:   LHASH space key_value_list space RHASH { $$ = new nodes::HashLiteral($3); }
                | LHASH space RHASH { $$ = new nodes::HashLiteral(0); }
                ;

block_literal:  LCURLY space method_body RCURLY {
                  $$ = new nodes::BlockLiteral(new ExpressionList($3));
                }
                | STAB block_args STAB space LCURLY space method_body space RCURLY {
                  $$ = new nodes::BlockLiteral($2, new ExpressionList($7));
                }
                ;

block_args:     block_args_with_comma
                | block_args_without_comma
                ;

block_args_without_comma: IDENTIFIER { $$ = blk_arg_node($1, 0); }
                | block_args IDENTIFIER { $$ = blk_arg_node($2, $1); }
                ;

block_args_with_comma: IDENTIFIER { $$ = blk_arg_node($1, 0); }
                | block_args COMMA IDENTIFIER { $$ = blk_arg_node($3, $1); }
                ;

key_value_list: SYMBOL_LITERAL space ARROW space exp { $$ = key_val_obj($1, $5, NULL); }
                | SYMBOL_LITERAL space ARROW space literal_value { $$ = key_val_obj($1, $5, NULL); }
                | STRING_LITERAL space ARROW space literal_value { $$ = key_val_obj($1, $5, NULL); }
                | key_value_list COMMA space SYMBOL_LITERAL space ARROW space exp  {
                  $$ = key_val_obj($4, $8, $1);
                }
                | key_value_list COMMA space STRING_LITERAL space ARROW space exp  {
                  $$ = key_val_obj($4, $8, $1);
                }
                | key_value_list COMMA space SYMBOL_LITERAL space ARROW space literal_value {
                  $$ = key_val_obj($4, $8, $1);
                }
                | key_value_list COMMA space SYMBOL_LITERAL space ARROW space literal_value {
                  $$ = key_val_obj($4, $8, $1);
                }
                ;

%%

int yyerror(char *s)
{
  extern int yylineno;
  extern char *yytext;

  string error_msg = "StdError new: (\"ParseError: [\" ++ ";
  error_msg += "\"" + current_file + "\" ++ \":\" ++ ";
  error_msg += Number::from_int(yylineno)->to_s() + " ++ \"]\" ++ ";
  error_msg += " \" at symbol '\" ++ ";
  string str(yytext);
  error_msg += "\"" + str + "\" ++ \"'\"";
  error_msg += ") . raise!";

  parse_string(error_msg, global_scope);
  /* fprintf(stderr, "ERROR [%s:%d] : %s at symbol %s\n", current_file.c_str(), yylineno, s, yytext); */
  exit(1);
}

nodes::key_val_node* key_val_obj(Expression* key, Expression* val, nodes::key_val_node *next)
{
  nodes::key_val_node *node = new nodes::key_val_node;
  node->key = key;
  node->val = val;
  node->next = next;
  return node;
}

expression_node* expr_node(Expression* expr, expression_node *next)
{
  expression_node *node = new expression_node;
  node->expression = expr;
  node->next = next;
  return node;
}

nodes::identifier_node* ident_node(Identifier* ident, nodes::identifier_node* next)
{
  nodes::identifier_node *node = new nodes::identifier_node;
  node->identifier = ident;
  node->next = next;
  return node;
}

nodes::block_arg_node* blk_arg_node(nodes::Identifier* argname, nodes::block_arg_node *next)
{
  nodes::block_arg_node *node = new nodes::block_arg_node;
  node->argname = argname;
  node->next = next;
  return node;
}

nodes::send_arg_node* msend_arg_node(nodes::Identifier* argname, Expression* argexpr, nodes::send_arg_node *next)
{
  nodes::send_arg_node *node = new nodes::send_arg_node;
  node->argname = argname;
  node->argexpr = argexpr;
  node->next = next;
  return node;
}

nodes::except_handler_list*
except_handler_node(nodes::Identifier* classname, nodes::Identifier* localname, ExpressionList* body, nodes::except_handler_list *next)
{
  nodes::except_handler_list *node = new nodes::except_handler_list;
  nodes::ExceptionHandler *handler = new nodes::ExceptionHandler(classname, localname, body);
  node->handler = handler;
  node->next = next;
  return node;
}
