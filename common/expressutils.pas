﻿unit expressutils;
{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}
interface

uses
  Classes, SysUtils, typinfo, variants, strutils,contnrs,
  {$IFDEF  FPC}
    dbugintf;
   {$ELSE}
     winapi.windows;
   {$ENDIF}

const
  SYMBOLCHARSET=['A'..'Z', 'a'..'z', '0'..'9', '_', '.', '[', ']','{','}','|'];

type

  TLikeType=(lEqual,lLeftEqual,lRightEqual,lFind);
  ToperatorType = (oEqual{==}, oNotEqual{<>}, oGreaterThan{>}, oGreaterThanOrEqual{>=}, oLessThan{<}, oLessThanOrEqual{<=}, oAnd{And}, oOr{Or}, oNot{Not}
    , oPlus{+}, oSub{-}, oMul{*}, oDiv{/}, oIn{In},oMinus{-负号} ,oNull{ Is Null}, oFunction,oCount,oVar{variable},oSymbol{Symbol},oStringSymbol{StringSymbol},oLike{like string});
  TValueType=(vInteger,vFloat,vString,vDateTime);
  PEChar=PChar;
  CharSet = set of Char;
  TExprValue= variant;

  TExpArray= array of TexprValue;
  //表达式异常类
  ExpressException = class(Exception)
  end;
  TInArray =array of Integer;
  { TStringStack }
  TStringStack = class(TStringList)
  strict private
  public
    procedure DeletePop;
    function PeekItem: string;
    function Pop: string;
    procedure Push(str: string);

  end;
  //表达式对象
  { TExpressNode }
  TExpressNodes=class(TCollection)

  end;

  TExpressNode=class(TCollectionItem)
  private
    FParams:TList;
    FOperatorType:TOperatorType;
    procedure ProcEqual(); //=
    procedure ProcGreaterThan(); //>
    procedure ProcLessThan(); //<
    procedure ProcGreaterThanOrEqual();//>=
    procedure ProcLessThanOrEqual(); //<=
    procedure procNotEqual();//<>
    procedure procAnd(); // And
    procedure procOr();// OR
    procedure procNot();
    function GetParam(aIndex:integer):TExpressNode;

    function FloatEquals(Value1, Value2: Extended): Boolean;
  protected
    FValue:TExprValue;
    procedure ProcParams();
    function IsNumber(str:string):boolean;
  public
    procedure AddParam(Param:TExpressNode);
    function IsTrue:boolean;
    constructor Create(ACollection:Tcollection);override;
    destructor Destroy();override;
    procedure Process();virtual;
    function AsBoolean: Boolean; virtual;
    function AsString:string;virtual;
    function AsInteger:int64;virtual;
    property  Param [aIndex:integer]:TExpressNode read GetParam ;
    property Value:TExprValue Read FValue Write FValue;
  published
    property OperatorType:TOperatorType read FOperatorType write FOperatorType;
  end;

  { TLikeNode }

  TLikeNode=Class(TExpressNode)
  private
    FLikeType:TLikeType;
    FLikeKey:string;
    procedure ProcLike();
  public
    procedure Process();override;
  end;

  { TOperatorBuilder }

  TOperatorBuilder=class(TComponent)
  protected
    FExpNodes:TExpressNodes;
  public
    //比较运算符
    function BuildEuql:TExpressNode;
    function BuildNotEqual:TExpressNode;
    function BuildGreaterThan:TExpressNode;
    function BuildLessThan:TExpressNode;
    function BuildLike(Symbol,Expr:TExpressNode):TExpressNode;
    function BuildGreaterThanOrEqual:TExpressNode;
    function BuildLessThanOrEqual:TExpressNode;
    function BuildIn:TExpressNode;

    //逻辑表达式

    function BuildAnd:TExpressNode;
    function BuildOr:TExpressNode;
    function BuildNot:TExpressNode; //
    function BuildBoolean(Bln:Boolean):TExpressNode;
    //运算符
    function BuildPlus:TExpressNode;  //加号
    function BuildSub:TExpressNode; //减号
    function BuildMul:TExpressNode;  //*号
    function BuildDiv:TExpressNode;  //除号
    function BuildMinus:TExpressNode; //负号
    //符号变量
    function BuildNullSymbol:TExpressNode; //空符号
    function BuildIntegerSymbol(Value:Integer):TExpressNode;
    function BuildStringSymbol(str:string):TExpressNode;
    function BuildFloatSymbol(Value:double):TExpressNode;
    function BuildArraySymbol(Arr:string):TExpressNode;
    function BuildVariable(VarName:string): TExpressNode; virtual;abstract; // 构建变量。 需覆盖此方法特定类型
    constructor Create(AOwner: TComponent);override;
    destructor Destroy();override;
  end;

  //表达式解析器
  { TExpressParser }
  TExpressParser = class(TComponent)
  private
    FExpress: string;
    FSourcePtr: PEChar;
    FWordsList: TstringStack;
    FOperators: TStringStack;
    FObjStack: TObjectStack;
    FOptBuilder:TOperatorBuilder;
    function GetOperatorLevel(ExpressOperator: string): Integer;
    function GetConst(var P: PEChar; var Value: string): Boolean;
    function ProcSymbol(var P: PEChar; var syName: string): Boolean;
    function ProcString(var P: PEChar; var strName: string): Boolean;
    function ProcInArray(var PChr: PEChar): Boolean;
    procedure SKIP(var P: PEChar; ChrSet: CharSet);
    procedure ProcInvisibleChar(var PChr: PEChar);
    function MatchString(Pchr: PEChar; KeyWord: string): boolean;
    procedure ProcessOperator(strOperator: string);
    function IsInteger(const str: string): Boolean;
    function IsFloat(const str: string): Boolean;
    function ParserKeywords:TExpressNode;
    function IsString(strkey:string):boolean;
    function GetString(strKey:string):string;//返回字符串内容 （去掉"")
    function IsSymbol(const str: string): Boolean; //判断是否符号
    function IsArray(strkey: string): Boolean; //判断是否数组
  public
    constructor Create(AOWner: TComponent); override;
    destructor  Destroy();override;
    function Parser(const Express: string):TExpressNode;
    procedure SplitWords(Express:string);
    property WordsList:TStringStack Read FWordsList;
    property Operators:TStringStack Read FOperators;
    property OperatorBuilder:TOperatorBuilder read FOptBuilder write FOptBuilder;
  end;


