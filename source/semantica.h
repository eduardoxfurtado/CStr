int isMainFunctionPresent();
char * strToLower(char *);
char * strToUpper(char *);
int functionCallSemanticCheck(NODE *);
int checkReturnStatementsTypes(char *, char *);
int recursivelyLookForReturnInCompoundStmt(NODE *);
int saveReturnStmtType(NODE *);
int saveReturnType(NODE *);
char * getRvalueType(NODE *);
void saveRvalueTypeRecursive(NODE *);
int methodCallSemanticCheck(NODE *, char *, char *, char *);
int identifierSemanticCheck(char *, char *, char *);
char * getTypeByMethodIdentifier(char *);
int getFormalArgCountByMethodIdentifier(char *);
int fillFormalArgsTypesByMethodIdentifier(char[255][255], char *);
int verifyDuplicateFunction(data_for_the_symbol_table*);
int verifyDuplicateVariable(data_for_the_symbol_table*, char *);
void saveExpressionType(NODE*);
char* getTypeFromTSByIdentifier(char *, char *, char *);