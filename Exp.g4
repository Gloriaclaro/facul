grammar Exp;

/*---------------- PARSER INTERNALS ----------------*/

@parser::header
{
import sys

symbol_table = []
type_table = []
unused_vars = []
function_table = []
stack_max = 0
stack_control = 0
if_count = 0
while_count = -1
while_local = 0
has_error = False

# Função de controle da pilha
def emit(print_str, sum):
    print(f'{print_str}')
    global stack_control
    global stack_max
    stack_control = stack_control + sum
    if stack_max < stack_control:
        stack_max = stack_control

# Função de controle das variaveis utilizadas
def used_vars(unused_vars, symbol_table):
    for i in range(len(unused_vars)):
        if unused_vars[i] == False:
            # Retorna o erro quando a variabel não foi utilizada
            print(f"Error: variable '{symbol_table[i]}' not used", file = sys.stderr)


}

/*---------------- LEXER RULES ----------------*/

PLUS  : '+' ;
MINUS : '-' ;
OVER  : '/' ;
REM   : '%' ;
TIMES : '*' ;
OP_PAR: '(' ;
CL_PAR: ')' ;
OP_CUR: '{' ;
CL_CUR: '}' ;
OP_SQR: '[' ;
CL_SQR: ']' ;
ATTRIB: '=' ;
COMMA : ',' ;
PERIOD: '.' ;
EQ    : '==';
NE    : '!=';
GT    : '>' ;
GE    : '>=';
LT    : '<' ;
LE    : '<=';

PRINT   : 'print';
READ_INT: 'read_int';
READ_STR: 'read_str';
IF      : 'if';
WHILE   : 'while';
BREAK   : 'break';
CONTINUE: 'continue';
ELSE    : 'else';
PUSH    : 'push';
LENGTH  : 'length';
DEF     : 'def';

NUMBER: '0'..'9'+ ;
NAME  : 'a'..'z'+ ;
STRING: '"'~('"')*'"';

COMMENT:'#' ~('\n')* -> skip ;
SPACE  : (' '|'\t'|'\r'|'\n')+ -> skip ;


/*---------------- PARSER RULES ----------------*/

program:
    {
print('.source Test.src')
print('.class  public Test')
print('.super  java/lang/Object\n')
print('.method public <init>()V')
print('    aload_0')
print('    invokenonvirtual java/lang/Object/<init>()V')
print('    return')
print('.end method\n')
    }
(function)*main ;

function: DEF NAME
    {
global function_table
if $NAME.text not in function_table:
    function_table.append($NAME.text)
    }
 OP_PAR CL_PAR OP_CUR (statement)+ CL_CUR
    {
print('.method public static cube()V\n')
print('    return')
print('.limit stack', stack_max)
print('.limit locals',len(symbol_table))
print('.end method')
symbol_table = []
type_table = []
unused_vars = []
function_table = []
stack_max = 0
stack_control = 0
if_count = 0
while_count = -1
while_local = 0
    }
;

main:
    {
print('.method public static main([Ljava/lang/String;)V\n')
    }
    ( statement)+
    {
used_vars(unused_vars, symbol_table)
print('    return')
print('.limit stack', stack_max)
print('.limit locals',len(symbol_table))
print('.end method')
print('\n; symbol_table:', symbol_table)
print('\n; unused_vars:', unused_vars)
print('\n; type_table:', type_table)
if has_error == True:
    sys.exit(1)
    }
    ;

statement: st_print | st_attrib | st_if | st_while | st_continue | st_break | st_array_new | st_array_push | st_array_set | st_call;

st_print: PRINT OP_PAR
    {
emit('    getstatic java/lang/System/out Ljava/io/PrintStream;', +1)
    }
    e1 = expression
    {
if $e1.type == 'i':
    emit('    invokevirtual java/io/PrintStream/print(I)V\n', -1)
elif $e1.type == 's':
    emit('    invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n', -1)
elif $e1.type == 'a':
    print(f"    invokevirtual Array/string()Ljava/lang/String;")
    print(f"    invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V")
else:
    print("Error: Type error", file=sys.stderr)

    }
    (COMMA
    {
emit('    getstatic java/lang/System/out Ljava/io/PrintStream;', +1)
    }
    e2 = expression
    {
if $e2.type == 'i':
    emit('    invokevirtual java/io/PrintStream/print(I)V\n', -1)
elif $e2.type == 's':
    emit('    invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n', -1)
else:
    print("Error: Type error", file=sys.stderr)

    }
    )*
    CL_PAR
    {
emit('    getstatic java/lang/System/out Ljava/io/PrintStream;',1)
emit('    invokevirtual java/io/PrintStream/println()V',-1)
    }
    ;

