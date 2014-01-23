/* Copyright (C) 2001 by Marc Feeley, All Rights Reserved. */

/* Converted to the D programming language (dlang) by Aziz Köksal (C) 2014
 * From:
 http://www.iro.umontreal.ca/~felipe/IFT2030-Automne2002/Complements/tinyc.c */

/*
 * This is a compiler for the Tiny-C language.  Tiny-C is a
 * considerably stripped down version of C and it is meant as a
 * pedagogical tool for learning about compilers.  The integer global
 * variables "a" to "z" are predefined and initialized to zero, and it
 * is not possible to declare new variables.  The compiler reads the
 * program from standard input and prints out the value of the
 * variables that are not zero.  The grammar of Tiny-C in EBNF is:
 *
 *  <program> ::= <statement>
 *  <statement> ::= "if" <paren_expr> <statement> |
 *                  "if" <paren_expr> <statement> "else" <statement> |
 *                  "while" <paren_expr> <statement> |
 *                  "do" <statement> "while" <paren_expr> ";" |
 *                  "{" { <statement> } "}" |
 *                  <expr> ";" |
 *                  ";"
 *  <paren_expr> ::= "(" <expr> ")"
 *  <expr> ::= <test> | <id> "=" <expr>
 *  <test> ::= <sum> | <sum> "<" <sum>
 *  <sum> ::= <term> | <sum> "+" <term> | <sum> "-" <term>
 *  <term> ::= <id> | <int> | <paren_expr>
 *  <id> ::= "a" | "b" | "c" | "d" | ... | "z"
 *  <int> ::= <an_unsigned_decimal_integer>
 *
 * Here are a few invocations of the compiler:
 *
 * % echo "a=b=c=2<3;" | ./a.out
 * a = 1
 * b = 1
 * c = 1
 * % echo "{ i=1; while (i<100) i=i+i; }" | ./a.out
 * i = 128
 * % echo "{ i=125; j=100; while (i-j) if (i<j) j=j-i; else i=i-j; }" | ./a.out
 * i = 25
 * j = 25
 * % echo "{ i=1; do i=i+10; while (i<50); }" | ./a.out
 * i = 51
 * % echo "{ i=1; while ((i=i+10)<50) ; }" | ./a.out
 * i = 51
 * % echo "{ i=7; if (i<5) x=1; if (i<10) y=2; }" | ./a.out
 * i = 7
 * y = 2
 *
 * The compiler does a minimal amount of error checking to help
 * highlight the structure of the compiler.
 */

import core.stdc.stdio : printf, fprintf, stderr, getchar, EOF;
import core.stdc.stdlib : exit, malloc;

/*---------------------------------------------------------------------------*/

/* Lexer. */

enum { DO_SYM, ELSE_SYM, IF_SYM, WHILE_SYM, LBRA, RBRA, LPAR, RPAR,
       PLUS, MINUS, LESS, SEMI, EQUAL, INT, ID, EOI };

string[] words = ["do", "else", "if", "while"];

int ch = ' ';
int sym;
int int_val;
char id_char;

void syntax_error(int x = 0)
{ fprintf(stderr, "syntax error (%d)\n", x); exit(1); }

void next_ch() { ch = getchar(); }

void next_sym()
{
again:
  switch (ch)
  {
  case ' ', '\n': next_ch(); goto again;
  case EOF: sym = EOI; break;
  case '{': next_ch(); sym = LBRA; break;
  case '}': next_ch(); sym = RBRA; break;
  case '(': next_ch(); sym = LPAR; break;
  case ')': next_ch(); sym = RPAR; break;
  case '+': next_ch(); sym = PLUS; break;
  case '-': next_ch(); sym = MINUS; break;
  case '<': next_ch(); sym = LESS; break;
  case ';': next_ch(); sym = SEMI; break;
  case '=': next_ch(); sym = EQUAL; break;
  default:
    if ((int_val = cast(ubyte)(ch - '0')) < 10)
    { /* missing overflow check */
    another_digit:
      next_ch();
      int x;
      if((x = cast(ubyte)(ch - '0')) < 10)
        int_val = int_val*10 + x;
      else
        goto another_digit;
      sym = INT;
    }
    else if (ch >= 'a' && ch <= 'z')
    {
      size_t id_len = 0;
      char[5] id_name; // "while".length == 5
      id_char = cast(char)ch;
      do
      {
        id_name[id_len++] = cast(char)ch;
        next_ch();
      }
      while (((ch >= 'a' && ch <= 'z') || ch == '_') &&
             id_len < id_name.length);
      sym = DO_SYM;
      while (sym < words.length && id_name[0..id_len] != words[sym])
        sym++;
      if (sym == words.length)
        if (id_len == 1)
          sym = ID;
        else
          syntax_error(1); // Only single-letter variables allowed.
    }
    else
      syntax_error(2);
  }
}

