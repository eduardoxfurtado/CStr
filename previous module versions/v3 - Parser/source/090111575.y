
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    /*define o tipo de informação que vamos passar pra ele:*/
    // #define YYSTYPE double
    /*geramos esta funcao com o flex, que eh padrao*/
    extern int yylex();
    extern int parse_multiple_line_comments();
    extern int parse_single_line_comments();
    extern int parse_string();
    extern int g_line_counter;

    typedef struct tree_node_struct {
        char description[255];
        char value[255];
        int node_brother_count;
        struct tree_node_struct *father, *node_brothers_list, *child;
    } NODE;

    // Estrutura usada para adicionar um novo no na arvore
    typedef struct description_and_value_data_for_the_tree {
        char description[255];
        char value[255];
    } description_and_value_data_for_the_tree;

    // Estrutura usada para adicionar novas linhas na Tabela de Símbolos:
    typedef struct data_for_the_symbol_table {
        char name[255];
        char type[255];
        char category[255];
    } data_for_the_symbol_table;

    // Tabela de Símbolos:
    typedef struct symbol_table_struct {
        char name[255];
        char value[255];
        // o escopo pode ser global (no caso de funções) ou o nome da função em que está (no caso de variáveis)
        char scope[255];
        char type[255];
        char category[255];
        struct symbol_table_struct *previous, *next;
    } symbol_table_struct;

    // protótipos de funções
    void printSymbolTable();
    void addSymbolTableLine(data_for_the_symbol_table*);
    void setCurrentScope(const char*);
    NODE* addTreeNode(description_and_value_data_for_the_tree*);
    void addNodeToListOfNodeBrothers(NODE*, NODE*);
    void addChildToTreeNode(NODE*, NODE*);
    void setValueInSymbolTableEntry(char *);
	void printSyntaxTree(NODE* root, int identation_counter);
	void setLastValueByIdentifierName(char *);
    void yyerror (char const *s); /* -> função de tratamento de erros do bison */

	// variáveis globais
    char g_current_scope[255];
    int g_symbol_table_size = 0;
    symbol_table_struct* g_symbol_table_current_line;
    symbol_table_struct *g_symbol_table_first_line;
    char g_last_value_from_st_entry [255];
    description_and_value_data_for_the_tree *g_desc_and_val;
    data_for_the_symbol_table *g_symbol_data;
    int g_syntax_error_flag = 0;
%}

%union {
    int int_value;
    char str_value[255];
    char char_value;

    struct tree_node_struct *NODE;
}

%define parse.error verbose

%token <char_value> OPERATOR
%token <str_value> Identifier
%token IF
%token ELSE
%token WHILE
%token INT
%token <str_value> NUMBER
%token STRING
%token <str_value> TEXT
%token VOID
%token RETURN
%token '('
%token ')'
%token '{'
%token '}'
%token ','
%token ';'
%token '='
%token '*'
%token '/'
%token '+'
%token '-'
%token '.'
%token ':'

%token EqualTo
%token LessThan
%token GreaterThan
%token LessThanOrEqualTo
%token GreaterThanOrEqualTo
%token NotEqualTo

%start Begin

%type <NODE> Begin
%type <NODE> Function
%type <NODE> Type
%type <NODE> CompoundStmt
%type <NODE> StmtList
%type <NODE> FormalArgList
%type <NODE> FormalArg
%type <NODE> Stmt
%type <NODE> WhileStmt
%type <NODE> Declaration
%type <NODE> Expr
%type <NODE> IfStmt
%type <NODE> ReturnStmt

%type <NODE> ArgList
%type <NODE> Arg
%type <NODE> Attribution
%type <NODE> Rvalue
%type <NODE> Compare
%type <NODE> Addition
%type <NODE> Multiplication
%type <NODE> Term
%type <NODE> Factor
%type <NODE> FunctionCall
%type <NODE> StringConcat
%type <NODE> RETURN

%nonassoc IFX
%nonassoc ELSE