procedure ExpressError(const ErrorMessage: string; const chr: array of const);
implementation

procedure ExpressError(const ErrorMessage: string; const chr: array of const);
begin
  raise ExpressException.Create(Format(ErrorMessage, chr)) ;
end;

{ TLikeNode }

procedure TLikeNode.ProcLike;
var
  strVal1,StrVal2:string;
begin
  StrVal1 :=Param[0].Value;
  strVal2 :=Param[1].Value;
  if FLikeType=lEqual then
  begin
    FValue :=strVal1=StrVal2;
  end else
  if FLikeType=lLeftEqual then
  begin
    FValue := leftStr(StrVal1 ,Length(FLikeKey))= FLikeKey;
  end else
  if FLikeType=lRightEqual then
  begin
    FValue :=RightStr(StrVal1,Length(FLikeKey))=FLikeKey;
  end else
  if FLiketype=lFind then
  begin
    FValue :=Pos(FLiKeKey,strVal1)>0;
  end;
end;

procedure TLikeNode.Process;

begin
  ProcParams();
  ProcLike();
end;

{ TOperatorBuilder }

function TOperatorBuilder.BuildEuql: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oEqual;
end;

function TOperatorBuilder.BuildNotEqual: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:= oNotEqual;
end;

function TOperatorBuilder.BuildGreaterThan: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oGreaterThan;
end;

function TOperatorBuilder.BuildLessThan: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oLessThan;
end;

function TOperatorBuilder.BuildLike(Symbol, Expr: TExpressNode): TExpressNode;
var
  likeExpr:string;
  likeNode:TLikeNode;
begin
  LikeNode :=TLikeNode.Create(FExpNodes);
  LikeNode.AddParam(Symbol);
  LikeNode.AddParam(Expr);
  LikeNode.OperatorType:= oLike;
  LikeExpr :=expr.Value;
  if  (LikeExpr[High(LikeExpr)]='%') and (LikeExpr[LOW(LikeExpr)]='%') then
  begin
    likeNode.FLikeType:=lFind;
  end else
  if Pos('%', LikeExpr)<=0 then
  begin
    LikeNode.FLikeType:=lEqual;
  end else
  if LikeExpr[High(LikeExpr)]='%' then
  begin
    LikeNode.FLikeType:=lLeftEqual;
  end else
  if LikeExpr[1]='%' then
  begin
    LikeNode.FLikeType:= lRightEqual;
  end;
  LikeNode.FLikeKey:=replacestr( LikeExpr,'%','');
  result := LikeNode;
end;

function TOperatorBuilder.BuildGreaterThanOrEqual: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oGreaterThanOrEqual;
end;

function TOperatorBuilder.BuildLessThanOrEqual: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:= oLessThanOrEqual;

end;