/*---------------------------------------------------------------------------*/

/* Parser. */

enum { VAR, CST, ADD, SUB, LT, SET,
       IF1, IF2, WHILE, DO, EMPTY, SEQ, EXPR, PROG }

struct Node { int kind; Node* o1, o2, o3; int val; }

Node* new_Node(int k)
{
  Node* x = cast(Node*)malloc(Node.sizeof);
  x.kind = k;
  return x;
}

Node* paren_expr(); /* forward declaration */

Node* term()  /* <term> ::= <id> | <int> | <paren_expr> */
{ Node* x;
  if (sym == ID) { x=new_Node(VAR); x.val=id_char-'a'; next_sym(); }
  else if (sym == INT) { x=new_Node(CST); x.val=int_val; next_sym(); }
  else x = paren_expr();
  return x;
}

Node* sum()  /* <sum> ::= <term> | <sum> "+" <term> | <sum> "-" <term> */
{ Node* t, x = term();
  while (sym == PLUS || sym == MINUS)
  { t=x; x=new_Node(sym==PLUS?ADD:SUB); next_sym(); x.o1=t; x.o2=term(); }
  return x;
}

Node* test()  /* <test> ::= <sum> | <sum> "<" <sum> */
{ Node* t, x = sum();
  if (sym == LESS)
  { t=x; x=new_Node(LT); next_sym(); x.o1=t; x.o2=sum(); }
  return x;
}

Node* expr()  /* <expr> ::= <test> | <id> "=" <expr> */
{ Node* t, x;
  if (sym != ID) return test();
  x = test();
  if (x.kind == VAR && sym == EQUAL)
  { t=x; x=new_Node(SET); next_sym(); x.o1=t; x.o2=expr(); }
  return x;
}

Node* paren_expr()  /* <paren_expr> ::= "(" <expr> ")" */
{ Node* x;
  if (sym == LPAR) next_sym(); else syntax_error(3);
  x = expr();
  if (sym == RPAR) next_sym(); else syntax_error(4);
  return x;
}

Node* statement()
{
  Node* t, x;
  if (sym == IF_SYM)  /* "if" <paren_expr> <statement> */
  { x = new_Node(IF1);
    next_sym();
    x.o1 = paren_expr();
    x.o2 = statement();
    if (sym == ELSE_SYM)  /* ... "else" <statement> */
      { x.kind = IF2;
        next_sym();
        x.o3 = statement();
      }
  }
  else if (sym == WHILE_SYM)  /* "while" <paren_expr> <statement> */
  { x = new_Node(WHILE);
    next_sym();
    x.o1 = paren_expr();
    x.o2 = statement();
  }
  else if (sym == DO_SYM)  /* "do" <statement> "while" <paren_expr> ";" */
  { x = new_Node(DO);
    next_sym();
    x.o1 = statement();
    if (sym == WHILE_SYM) next_sym(); else syntax_error(5);
    x.o2 = paren_expr();
    if (sym == SEMI) next_sym(); else syntax_error(6);
  }
  else if (sym == SEMI)  /* ";" */
  { x = new_Node(EMPTY); next_sym(); }
  else if (sym == LBRA)  /* "{" { <statement> } "}" */
  { x = new_Node(EMPTY);
    next_sym();
    while (sym != RBRA)
    { t=x; x=new_Node(SEQ); x.o1=t; x.o2=statement(); }
    next_sym();
  }
  else  /* <expr> ";" */
  { x = new_Node(EXPR);
    x.o1 = expr();
    if (sym == SEMI) next_sym(); else syntax_error(7);
  }
  return x;
}