%% /* Regras Gramaticais */
/* aqui começa nossa gramática , uma palavra válida é zero ou mais linhas de
entrada */
/* define recursivamente as possíveis expressões */
Begin           : Function
                {
                    strcpy(g_desc_and_val->description, "CStr");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);
                    addChildToTreeNode($$, $1);
                    if (g_syntax_error_flag == 0)
                    {
                        printf("\nArvore sintatica:\n");
                        printSyntaxTree($$,0);
                        printSymbolTable();
                    }
                };

Function 		: Type Identifier '(' FormalArgList ')' CompoundStmt
                {
                    strcpy(g_desc_and_val->description, "Function");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $2);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$4);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$6);

                    setCurrentScope("GLOBAL");
                    strcpy(g_symbol_data->name, $2);
                    strcpy(g_symbol_data->type, $1->child->description);
                    strcpy(g_symbol_data->category, "FUNCTION");
                    addSymbolTableLine(g_symbol_data);
                    // o escopo passa a ser o da função inserida:
                    setCurrentScope($2);

                }
                | Function Type Identifier '(' FormalArgList ')' CompoundStmt
                {
                    strcpy(g_desc_and_val->description, "Function");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    addChildToTreeNode($$,$2);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$5);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$7);

                    setCurrentScope("GLOBAL");
                    strcpy(g_symbol_data->name, $3);
                    strcpy(g_symbol_data->type, $2->child->description);
                    strcpy(g_symbol_data->category, "FUNCTION");
                    addSymbolTableLine(g_symbol_data);
                    // o escopo passa a ser o da função inserida:
                    setCurrentScope($3);
                }
                | error '}'
                {
                    strcpy(g_desc_and_val->description, "SYNTAX ERROR");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                    g_syntax_error_flag = 1;
                };