function TOperatorBuilder.BuildIn: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oIn;
end;

function TOperatorBuilder.BuildAnd: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:= oAnd;
end;

function TOperatorBuilder.BuildOr: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:= oOr;
end;

function TOperatorBuilder.BuildNot: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType :=oNot;
end;

function TOperatorBuilder.BuildBoolean(Bln: Boolean): TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.Value:=Bln;
  result.OperatorType:= oSymbol;
end;

function TOperatorBuilder.BuildPlus: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oPlus;
end;

function TOperatorBuilder.BuildSub: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oSub;
end;

function TOperatorBuilder.BuildMul: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oMul;
end;

function TOperatorBuilder.BuildDiv: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oDiv;
end;

function TOperatorBuilder.BuildMinus: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.OperatorType:=oMinus;
end;

function TOperatorBuilder.BuildNullSymbol: TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.Value:= Null();
  result.OperatorType:=oNull;
end;

function TOperatorBuilder.BuildIntegerSymbol(Value: Integer): TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.Value:= Value;
  result.OperatorType:=oSymbol;
end;

function TOperatorBuilder.BuildStringSymbol(str: string): TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.Value:=str;
  result.OperatorType:=oStringSymbol;
end;

function TOperatorBuilder.BuildFloatSymbol(Value: double): TExpressNode;
begin
  result :=TExpressNode.Create(FExpNodes);
  result.Value:=Value;
  result.OperatorType:=oSymbol;
end;

function TOperatorBuilder.BuildArraySymbol(Arr: string): TExpressNode;
begin
//
end;



constructor TOperatorBuilder.Create(AOwner: TComponent);
begin
  inherited;
  FExpNodes :=TExpressNodes.Create(TExpressNode);
end;

destructor TOperatorBuilder.Destroy;
begin
  FreeAndnil(FExpNodes);
  inherited;
end;

{ TExpressNode }




function TExpressNode.IsNumber(str: string): boolean;
var
  I:integer;
  cnt,dotCnt:integer;
begin
  cnt :=0;
  for I := Low(Str) to High(str) do
  begin
    if str[I] in ['0'..'9'] then
    begin
      inc(Cnt);
    end else
    begin
      inc(DotCnt);
    end;
  end;
  if ((cnt+dotcnt)=length(str)) and (dotcnt=1) then
    result :=true
  else
    result :=false;

end;

procedure TExpressNode.ProcEqual;
var
  Param1,param2:TExpressNode;
  Value1,Value2:variant;
  Vtype1,VType2:integer;
begin
  Param1 :=Param[0];
  Param2 :=Param[1];
  Value1 :=param1.Value;
  Value2 :=Param2.Value;
  VType1 :=VarType(Value1);
  Vtype2 :=VarType(Value2);
  if variants.VarType(Value2) in [varBoolean] then
  begin
    FValue := Param1.AsBoolean = Param2.AsBoolean;
  end
  else if ((VType1) in [varDouble, varSingle, varCurrency]) and
  ((Vtype2) in [vardouble, varSingle, varCurrency]) then
  begin
    FValue := FloatEquals(Value1, Value2);
  end
  else
  begin
    Fvalue := Value1 = Value2;

  end;
end;

procedure TExpressNode.ProcGreaterThan;
var
  Param1,Param2:TExpressNode;
begin
  FValue :=Param[0].Value>Param[1].Value;
end;

procedure TExpressNode.ProcLessThan;
begin
  FValue :=Param[0].Value<Param[1].Value;
end;

procedure TExpressNode.ProcGreaterThanOrEqual;
begin
  FValue :=param[0].Value>=Param[1].Value;
end;

procedure TExpressNode.ProcLessThanOrEqual;
begin
  FValue :=Param[0].Value<=Param[1].Value;
end;

procedure TExpressNode.procNotEqual;
begin
  FValue :=Param[0].Value<>Param[1].Value;
end;

procedure TExpressNode.procAnd();
begin
  FValue :=Param[0].Value And Param[1].Value;
end;

procedure TExpressNode.procOr;
begin
  FValue :=Param[0].Value OR Param[1].Value;
end;

procedure TExpressNode.procNot;
begin
  FValue :=Not Param[0].Value ;
end;

function TExpressNode.GetParam(aIndex: integer): TExpressNode;
begin
  result :=TObject(Fparams[aIndex]) as TExpressNode;
end;

procedure TExpressNode.ProcParams();
var
  I:integer;
  PtInfo:PTypeInfo;
  ParamNode:TExpressNode;