Node* program()  /* <program> ::= <statement> */
{
  Node* x = new_Node(PROG);
  next_sym(); x.o1 = statement(); if (sym != EOI) syntax_error(8);
  return x;
}

/*---------------------------------------------------------------------------*/

/* Code generator. */
alias code = ubyte;

enum : code
{ IFETCH, ISTORE, IPUSH, IPOP, IADD, ISUB, ILT, JZ, JNZ, JMP, HALT }

__gshared code[1000] object_code;
code* op = object_code.ptr; /* Current code position. */

void g(code c) { *op++ = c; } /* missing overflow check */
void v(int letter) { g(cast(code)letter); }
code* hole() { return op++; }
void fix(code* src, code* dst)
{ *src = cast(code)(dst-src); } /* missing overflow check */

void emit(Node* x)
{
  code* p1, p2;
  switch (x.kind)
  {
  case VAR  : g(IFETCH); v(x.val); break;
  case CST  : g(IPUSH); v(x.val); break;
  case ADD  : emit(x.o1); emit(x.o2); g(IADD); break;
  case SUB  : emit(x.o1); emit(x.o2); g(ISUB); break;
  case LT   : emit(x.o1); emit(x.o2); g(ILT); break;
  case SET  : emit(x.o2); g(ISTORE); v(x.o1.val); break;
  case IF1  : emit(x.o1); g(JZ); p1=hole(); emit(x.o2); fix(p1,op); break;
  case IF2  : emit(x.o1); g(JZ); p1=hole(); emit(x.o2); g(JMP); p2=hole();
              fix(p1,op); emit(x.o3); fix(p2,op); break;
  case WHILE: p1=op; emit(x.o1); g(JZ); p2=hole(); emit(x.o2);
              g(JMP); fix(hole(),p1); fix(p2,op); break;
  case DO   : p1=op; emit(x.o1); emit(x.o2); g(JNZ); fix(hole(),p1); break;
  case EMPTY: break;
  case SEQ  : emit(x.o1); emit(x.o2); break;
  case EXPR : emit(x.o1); g(IPOP); break;
  case PROG : emit(x.o1); g(HALT); break;
  version(WHILE_Commented)
  {
  case WHILE:
  p1 = op; // Remember start address of the condition.
  emit(x.o1); // Emit the condition.
  g(JZ); // Emit jump opcode. Tests condition and exits if zero.
  p2 = hole(); // Reserve space for exit address.
  emit(x.o2); // Emit the loop body.
  g(JMP); // Emit jump opcode. Jumps back to the condition.
  fix(hole(), p1); // Emit address of the condition.
  fix(p2, op); // Jumped here if condition is zero (false).
  }
  default:
    assert(0);
  }
}

/*---------------------------------------------------------------------------*/

/* Virtual machine. */

int globals[26];

void run()
{
  int stack[1000];
  auto sp = stack.ptr;
  code* pc = object_code.ptr;

  while (1)
    switch (*pc++)
    {
    case IFETCH: *sp++ = globals[*pc++];               break;
    case ISTORE: globals[*pc++] = sp[-1];              break;
    case IPUSH : *sp++ = *pc++;                        break;
    case IPOP  : --sp;                                 break;
    case IADD  : sp[-2] = sp[-2] + sp[-1]; --sp;       break;
    case ISUB  : sp[-2] = sp[-2] - sp[-1]; --sp;       break;
    case ILT   : sp[-2] = sp[-2] < sp[-1]; --sp;       break;
    case JMP   : pc += *pc;                            break;
    case JZ    : if (*--sp == 0) pc += *pc; else pc++; break;
    case JNZ   : if (*--sp != 0) pc += *pc; else pc++; break;
    case HALT  : return;
    default:
      assert(0);
    }
}

/*---------------------------------------------------------------------------*/

/* Main program. */

void main()
{
  emit(program());

  globals[] = 0;

  run();

  foreach (i, global; globals)
    if (global != 0)
      printf("%c = %d\n", 'a'+i, global);
}