FormalArgList   : /*empty*/
                {
                    strcpy(g_desc_and_val->description, "FormalArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                }
                | FormalArg
                {
                    strcpy(g_desc_and_val->description, "FormalArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | FormalArgList ',' FormalArg
                {
                    strcpy(g_desc_and_val->description, "FormalArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ",");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                };

FormalArg       : Type Identifier
                {
                    strcpy(g_desc_and_val->description, "FormalArg");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $2);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    setCurrentScope("-");
                    strcpy(g_symbol_data->name, $2);
                    strcpy(g_symbol_data->type, $1->child->description);
                    strcpy(g_symbol_data->category, "VARIABLE");
                    addSymbolTableLine(g_symbol_data);
                };

ArgList         : /*empty*/
                {
                    strcpy(g_desc_and_val->description, "ArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                }
                | Arg
                {
                    strcpy(g_desc_and_val->description, "ArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | ArgList ',' Arg
                {
                    strcpy(g_desc_and_val->description, "ArgList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ",");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                };

Arg             : Factor
                {
                    strcpy(g_desc_and_val->description, "Arg");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | FunctionCall
                {
                    strcpy(g_desc_and_val->description, "Arg");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | StringConcat
                {
                    strcpy(g_desc_and_val->description, "Arg");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Declaration     : Type Identifier
                {
                    strcpy(g_desc_and_val->description, "Declaration");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $2);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    setCurrentScope("-");
                    strcpy(g_symbol_data->name, $2);
                    strcpy(g_symbol_data->type, $1->child->description);
                    strcpy(g_symbol_data->category, "VARIABLE");
                    addSymbolTableLine(g_symbol_data);
                }
                | Type Attribution
                {
                    strcpy(g_desc_and_val->description, "Declaration");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    addChildToTreeNode($$,$2);

                    setCurrentScope("-");
                    strcpy(g_symbol_data->name, $2->child->value);
                    strcpy(g_symbol_data->type, $1->child->description);
                    strcpy(g_symbol_data->category, "VARIABLE");
                    addSymbolTableLine(g_symbol_data);
                    setValueInSymbolTableEntry($2->child->value);
                };

Type            : INT
                {
                    strcpy(g_desc_and_val->description, "Type");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "int");
                    strcpy(g_desc_and_val->value, "");

                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | STRING
                {
                    strcpy(g_desc_and_val->description, "Type");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "string");
                    strcpy(g_desc_and_val->value, "");

                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                };

CompoundStmt    : '{' StmtList '}'
                {
                    strcpy(g_desc_and_val->description, "CompoundStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "{");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$2);

                    strcpy(g_desc_and_val->description, "}");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | error '}'
                {
                    strcpy(g_desc_and_val->description, "SYNTAX ERROR");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                    g_syntax_error_flag = 1;
                };

StmtList        : StmtList Stmt
                {
                    strcpy(g_desc_and_val->description, "StmtList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                    addChildToTreeNode($$,$2);
                }
                |/*empty*/
                {
                    strcpy(g_desc_and_val->description, "StmtList");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                };

Stmt            : WhileStmt
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | Declaration   ';'
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ";");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | Expr ';'
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ";");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | IfStmt
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | CompoundStmt
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | ReturnStmt ';'
                {
                    strcpy(g_desc_and_val->description, "Stmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ";");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | error ';'
                {
                    strcpy(g_desc_and_val->description, "SYNTAX ERROR");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                    g_syntax_error_flag = 1;
                }
                | error '{'
                {
                    strcpy(g_desc_and_val->description, "SYNTAX ERROR");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,NULL);
                    g_syntax_error_flag = 1;
                };

WhileStmt       : WHILE '(' Expr ')' CompoundStmt
                {
                    strcpy(g_desc_and_val->description, "WhileStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "WHILE");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$5);
                };

IfStmt          : IF '(' Expr ')' CompoundStmt %prec IFX
                {
                    strcpy(g_desc_and_val->description, "IfStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "IF");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$5);
                }
                | IF '(' Expr ')' CompoundStmt ELSE CompoundStmt
                {
                    strcpy(g_desc_and_val->description, "IfStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "IF");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$5);

                    strcpy(g_desc_and_val->description, "ELSE");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$7);
                };

ReturnStmt      : RETURN
                {
                    strcpy(g_desc_and_val->description, "ReturnStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "RETURN");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | RETURN Expr
                {
                    strcpy(g_desc_and_val->description, "ReturnStmt");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "RETURN");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$2);
                };

Expr            : Rvalue
                {
                    strcpy(g_desc_and_val->description, "Expr");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | Attribution
                {
                    strcpy(g_desc_and_val->description, "Expr");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | FunctionCall
                {
                    strcpy(g_desc_and_val->description, "Expr");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                }
                | StringConcat
                {
                    strcpy(g_desc_and_val->description, "Expr");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Attribution     : Identifier '=' Expr
                {
                    strcpy(g_desc_and_val->description, "Attribution");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "=");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                };

Rvalue          : Rvalue Compare Addition
                {
                    strcpy(g_desc_and_val->description, "Rvalue");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                    addChildToTreeNode($$,$2);
                    addChildToTreeNode($$,$3);
                }
                | Addition
                {
                    strcpy(g_desc_and_val->description, "Rvalue");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Compare         : EqualTo
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "==");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | LessThan
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "<");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | GreaterThan
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, ">");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | LessThanOrEqualTo
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "<=");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | GreaterThanOrEqualTo
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, ">=");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | NotEqualTo
                {
                    strcpy(g_desc_and_val->description, "Compare");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "!=");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                };

Addition        : Addition '+' Multiplication
                {
                    strcpy(g_desc_and_val->description, "Addition");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "+");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                }
                | Addition '-' Multiplication
                {
                    strcpy(g_desc_and_val->description, "Addition");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "-");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                }
                | Multiplication
                {
                    strcpy(g_desc_and_val->description, "Addition");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Multiplication  : Multiplication '*' Factor
                {
                    strcpy(g_desc_and_val->description, "Multiplication");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "*");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                }
                | Multiplication '/' Factor
                {
                    strcpy(g_desc_and_val->description, "Multiplication");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, "/");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);
                }
                | Term
                {
                    strcpy(g_desc_and_val->description, "Multiplication");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Term            : '(' Expr ')'
                {
                    strcpy(g_desc_and_val->description, "Term");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$2);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | '-' Term
                {
                    strcpy(g_desc_and_val->description, "Term");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "-");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$2);
                }
                | '+' Term
                {
                    strcpy(g_desc_and_val->description, "Term");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "+");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$2);
                }
                | Factor
                {
                    strcpy(g_desc_and_val->description, "Term");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);
                };

Factor          : Identifier
                {
                    strcpy(g_desc_and_val->description, "Factor");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    setLastValueByIdentifierName($1);
                }
                | NUMBER
                {
                    strcpy(g_desc_and_val->description, "Factor");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "NUMBER");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_last_value_from_st_entry, $1);
                }
                | TEXT
                {
                    strcpy(g_desc_and_val->description, "Factor");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_last_value_from_st_entry, $1);
                };

FunctionCall    : Identifier '(' ArgList ')'
                {
                    strcpy(g_desc_and_val->description, "FunctionCall");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$3);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | Identifier '.' Identifier '(' ArgList ')'
                {
                    strcpy(g_desc_and_val->description, "FunctionCall");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, ".");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "(");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    addChildToTreeNode($$,$5);

                    strcpy(g_desc_and_val->description, ")");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                };

StringConcat    : StringConcat ':' TEXT
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | StringConcat ':' Identifier
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    addChildToTreeNode($$,$1);

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | TEXT ':' TEXT
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | Identifier ':' TEXT
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | TEXT ':' Identifier
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "TEXT");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                }
                | Identifier ':' Identifier
                {
                    strcpy(g_desc_and_val->description, "StringConcat");
                    strcpy(g_desc_and_val->value, "");
                    $$ = addTreeNode(g_desc_and_val);

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $1);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, ":");
                    strcpy(g_desc_and_val->value, "");
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));

                    strcpy(g_desc_and_val->description, "Identifier");
                    strcpy(g_desc_and_val->value, $3);
                    addChildToTreeNode($$,addTreeNode(g_desc_and_val));
                };