begin
  for i := 0 to FParams.Count-1 do
  begin
    ParamNode :=Param[I];
    ParamNode.Process();
    {$IFOpt D+}
      //SendInteger('ParamCount:',fparams.Count);
      //PtInfo :=GetPropinfo(ParamNode,'OperatorType')^.PropType;
      //dbugintf.SendDebug('operatorType:'+GetEnumName(PtInfo,Integer(paramNode.operatorType)));
    {$ENDIF}
  end;

end;

function TExpressNode.FloatEquals(Value1, Value2: Extended): Boolean;
begin
  result := Abs(Value1 - Value2) < 0.000000000001;
end;








procedure TExpressNode.AddParam(Param: TExpressNode);
begin
  FParams.Add(Param);
end;

function TExpressNode.IsTrue: boolean;
begin
  //
end;

constructor TExpressNode.Create(ACollection: Tcollection);
begin
  inherited;
  FParams :=TList.Create;
end;

destructor TExpressNode.Destroy;
begin
  FreeAndnil(FParams);
  inherited;
end;

procedure TExpressNode.Process;
begin
  //
  ProcParams();
  case FOperatorType of
    oSymbol:
      begin

      end;
    oEqual: ProcEqual();

    oGreaterThan: ProcGreaterThan();
    oLessThan: ProcLessThan();
    oGreaterThanOrEqual: ProcGreaterThanOrEqual();
    oLessThanOrEqual: ProcLessThanOrEqual();
    oNotEqual: procNotEqual();
    oAnd : procAnd();
    oOr: procOr();
    oNot: procNot();
  end;
end;

function TExpressNode.AsBoolean: Boolean;
var
  VType:Dword;
begin
  VType :=VarType(FValue);
  if VType=varBoolean then
  begin
    result :=FValue;
  end else
  if VType in [varDouble,varSingle,varCurrency,
  {$IFDEF  FPC}
  vardecimal,
  {$ENDIF}
  varbyte,varshortint,varinteger,varint64] then
  begin
    if FValue>0 then
      result :=true
    else
      result :=false;
  end else
  if (VType=varstring) or (VType=varustring) then
  begin
    if FValue<>'' then
       result :=true
    else
      result :=false;
  end else
  begin
    result :=false;
  end;
end;

function TExpressNode.AsString: string;
var
  VType:DWord;
begin
  VType :=VarType(FValue);
  if (VType =varstring) or (Vtype=varustring) then
  begin
    result :=FValue;
  end else
  if VType in [varbyte,varshortint,varinteger,varint64] then
  begin
    result :=InttoStr(FValue);
  end;
end;

function TExpressNode.AsInteger: int64;
var
  VType:integer;
  cur:double;
begin
  //
  VType :=VarType(FValue);
  if VType in [varinteger,varint64,varbyte,varsmallint] then
  begin
    result :=FValue;
  end else
  if VType in [varCurrency,varDouble,varSingle
  {$IFDEF FPC}
  ,vardecimal
  {$ENDIF}
  ]
   then
  begin
    Cur :=FValue;
    result :=Round(Cur);
  end else
  if ((VType=varstring) or (Vtype=varustring)) and isnumber(FValue) then
  begin
    result :=strToint(FValue);
  end else
  begin
    FillChar(result,Sizeof(result),$FF);
  end;
end;

{ TStringStack }

procedure TStringStack.DeletePop;
begin
  Delete(self.Count - 1);
end;

function TStringStack.PeekItem: string;
begin
  Result := self.Strings[self.Count - 1];
end;

function TStringStack.Pop: string;
begin
  Result := PeekItem;
  Delete(self.Count - 1);
end;

procedure TStringStack.Push(str: string);
begin
  self.Add(str);
end;



{ TExpressParser }

procedure TExpressParser.SplitWords(Express: string);
var
  P: PEChar;
  SyName: string;
  str: string;
  IsOperator: boolean;
