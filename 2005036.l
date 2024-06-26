%option noyywrap
%option yylineno

%x CONST_CHAR
%x STRING_STATE
%x SINGLE_LINE_CMNT
%x MULTI_LINE_CMNT


%{
/* #include <cstdio> */
#include <iostream>
#include <fstream>
#include "2005036_SymbolTable.cpp"

using namespace std;

string upperCase(string s);
void printLogFile(string tokenName, string lexeme);
void printTokenFile(string tokenType, string token);
void printError(string error, string lexeme);
void replaceEscapeChar(const char* chars);
void printIndentationError();
void checkIndentation();


ofstream logout;
ofstream tokenout;

int BUCKET_NUM = 10;

int errorCount = 0;
int warningCount = 0;

int expectedTab = 0;
int tabCount = 0;
int spaceCount = 0;
bool foundNewLine = true;

int lineCount;
bool isMultiline;

string lexeme;
string token;

SymbolTable* symbolTable = new SymbolTable(BUCKET_NUM); 


%}

DIGIT [0-9]
DIGITS	{DIGIT}*

INT {DIGIT}+

EXP_NUM		{INT}E[+-]?{INT}
DECIMAL_POINT_NUM	{DIGITS}\.{INT}
EXP_AND_DEC_NUM		{DIGITS}(\.{INT})(E[+-]?{INT})

FLOAT	{EXP_NUM}|{DECIMAL_POINT_NUM}|{EXP_AND_DEC_NUM}

REDUNDENT_DECIMAL	{DIGITS}\.({DIGITS}\.)+{DIGITS}(E[+-]?{INT})?
ILL_FORMED_NUM	{INT}E({FLOAT}|{REDUNDENT_DECIMAL})
INVALID_NUM		({INT}|{FLOAT}){CHAR}+

NEWLINE		\n|\r\n
TAB		\t
SPACE	[ ]

CHAR	[A-Za-z]
ALPHANUMERIC	[A-Za-z0-9_]
ESP_CHAR \\['"ntafrbv0\\]

%%

{NEWLINE}	{ 
	foundNewLine = true;
	tabCount = 0;
	spaceCount = 0; 
}
{TAB}	{ 
	tabCount++; 
}
{SPACE}	{
	spaceCount++;
}

"if"        |	
"else"      |
"for"       |
"while"     |
"do"        |	
"break"     |
"int"       |
"char"      |
"float"     |
"double"    |
"void"      |
"return"    |
"switch"    |	
"case"	    |
"default"   |	
"continue"	{ 
	checkIndentation();
	printTokenFile(upperCase(yytext), yytext);
	printLogFile(upperCase(yytext), yytext);
}

{INT}	{ 
	checkIndentation();
	printTokenFile("CONST_INT", yytext);
	printLogFile("CONST_INT", yytext);
}
{FLOAT}		{ 
	checkIndentation();
	printTokenFile("CONST_FLOAT", yytext);
	printLogFile("CONST_FLOAT", yytext);
}
{REDUNDENT_DECIMAL}		{
	checkIndentation();
	errorCount++;
	printError("TOO_MANY_DECIMAL_POINTS", yytext);
}
{ILL_FORMED_NUM}	{
	checkIndentation();
	errorCount++;
	printError("ILLFORMED_NUMBER", yytext);
}
{INVALID_NUM}	{
	checkIndentation();
	errorCount++;
	printError("INVALID_ID_SUFFIX_NUM_PREFIX", yytext);
}


\'	{
	checkIndentation();
	BEGIN CONST_CHAR;
	lexeme = yytext;
	token = "";
}
<CONST_CHAR>\'	{
	lexeme += yytext;

	if(token.size() == 0){
		errorCount++;
		printError("EMPTY_CONST_CHAR", lexeme);
	}
	else if(token.size() == 1){
		printLogFile("CONST_CHAR", token);
		printTokenFile("CONST_CHAR", token);
	}
	else{
		errorCount++;
		printError("MULTICHAR_CONST_CHAR", lexeme);
	}

	BEGIN INITIAL;
}
<CONST_CHAR>[^'\n\r]	{
	lexeme += yytext;
	token += yytext;
}
<CONST_CHAR>{ESP_CHAR}	{
	lexeme += yytext;
	replaceEscapeChar(yytext);
}
<CONST_CHAR>{NEWLINE}	{
	//re-initiating indentation params
	foundNewLine = true;
	tabCount = 0;
	spaceCount = 0;

	//pointing to unfinished char line
	yylineno--;

	errorCount++;
	printError("UNFINISHED_CONST_CHAR", lexeme);
	
	//restoring original line count
	yylineno++;
	BEGIN INITIAL;
}