%%

void printSymbolTable()
{
    symbol_table_struct *aux = g_symbol_table_first_line;

    printf("\n\nTabela de simbolos:\n");

    if(0 < g_symbol_table_size)
    {
        while(aux != NULL)
        {
            printf("\nCATEGORY: %s\nTYPE: %s \nNAME: %s\nSCOPE: %s \nVALUE: %s\n", aux->category, aux->type, aux->name, aux->scope, aux->value);
            // printf("\nNAME: %s\nSCOPE: %s \nTYPE: %s \nCATEGORY: %s\n", aux->name,aux->scope,aux->type,aux->category);
            aux = aux->next;
        }
        printf("\n");
    }
}

void setLastValueByIdentifierName(char * var_name)
{
	symbol_table_struct *aux;
	aux = g_symbol_table_first_line;

	if(0 < g_symbol_table_size)
	{
        while(aux != NULL)
        {
            if(strcmp(aux->name,var_name) == 0)
            {
            	strcpy(g_last_value_from_st_entry , aux->value);
            }
            aux = aux->next;
        }
    }
}

void setValueInSymbolTableEntry(char * var_name)
{
    symbol_table_struct *aux;
    aux = g_symbol_table_first_line;

    if(0 < g_symbol_table_size)
    {
        while(aux != NULL)
        {
            if(strcmp(aux->name,var_name) == 0)
            {
                strcpy(aux->value , g_last_value_from_st_entry);
            }

            aux = aux->next;
        }
    }
}

//Cria uma nova linha na Tabela de Símbolos e aponta o elemento anterior e o que segue
void addSymbolTableLine(data_for_the_symbol_table * data)
{
    symbol_table_struct* line = (symbol_table_struct *) malloc (sizeof(symbol_table_struct));

    if(0 == g_symbol_table_size)
    {
        // preenche a entrada
        strcpy(line->scope,g_current_scope);
        strcpy(line->name ,data->name);
        strcpy(line->type,data->type);
        strcpy(line->category ,data->category);

        line->previous = NULL;
        line->next = NULL;

        // controle:
        g_symbol_table_size++;
        g_symbol_table_current_line = line;
        g_symbol_table_first_line = line;
    }
    else
    {
        strcpy(line->scope,g_current_scope);
        strcpy(line->name ,data->name);
        strcpy(line->type,data->type);
        strcpy(line->category ,data->category);

        line->previous = g_symbol_table_current_line;
        line->next = NULL;

        g_symbol_table_current_line->next = line;
        g_symbol_table_size++;
        g_symbol_table_current_line = line;
    }
}