st_attrib: NAME ATTRIB expression
    {
er = False
if $NAME.text not in symbol_table:
    symbol_table.append($NAME.text)
    unused_vars.append(False)
    type_table.append($expression.type)
else:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type != $expression.type:
            er = True
            if my_type == 'i':
                print(f"Error: '{$NAME.text}' is a integer", file=sys.stderr)

            elif my_type == 's':
                print(f"Error: '{$NAME.text}' is a string", file=sys.stderr)

            elif my_type == 'a':
                print(f"Error: '{$NAME.text}' is an array", file=sys.stderr)

            else:
                print(f'Error:Type error in {$NAME.text} ', file=sys.stderr)

if er != True:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type == 'i':
        emit(f"    istore {index}", -1)
    elif my_type == 's':
        emit(f"    astore {index}", -1)
    else:
        print(f'Error: Type error', file=sys.stderr)

    }
    ;

st_if: IF comparison
    {
global if_count
if_local = if_count
emit(f"NOT_IF_{if_count}", -2)
if_count = if_count + 1
    }
OP_CUR (statement)+ CL_CUR
    {
print(f"    goto   END_ELSE_{if_local}")
print(f"NOT_IF_{if_local}:")
    }
(ELSE OP_CUR (statement)+ CL_CUR)?
    {
emit(f"END_ELSE_{if_local}:", -2)
    }
    ;

st_while:
    {
global while_count
global while_local
if while_count == -1:
    while_count = while_count + 1
while_local = while_count
print(f'BEGIN_WHILE_{while_count}:')
    }
WHILE comparison
    {
emit(f"END_WHILE_{while_count}", -2)
    }
OP_CUR (statement)+ CL_CUR
    {
print(f"    goto   BEGIN_WHILE_{while_local}")
print(f"END_WHILE_{while_local}:")
while_count = while_count + 1
    }
    ;

st_continue: CONTINUE
    {
global while_count
global while_local
if while_count == while_local:
    print(f"    goto   BEGIN_WHILE_{while_count}")
else:
    print('Error: continue outside a loop', file = sys.stderr)

    }
    ;

st_break: BREAK
    {
global while_count
global while_local
if while_count == while_local:
    print(f"    goto   END_WHILE_{while_count}")
else:
    print('Error: break outside a loop', file = sys.stderr)

    }
    ;

st_array_new: NAME ATTRIB OP_SQR CL_SQR
    {
if $NAME.text not in symbol_table:
    symbol_table.append($NAME.text)
    unused_vars.append(False)
    type_table.append('a')
    err = False
else:
    print(f"Error: '{$NAME.text}' already declared", file = sys.stderr)

    err = True
if err == False:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    print(f"    new Array")
    print(f"    dup")
    print(f"    invokespecial Array/<init>()V")
    print(f"    astore {index}")
    }
    ;

st_array_push: NAME PERIOD PUSH OP_PAR
    {
index = symbol_table.index($NAME.text)
my_type = type_table[index]

emit(f"    aload {index}", +1)
    }
expression CL_PAR
    {
emit(f"    invokevirtual Array/push(I)V", -2)
    }
    ;

st_array_set: NAME OP_SQR
    {
if $NAME.text in symbol_table:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type != 'a':
        print(f"Error: '{$NAME.text}' is not array", file = sys.stderr)

    emit(f"    aload {index}", +1)
else:
    print(f"Error: '{$NAME.text}' not defined", file = sys.stderr)

    }
e1 = expression CL_SQR ATTRIB e2 = expression
    {
if $e1.type != 'i':
    print(f"Error: array index must be integer", file = sys.stderr)

if $e2.type == 'a':
    print(f"Error: 'a' is array", file = sys.stderr)

elif $e2.type == 's':
    print(f"Error: 's' is string", file = sys.stderr)

emit(f"    invokevirtual Array/set(II)V", -3)
    }
    ;