"+"|"-"		{
	checkIndentation();
	printTokenFile("ADDOP", yytext);
	printLogFile("ADDOP", yytext);
}
"*"|"/"|"%"	{
	checkIndentation();
	printTokenFile("MULOP", yytext);
	printLogFile("MULOP", yytext);
}
"++"|"--"	{
	checkIndentation();
	printTokenFile("INCOP", yytext);
	printLogFile("INCOP", yytext);
}
"<"|"<="|">"|">="|"=="|"!="		{
	checkIndentation();
	printTokenFile("RELOP", yytext);
	printLogFile("RELOP", yytext);
}
"="			{
	checkIndentation();
	printTokenFile("ASSIGNOP", yytext);
	printLogFile("ASSIGNOP", yytext);
}
"&&"|"||"	{
	checkIndentation();
	printTokenFile("LOGICOP", yytext);
	printLogFile("LOGICOP", yytext);
}
"&"|"|"|"^"|"<<"|">>"	{
	checkIndentation();
	printTokenFile("BITOP", yytext);
	printLogFile("BITOP", yytext);
}
"!"			{
	checkIndentation();
	printTokenFile("NOT", yytext);
	printLogFile("NOT", yytext);
}
"("			{
	checkIndentation();
	printTokenFile("LPAREN", yytext);
	printLogFile("LPAREN", yytext);
}
")"			{
	checkIndentation();
	printTokenFile("RPAREN", yytext);
	printLogFile("RPAREN", yytext);
}
"{"			{
	checkIndentation();
	expectedTab++;
	
	printTokenFile("LCURL", yytext);
	printLogFile("LCURL", yytext);

	symbolTable->enterScope();
}
"}"			{
	expectedTab--;
	checkIndentation();
	
	printTokenFile("RCURL", yytext);
	printLogFile("RCURL", yytext);

	symbolTable->exitScope();
}
"["			{
	checkIndentation();
	printTokenFile("LSQUARE", yytext);
	printLogFile("LSQUARE", yytext);
}
"]"			{
	checkIndentation();
	printTokenFile("RSQUARE", yytext);
	printLogFile("RSQUARE", yytext);
}
","			{
	checkIndentation();
	printTokenFile("COMMA", yytext);
	printLogFile("COMMA", yytext);
}
";"			{
	checkIndentation();
	printTokenFile("SEMICOLON", yytext);
	printLogFile("SEMICOLON", yytext);
}	

(_|{CHAR}){ALPHANUMERIC}*	{
	checkIndentation();
	
	printTokenFile("ID", yytext);
	printLogFile("ID", yytext);

	if(symbolTable->insert(yytext, "ID"))
		symbolTable->printAllScopeTables();
	else
		cout << '\t' << yytext << " already exists in the current ScopeTable" 
			<< endl;
}



\"  {
		checkIndentation();
		lineCount = yylineno;
		lexeme = yytext;
		token = "";
		isMultiline = false;
		BEGIN STRING_STATE;
}

<STRING_STATE>\"	{
	checkIndentation();
	lexeme += yytext;

	int tempLineNum = yylineno;
	yylineno = lineCount;

	if(isMultiline) {
		printTokenFile("MULTI LINE STRING", token);
		printLogFile("MULTI LINE STRING", lexeme);
	}	
	else {
		printTokenFile("SINGLE LINE STRING", token);
		printLogFile("SINGLE LINE STRING", lexeme);
	}
		

	yylineno = tempLineNum;
	
	BEGIN INITIAL;
}
<STRING_STATE>\\{NEWLINE}  {
	checkIndentation();

	//re-initiating indentation params
	foundNewLine = true;
	tabCount = 0;
	spaceCount = 0;

	lexeme += yytext ;
	isMultiline = true;
}
<STRING_STATE>{NEWLINE}  	{
	//re-initiating indentation params
	foundNewLine = true;
	tabCount = 0;
	spaceCount = 0;

	//pointing to unfinished string line
	yylineno--;
	
	errorCount++;
	printError("UNFINISHED_STRING", lexeme);

	//restoring original line count
	yylineno++;
	BEGIN INITIAL;
}
<STRING_STATE><<EOF>>  	{
	
	errorCount++;
	printError("UNFINISHED_STRING", lexeme);
	
	BEGIN INITIAL;
}
<STRING_STATE>{ESP_CHAR}	{
	checkIndentation();
	lexeme += yytext;
	replaceEscapeChar(yytext);
}
<STRING_STATE>{TAB}		{
	tabCount++;
	lexeme += yytext ;
	token += yytext ;
}
<STRING_STATE>{SPACE}	{
	spaceCount++;
	lexeme += yytext ;
	token += yytext ;
}
<STRING_STATE>[^\n\r\\\"\t ]+ {
	checkIndentation();
	lexeme += yytext ;
	token += yytext ;
}			