begin
  FExpress :=Express;
  FSourcePtr := @Fexpress[1];
  P :=FSourcePtr;
  IsOperator := True;
  while (P <> nil) and (P^ <> #0) do
  begin
    ProcInvisibleChar(P);
    //ProcComment(P);
    ProcInvisibleChar(P);
    // Variable VariableSet
    if MatchString(P, '+') then
    begin
      Inc(P, 1);
      IsOperator := True;
      ProcessOperator('+');
      Continue;
    end
    else
    if MatchString(P, '-') then
    begin
      // is sub
      Inc(P, 1);
      if not IsOperator then
      begin
        // is sub
        ProcessOperator('-');
      end
      else
      begin
        // is minus
        ProcessOperator('Minus');
      end;
      Continue;
    end
    else
    if MatchString(P, '*') then
    begin
      Inc(P, 1);
      IsOperator := True;
      ProcessOperator('*');
      Continue;
    end
    else
    if MatchString(P, '/') then
    begin
      Inc(P, 1);
      IsOperator := True;
      ProcessOperator('/');
      Continue;
    end
    else
    if MatchString(P, 'not ') or MatchString(P, 'not(') then
    begin

      Inc(P, 3);
      IsOperator := True;
      ProcessOperator('not');
      Continue;
    end
    else
    if MatchString(P, 'and ') or MatchString(P, 'and(') then
    begin
      Inc(P, 3);
      IsOperator := True;
      ProcessOperator('and');
      Continue;
    end
    else
    if MatchString(P, 'or ') or MatchString(P, 'or(') then
    begin
      Inc(P, 2);
      IsOperator := True;
      ProcessOperator('or');
      Continue;
    end
    else
    if MatchString(P,'Like ') or MatchString(P,'Like "') then
    begin
      inc(P,4);
      IsOperator :=true;
      Processoperator('Like');
      Continue;
    end;
    if P^ = '(' then
    begin
      Inc(P);
      IsOperator := True;
      ProcessOperator('(');
      Continue;
    end
    else
    if P^ = ')' then
    begin
      Inc(P);
      IsOperator := True;
      ProcessOperator(')');
      Continue;
    end
    else
    if MatchString(P, '>=') then
    begin
      Inc(P, 2);
      IsOperator := True;
      ProcessOperator('>=');
      Continue;
    end
    else
    if MatchString(P, '<=') then
    begin
      Inc(P, 2);
      IsOperator := True;
      ProcessOperator('<=');
      Continue;
    end
    else
    if MatchString(P, '<>') then
    begin
      Inc(P, 2);
      IsOperator := True;
      ProcessOperator('<>');
      Continue;
    end
    else
    if P^ = '<' then
    begin
      Inc(P);
      IsOperator := True;
      ProcessOperator('<');
      Continue;
    end else
    if P^ = '>' then
    begin
      Inc(P);
      IsOperator := True;
      ProcessOperator('>');
      Continue;
    end else
    if MatchString(P, ':=') then
    begin
      Inc(P, 2);
      IsOperator := True;
      ProcessOperator(':=');
      Continue;
    end else
    if MatchString(P, '=') then
    begin
      Inc(P);
      IsOperator := True;
      ProcessOperator('=');
      Continue;
    end else
    if (MatchString(P, 'In ')) or (MatchString(P, 'In(')) then
    begin
      IsOperator := True;
      ProcInArray(P);
      Continue;
    end else
    if matchString(P,'like "') then
    begin
      // proc Like;
    end
    else
    if MatchString(P, '"') then
    begin
      IsOperator := False;
      ProcString(P, str);
      FWordsList.Push(str);
      Continue;
    end
    else
    if MatchString(P, 'Null ') then
    begin
      IsOperator := True;
      Inc(P, 4);
      FWordsList.Push('Null');
      Continue;
    end
    else
    if GetConst(P, SyName) then
    begin
      IsOperator := False;
      FWordsList.Push(SyName);
      Continue;
    end
    else
    if ProcSymbol(P, SyName) then
    begin
      IsOperator := False;
      FWordsList.Push(SyName);
      Continue;
    end
    else
    if (P^ = #13) and (P[1] = #10) then
    begin
      Inc(P, 2);
      Continue;
    end
    else
    if P^ = #0 then
    begin
      Break;
    end
    else
    begin
      ExpressError('Invalid Express:"%s"', [P]);
    end;
  end;


  while FOperators.Count > 0 do
  begin
    str := FOperators.Pop;
    FWordsList.Push(str);
  end;

end;

function TExpressParser.GetOperatorLevel(ExpressOperator: string): Integer;
begin
  // 逻辑符号 AND OR NOT   1
    // 比较符号: > >= < <= = 2  In
    if sameText(ExpressOperator, ':=')  then
    begin
      result := 0;
    end else
    if sameText(ExpressOperator, 'And') then
    begin
      Result := 1
    end else
    if sameText(ExpressOperator, 'Or') then
    begin
      Result := 1;
    end else
    if sameText(ExpressOperator, 'Not')  then
    begin
      result := 1;
    end else
    if sameText(ExpressOperator,'like') then
    begin
      result :=2;
    end
    else if sameText(ExpressOperator, '>') then
    begin
      result := 2;
    end else
    if sameText(ExpressOperator, '>=') then
    begin
      result := 2;
    end
    else if sameText(ExpressOperator, '<') then
    begin
      result := 2;
    end else
    if sameText(ExpressOperator, '<=')  then
    begin
      Result := 2;
    end else
    if sameText(ExpressOperator, '=') then
    begin
      result := 2;
    end else
    if sameText(ExpressOperator, 'In')  then
    begin
      result := 2;
    end else
    if sameText(ExpressOperator, '+')  then
    begin
      result := 3;
    end else
    if sameText(ExpressOperator, '-') then
    begin
      result := 3;
    end else
    if sameText(ExpressOperator, '*')  then
    begin
      result := 4;
    end else
    if sameText(ExpressOperator, '/') then
    begin
      result := 4;
    end  else
    if sameText(ExpressOperator, 'Minus') then
    begin
      Result := 5;
    end
    else
    begin
      ExpressError('Express Operator Error :%s', [ExpressOperator]);
    end;

end;

function TExpressParser.GetConst(var P: PEChar; var Value: string): Boolean;
var
  S:PEChar;
begin
  Result :=false ;
  if P^ in ['0'..'9'] then
  begin
    S :=P;
    Inc(P);
    skip(P,['0'..'9']);
    if P^='.' then
    begin
      Inc(P);
      SKIP(P,['0'..'9']);


    end;
    SetString(Value,S,P-S);
    Result :=true;
  end else
  if P^='.' then
  begin
    S :=P;
    Inc(P);
    SKIP(P,['0'..'9']);
    SetString(Value,S,P-S);
    Result :=true;
  end;

end;

function TExpressParser.ProcSymbol(var P: PEChar; var syName: string): Boolean;
var
  PVarS:PEChar;
begin
  if (P^ in SYMBOLCHARSET) or (P^>=#$100) then
  begin
    PVarS :=P;
    SKIP(P,SYMBOLCHARSET);
    SetString(SyName,PVars,P-PVars);
    result :=true;
  end else
  begin
    result :=false;
  end;

end;

function TExpressParser.ProcString(var P: PEChar; var strName: string): Boolean;
var
  PVarS:PEChar;
begin
  case P^ of
      '"':
    begin
      PVarS :=P;
      Inc(P);
      while P^<>#0 do
      begin
        if (P^ = '"') then
        begin

          Break;
        end;
        Inc(P)
      end;
      if P^=#0 then  ExpressError('Epxress Error %',[strName]);
      SetString(strName, PVarS, P - PVarS+1);
      Inc(P);
      Result :=true;
    end;
  else
    result :=false;
  end;

end;

function TExpressParser.ProcInArray(var PChr: PEChar): Boolean;
var
  InArr:TInArray;
  PS,PE:PEChar;
  P,PValStart:PEChar;
  str:string;
begin
  //
  P := PChr;
  if MatchString(PChr,'In ') or MatchString(PChr,'in (')  then
  begin
    SKIP(P,['i','n',' ','(']);
    PS :=P;
  while True do
  begin
    PValStart :=P;
    SKIP(P,['0'..'9']);
    SetString(str,PValStart,P-Pvalstart);
    if not IsInteger(str) then
    begin
      ExpressError('Express Error In grama error',[FSourcePtr^]);
    end;
    if P^=')' then
    begin
      PE :=P;
      SetString(str,PS,Pe-ps);
      FWordsList.Push(Trim(str));
      FWordsList.Push('In');
      Inc(p);
      PChr :=P;
      exit;
    end else
    if P^= #0 then
    begin
      ExpressError('In (XXXX) is not close',[]);
    end;
    SKIP(P,[',']);
  end;
  end else
  begin
    result :=false;
  end;

end;

procedure TExpressParser.SKIP(var P: PEChar; ChrSet: CharSet);
begin
  while TRUE do
   begin
     if (P^ >= #$100) or (P^ in ChrSet) then
       Inc(P)
     else
       Exit;
   end;
end;

procedure TExpressParser.ProcInvisibleChar(var PChr: PEChar);
var
  P: PEChar;
begin
  P := PChr;
  while (P^ <> #0) and (P^ <= ' ') and (P^ <> #13) and (P^ <> #10) do
    Inc(P);
  PChr := P;

end;

function TExpressParser.MatchString(Pchr: PEChar; KeyWord: string): boolean;
var
  strBuf: string;
  Len: integer;
begin
  Len := Length(KeyWord);
  SetString(strBuf, Pchr, Len);
  Result := CompareText(strBuf, KeyWord) = 0;
end;

procedure TExpressParser.ProcessOperator(strOperator: string);
var
  str: string;
  strOperator2: string;
  Level1, Level2: integer;
begin
  if strOperator = '(' then
  begin
    FOperators.Push(strOperator)
  end
  else if strOperator = ')' then
  begin
    while FOperators.PeekItem <> '(' do
    begin
      str := FOperators.Pop;
      FWordsList.Push(str);
      if FOperators.Count = 0 then
      begin
        ExpressError('Express  Error :', [FSourcePtr^]);
      end;
    end;
    FOperators.DeletePop;
  end
  else
  begin
    if FOperators.Count = 0 then
    begin
      FOperators.Push(strOperator);
    end
    else
    begin

      while (FOperators.Count > 0) do
      begin
        strOperator2 := FOperators.PeekItem;

        if strOperator2 = '(' then
        begin
          FOperators.Push(strOperator);
          Break;
        end
        else
        begin
          Level1 := GetOperatorLevel(strOperator);
          Level2 := GetOperatorLevel(strOperator2);
          if Level2 >= Level1 then
          begin
            strOperator2 := FOperators.Pop;
            FWordsList.Push(strOperator2);
            if FOperators.Count = 0 then
            begin
              FOperators.Push(strOperator);
              Break;
            end;

          end
          else
          begin
            //
            FOperators.Push(strOperator);
            Break;
          end;
        end;

      end;
    end;

  end;

end;

function TExpressParser.IsInteger(const str: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(str) do
  begin
    if not  (str[I] in ['0'..'9']) then
    begin
      result :=False;
      exit;
    end;
  end;
  result :=true;
end;

function TExpressParser.IsFloat(const str: string): Boolean;
var
  I: Integer;
  NumCount,DotCount:integer;
begin
  NumCount :=0;
  DotCount :=0;
  for I := 1 to Length(str) do
  begin
    if   (str[I] in ['0'..'9']) then
    begin
      Inc(NumCount);

    end;
    if str[I]='.' then
    begin
      Inc(DotCount);
    end;

  end;
  if((NumCount+DotCount)=Length(str)) and (DotCount=1) then
  begin
    result :=true;
  end else
  begin
    Result :=false;
  end;

end;

function TExpressParser.ParserKeywords: TExpressNode;
var
  I:integer;
  KeyWord:string;
  strKey:string;
  Node:TExpressNode;
  Opt:TExpressNode;
  Param1,Param2,Param3:TExpressNode;
  cnt:integer;
begin
  try
  for I := 0 to FWordsList.Count-1 do
  begin
    strKey :=FWordsList.Strings[I];
    if strKey='*' then
    begin
      opt :=FOptBuilder.BuildMul;
      Param2 :=FObjstack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(Opt);
    end else
    if strKey='/' then
    begin
      opt :=FOptBuilder.BuildDiv;
      Param2 :=FObjstack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(Opt);
    end else
    if strkey='+' then
    begin
      opt :=FOptBuilder.BuildPlus;

      Param2 :=FObjstack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(Opt);
    end else
    if strkey='-' then
    begin
      opt :=FOptBuilder.BuildSub;
      Param2 :=FObjstack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(Opt);
    end else
    if strKey='=' then
    begin
      Opt :=FOptBuilder.BuildEuql;
      Param2 := FObjStack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;

      opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if strKey='>' then
    begin
      opt :=FOptBuilder.BuildGreaterThan;
      param2 :=fobjstack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;
      opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if strKey='>=' then
    begin
      opt :=FOptBuilder.BuildGreaterThanOrEqual;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if strkey='<' then
    begin
      opt :=FOptBuilder.BuildLessThan;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;
      opt.AddParam(Param1);
      opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if strkey='<=' then
    begin
      opt :=FOptBuilder.BuildLessThanOrEqual;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;
      opt.AddParam(Param1);
      opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if strkey='<>' then
    begin
      Opt :=FOptBuilder.BuildNotEqual;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;
      opt.AddParam(Param1);
      Opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if sameText(strkey,'In') then
    begin
      opt :=FOptBuilder.BuildIn;
      Param2 :=FObjstack.Pop as TExpressNode;
      Param1 :=FObjstack.Pop as TExpressNode;
      opt.AddParam(Param1);
      opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if sameText(strKey,'And') then
    begin
      opt :=FOptBuilder.BuildAnd;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      opt.AddParam(Param1);
      opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if SameText(strKey,'Or') then
    begin
      opt :=FOptbuilder.BuildOR;
      Param2 :=FObjStack.Pop as TExpressNode;
      Param1 :=FObjStack.Pop as TExpressNode;
      opt.AddParam(Param1);
      opt.AddParam(Param2);
      FObjStack.Push(opt);
    end else
    if SameText(strKey,'Not') then
    begin
      opt :=FOptBuilder.BuildNot;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      FObjStack.Push(opt);
    end else
    if sameText(strkey,'true') then
    begin
      Node :=FOptBuilder.BuildBoolean(True);
      FObjStack.Push(Node);
    end else
    if SameText(strKey,'false') then
    begin
      Node :=FOptBuilder.BuildBoolean(false);
      FObjStack.Push(Node);
    end else
    if sameText(strKey,'Null') then
    begin
      Node :=FOptBuilder.BuildNullSymbol;
      FObjStack.Push(Node);
    end else
    if strKey='Minus' then
    begin
      opt :=FOptBuilder.BuildMinus;
      Param1 :=FObjStack.Pop as TExpressNode;
      Opt.AddParam(Param1);
      FObjStack.Push(opt);
    end else
    if SameText(strKey,'like') then
    begin

      Param1 :=FobjStack.Pop as TExpressNode;
      Param2 :=FobjStack.Pop as TExpressNode;
      if (param2.FOperatorType=oVar) and (Param1.FOperatorType=oStringSymbol) then
      begin
        opt :=FOptBuilder.BuildLike(Param2,Param1);
        FObjStack.Push(Opt);
      end else
      begin
        raise Exception.Create('Error'); //like express error;
      end;
    end else
    if IsString(strKey) then
    begin
      Node :=FOptBuilder.BuildStringSymbol(GetString(strKey));
      FObjStack.Push(Node);
    end else
    if IsInteger(strkey) then
    begin
      Node :=FOptBuilder.BuildIntegerSymbol(StrToInt(strkey));
      FObjStack.Push(Node);
    end else
    if IsFloat(strKey) then
    begin
      Node :=FOptBuilder.BuildFloatSymbol(StrToFloat(strKey));
      FObjStack.Push(Node);
    end else
    if IsArray(strkey) then
    begin
      Node :=FOptbuilder.BuildArraySymbol(strKey);
      FObjStack.Push(Node);
    end else
    if IsSymbol(strKey) then
    begin
      Node :=FOptBuilder.BuildVariable(strKey);
      Node.OperatorType:= oVar;
      //Add Variable List
      FObjStack.Push(Node);
    end else
    begin
      ExpressError('Express KeyWord Error:%s',[strkey]);
    end;

  end;
  if FObjStack.Count =1 then
  begin
    result :=Fobjstack.Pop as TExpressNode;
  end else
  begin
    ExpressError('express error :%s',[fexpress]);
  end;
  except
    on E:Exception do
    begin
      ExpressError('Express KeyWord Error:%s',[strkey]);
    end;
  end;
  //
end;

function TExpressParser.IsString(strkey: string): boolean;
begin
  if (Length(strkey) > 0) and (strkey[1] = '"') and (strkey[Length(strkey)] = '"') then
  begin
    result := true;
  end
  else
  begin
    result := false;
  end;
end;

function TExpressParser.GetString(strKey: string): string;
begin
  if (strkey[Low(strkey)]='"') and (strKey[High(strkey)]='"') then
  begin
    result := Copy(strKey, 2, Length(strKey) - 2);
  end else
  begin
    result :='';
    ExpressError('string symbol is error:%s',[strkey]);
  end;
end;

function TExpressParser.IsSymbol(const str: string): Boolean;
var
  I: Integer;
begin
  if Length(str) = 0 then
  begin
    ExpressError('Invalid Symbol %s',[str]);
  end;
  for I := 1 to Length(str) do
  begin
    if not ((str[I] in SYMBOLCHARSET) or (str[I] >= #$100)) then
    begin
      result := false;
      ExpressError('Invalid Symbol %s',[str]);
    end;
  end;
  result := true;

end;

function TExpressParser.IsArray(strkey: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(strkey) do
  begin
    if not (strkey[I] in ['0'..'9', ',']) then
    begin
      result := False;
      exit;
    end;
  end;
  Result := true;

end;



constructor TExpressParser.Create(AOWner: TComponent);
begin
  inherited;
  FWordsList := TStringStack.Create;
  FOperators := TStringStack.Create;
  FObjStack := TObjectStack.Create;
end;

destructor TExpressParser.Destroy;
begin
  FreeAndnil(FObjStack);
  FreeAndNil(FOperators);
  FreeAndNil(FWordsList);
  inherited;

end;

function TExpressParser.Parser(const Express: string): TExpressNode;

begin
  if Trim(express) <> '' then
  begin
    FWordsList.Clear;
    FExpress := Express;
    SplitWords(Express);
    Result := ParserKeywords;

  end
  else
  begin
    FWordsList.Clear;
    FExpress := 'True';
    splitWords(Express);
    Result := ParserKeywords;
  end;

end;

end.