void setCurrentScope(const char *scopeName)
{
    symbol_table_struct *aux;

    if(strcmp(scopeName,"") !=0)
        strcpy(g_current_scope,scopeName);

    aux = g_symbol_table_first_line;

    if(0 < g_symbol_table_size)
    {
        while(aux != NULL)
        {
            if( strcmp(aux->category,"VARIABLE") == 0 && strcmp(g_current_scope,"GLOBAL") != 0 && strcmp(aux->scope,"-") == 0 && strcmp(scopeName,"-") != 0 )
                strcpy(aux->scope,scopeName);
            aux = aux->next;
        }
    }
}

void addNodeToListOfNodeBrothers(NODE *root, NODE *item)
{
    int flag = 0;
    NODE *temp;

    if(item != NULL)
    {
        // se é o primeiro filho
        if (root->node_brothers_list == NULL)
        {
            root->node_brothers_list = item;
        }
        // se não é o primeiro filho
        else
        {
            //add a new child in a child list
            temp = root->node_brothers_list;

            while(0 == flag)
            {
                if(temp->node_brothers_list != NULL)
                    temp = temp->node_brothers_list;
                else
                    flag = 1;
            }

            //effect of the add
            temp->node_brothers_list = item;
        }
    }
}

// cria um novo nodo para ser preenchido depois. aloca memória pra ele, basicamente
NODE *addTreeNode(description_and_value_data_for_the_tree *g_desc_and_val)
{
    NODE *node;

    node = (NODE *) malloc (sizeof(NODE));

    strcpy(node->description , g_desc_and_val->description);
    strcpy(node->value , g_desc_and_val->value);

    node->node_brother_count = 0;
    node->father = NULL;
    node->child = NULL;
    node->node_brothers_list = NULL;

    return node;
}

void addChildToTreeNode(NODE *root, NODE *item)
{
    int flag = 0;
    NODE *temp;

    if(item != NULL)
    {
        // se é o primeiro filho
        if (root->child == NULL)
        {
            item->father = root;
            root->child = item;
        }
        // se não é o primeiro filho
        else
        {
            addNodeToListOfNodeBrothers(root->child, item);
        }

        root->node_brother_count++;
        temp = item;

        // atualiza quem é o nodo pai deste
        while(flag == 0)
        {
            if(temp != NULL)
            {
                temp = temp->node_brothers_list;

                if(temp != NULL)
                {
                    temp->father = root;
                }
            }
            else
            {
                flag = 1;
            }
        }
    }
}

void printSyntaxTree(NODE* root, int identation_counter)
{
    NODE* aux = NULL;
    int i=0;

    if (root != NULL)
    {
        for(i = 0; i < identation_counter; i++) { printf("|   "); }

        printf("%s %s\n", root->description, root->value);

        aux = root->child;

        // chamada recursiva para imprimir os filhos.
        while (aux != NULL)
        {
            printSyntaxTree(aux, identation_counter + 1);
            aux = aux->node_brothers_list;
        }
    }
}

/* Epílogo ( código no final do arquivo ) */
/* Chamado quando há um erro sintático na entrada . */
void yyerror ( char const *s)
{
    printf ("Line %d: %s\n", g_line_counter, s);
}

int main ( void )
{
    g_desc_and_val = (description_and_value_data_for_the_tree*) malloc(sizeof(description_and_value_data_for_the_tree));
    g_symbol_data = (data_for_the_symbol_table*) malloc(sizeof(data_for_the_symbol_table));

    /* Chama o parser . */
    return yyparse ();
}