\/\/	{
	lineCount = yylineno;
	lexeme = yytext;

	BEGIN SINGLE_LINE_CMNT;
}
<SINGLE_LINE_CMNT>(\\{NEWLINE}|[^\n\r])*	{
	lexeme += yytext;
}
<SINGLE_LINE_CMNT>{NEWLINE}		{
	//re-initiating indentation params
	foundNewLine = true;
	tabCount = 0;
	spaceCount = 0;

	int tempLineNum = yylineno;
	yylineno = lineCount;

	printLogFile("SINGLE LINE COMMENT", lexeme);

	yylineno = tempLineNum;
	BEGIN INITIAL;
}

"/*"	{
	BEGIN MULTI_LINE_CMNT;
	lineCount = yylineno;
	lexeme = yytext;
}
<MULTI_LINE_CMNT>"*/"	{
	lexeme += yytext;

	int tempLineNum = yylineno;
	yylineno = lineCount;
	
	printLogFile("MULTI LINE COMMENT", lexeme);

	BEGIN INITIAL;
	yylineno = tempLineNum;
}

<MULTI_LINE_CMNT>[^*]*	{
	lexeme += yytext;
}
<MULTI_LINE_CMNT>\*	{
	lexeme += yytext;
}

<MULTI_LINE_CMNT><<EOF>>	{
	
	errorCount++;
	printError("UNFINISHED_COMMENT", lexeme);	

	BEGIN INITIAL;
}

.	{
	checkIndentation();
	errorCount++;
	printError("UNRECOGNIZED_CHAR", yytext);	
}

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	

	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("2005036_log.txt");
	tokenout.open("2005036_token.txt");

	streambuf* coutBuffer = std::cout.rdbuf();
	cout.rdbuf(logout.rdbuf());

	yyin = fin;
	yylineno = 1;
	yylex();
	
	symbolTable->printAllScopeTables();
	cout << "Total lines: " << yylineno << endl;
	cout << "Total errors: " << errorCount << endl;
	cout << "Total warnings: " << warningCount << endl;

	fclose(yyin);
	logout.close();
	tokenout.close();

	cout.rdbuf(coutBuffer);

	return 0;
}

void printLogFile(string tokenName, string lexeme){
	cout << "Line# " << yylineno << ": Token <" << tokenName << "> Lexeme " <<
		lexeme << " found" << endl;
}
void printError(string error, string lexeme){
	cout << "Error at line# " << yylineno << ": " << error << " " <<
		lexeme << endl;
}
void printTokenFile(string tokenType, string token){
	tokenout << "<" << tokenType << ", " << token << ">" << endl;
}

string upperCase(string s){
    string str = s;
    
    for(int i = 0; i < s.size(); i++){
        str[i] = str[i] - ('a' - 'A');
    }
    
    return str;
}

void checkIndentation(){
	if(foundNewLine){
		if(spaceCount != 0){
			warningCount++;

			cout << "Line# " << yylineno << ": Warning, tab requrired but got space." << endl;
		}
		else if(expectedTab != tabCount){
			cout << "Line# " << yylineno << ": warning, " << expectedTab <<
				" of tabs needed but got " << tabCount << " tabs." << endl;
			 
			warningCount++;
		}
	}
	foundNewLine = false;
}
void printIndentationError(){
	cout << "Line# " << yylineno << ": warning, " << expectedTab <<
		" of tabs needed but got " << tabCount << " tabs." << endl;
}

void replaceEscapeChar(const char* chars){

	switch(chars[1]){
		case 't':
			token += '\t';
			break;
		case '\'':
			token += '\'';
			break;
		case '\"':
			token += '\"';
			break;
		case '\\':
			token += '\\';
			break;
		case 'n':
			token += '\n';
			break;
		case 'r':
			token += '\r';
			break;
		case 'a':
			token += '\a';
			break;
		case 'f':
			token += '\f';
			break;
		case 'b':
			token += '\b';
			break;
		case 'v':
			token += '\v';
			break;
		case '0':
			token += '\0';
			break;
	}
}