st_call: NAME OP_PAR CL_PAR
    {
emit(f"    invokevirtual {$NAME.text}/Cube()V", -3)
    }
;

comparison: e1 = expression op = (EQ | NE | GT | GE | LT | LE) e2 = expression
    {
if $op.type == ExpParser.EQ: print('    if_icmpne ', end="")
if $op.type == ExpParser.NE: print('    if_icmpeq ', end="")
if $op.type == ExpParser.GT: print('    if_icmple ', end="")
if $op.type == ExpParser.GE: print('    if_icmplt ', end="")
if $op.type == ExpParser.LT: print('    if_icmpge ', end="")
if $op.type == ExpParser.LE: print('    if_icmpgt ', end="")
if $e1.type != $e2.type:
    print('Error: cannot mix types', file=sys.stderr)

    }
    ;

expression returns [type]: t1 = term ( op = (PLUS | MINUS) t2 = term
    {
if $op.type == ExpParser.PLUS: emit('    iadd', -1)
if $op.type == ExpParser.MINUS: emit('    isub', -1)
if $t1.type != 'i' or $t2.type != 'i':
    print('Error: cannot mix types', file=sys.stderr)

if $t1.type != $t2.type:
    print('Error: cannot mix types', file=sys.stderr)

    }
    )*
    {
$type = $t1.type
    }
    ;

term returns [type]: f1 = factor ( op = (TIMES | OVER | REM) f2 = factor
    {
if $op.type == ExpParser.TIMES: emit('    imul', -1)
if $op.type == ExpParser.OVER: emit('    idiv', -1)
if $op.type == ExpParser.REM: emit('    irem', -1)
if $f1.type != 'i' or $f2.type != 'i':
    print('Error: cannot mix types', file=sys.stderr)

    }
    )*
    {
$type = $f1.type
    }
    ;

factor returns [type]: NUMBER
    {
emit('    ldc ' + $NUMBER.text, +1)
$type = 'i'
    }
    | STRING
    {
emit('    ldc ' + $STRING.text, +1)
$type = 's'
    }
    | OP_PAR expression CL_PAR
    {
$type = $expression.type
    }
    | NAME
    {
if $NAME.text in symbol_table:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type == 's':
        emit(f"    aload {index}", +1)
        $type = 's'
    elif my_type == 'i':
        emit(f"    iload {index}", +1)
        $type = 'i'
    elif my_type == 'a':
        emit(f"    aload {index}", +1)
        $type='a'
    else:
        print('    Type error', file = sys.stderr)

        $type = 'None'
    unused_vars[index] = True
# Retorna o erro quando a variavel não foi definida
else:
    print('Error: variable not defined', file = sys.stderr)

    }
    | READ_INT OP_PAR CL_PAR
    {
emit('    invokestatic Runtime/readInt()I', +1)
$type = 'i'
    }
    | READ_STR OP_PAR CL_PAR
    {
emit('    invokestatic Runtime/readString()Ljava/lang/String;', +1)
$type = 's'
    }
    | NAME PERIOD LENGTH
    {
if $NAME.text in symbol_table:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type == 's':
        print(f"Error: '{$NAME.text}' must be array", file = sys.stderr)

    elif my_type == 'i':
        print(f"Error: '{$NAME.text}' must be array", file = sys.stderr)

    else:
        emit(f"    aload {index}", +1)
        print(f"    invokevirtual Array/length()I")
else:
    print(f"Error: '{$NAME.text}' not defined", file = sys.stderr)

$type = 'i'
    }
    | NAME OP_SQR
    {
if $NAME.text in symbol_table:
    index = symbol_table.index($NAME.text)
    my_type = type_table[index]
    if my_type == 's':
        print(f"Error: '{$NAME.text}' is not array", file = sys.stderr)

    elif my_type == 'i':
        print(f"Error: '{$NAME.text}' is not array", file = sys.stderr)

    else:
        emit(f"    aload {index}", +1)
else:
    print(f"Error: '{$NAME.text}' not defined", file = sys.stderr)

    }
    expression CL_SQR
    {
print(f"    invokevirtual Array/get(I)I")
$type = 'i'
    }
    ;

