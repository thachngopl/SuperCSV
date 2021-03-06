unit frm_filter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, KButtons, Forms, Controls, Graphics, Dialogs,
  StdCtrls, csvengine;

type

  { TfrmFilter }

  TfrmFilter = class(TForm)
    combOperator: TComboBox;
    memExpress: TMemo;
    txtValue: TEdit;

    btnAnd: TButton;
    btnLeftBracket: TButton;
    btnRightBracket: TButton;
    btnOR: TButton;
    btnNOT: TButton;
    Button1: TButton;
    Button2: TButton;
    btnAdd: TButton;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    VarList: TListBox;
    Memo1: TMemo;
    procedure btnAddClick(Sender: TObject);
    procedure btnLeftBracketClick(Sender: TObject);
    procedure btnNOTClick(Sender: TObject);
    procedure btnORClick(Sender: TObject);
    procedure btnRightBracketClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure memExpressChange(Sender: TObject);
    function AddCondition(condition,VariableName,Value:string):string;
    procedure btnAndClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GetVariableList(CsvEngine:TCSVEngine);
    procedure ToggleBox1Change(Sender: TObject);

  private
    FOK:boolean;
    FExpress:string;
    FEngine:TCSVEngine;
    function GetExpress: string;
    procedure SetExpress(AValue: string);
  public
    property Express:string read GetExpress write SetExpress;
    property OK:Boolean read FOK write FOK;
    procedure SetFilterCondition(const Engine:TCSVEngine);
  end;

var
  frmFilter: TfrmFilter;

implementation

{$R *.lfm}

{ TfrmFilter }

procedure TfrmFilter.memExpressChange(Sender: TObject);
begin
  FExpress :=memExpress.Lines.Text;
end;

procedure TfrmFilter.btnAddClick(Sender: TObject);
var
  str:string;
begin
  if VArList.ItemIndex>=0 then
  begin
    if txtValue.Text<>'' then
    begin

      str :=AddCondition(combOperator.Text,VarList.Items[varList.ItemIndex],txtValue.Text);
      if str<>'' then
      begin
        Express :=Express +str;
      end;
    end;

  end;
end;

procedure TfrmFilter.btnLeftBracketClick(Sender: TObject);
begin
  Express :=Express +'(';
end;

procedure TfrmFilter.btnNOTClick(Sender: TObject);
begin
  Express :=Express+'NOT ';
end;

procedure TfrmFilter.btnORClick(Sender: TObject);
begin
  Express :=Express + ' OR ';
end;

procedure TfrmFilter.btnRightBracketClick(Sender: TObject);
begin
  Express :=Express+')';
end;

procedure TfrmFilter.Button1Click(Sender: TObject);
begin
  fok :=true;
  self.Close;
end;

procedure TfrmFilter.Button2Click(Sender: TObject);
begin
  fok :=false;
  self.Close;
end;





function TfrmFilter.GetExpress: string;
begin
  result :=FExpress;
end;

procedure TfrmFilter.SetExpress(AValue: string);
begin
  FExpress :=AValue;
  memExpress.Lines.Text:= AValue;

end;

procedure TfrmFilter.SetFilterCondition(const Engine: TCSVEngine);
begin
  Express:=Engine.Filter;
  FEngine :=Engine;
  GetVariableList(FEngine);
  self.ShowModal;

end;

function TfrmFilter.AddCondition(condition, VariableName, Value: string
  ): string;
begin
  if condition='=' then
  begin
    result :=VariableName +'='+ '"'+Value+'"';
  end else
  if condition ='contains' then
  begin
    result :=VariableName +' like "%'+Value+'%"';
  end else
  if condition ='left contains' then
  begin
    result :=VariableName +' like '+'"'+Value+'%"';
  end else
  if Condition ='right contains' then
  begin
    result :=VariableName +' like '+'"%'+Value+'"';
  end else
  if Condition ='>' then
  begin
    result :=VariableName +' > '+'"'+ Value+'"';
  end else
  if Condition ='<' then
  begin
    result :=VariableName +' < '+'"'+Value+'"';
  end else
  if Condition ='>=' then
  begin
    result :=VariableName +' >= '+'"'+ Value+'"';
  end else
  if Condition ='<=' then
  begin
    result :=VariableName +' <= '+'"'+ Value+'"';
  end;

end;

procedure TfrmFilter.btnAndClick(Sender: TObject);
begin
  Express :=Express + ' AND ';
end;

procedure TfrmFilter.FormCreate(Sender: TObject);
begin

end;

procedure TfrmFilter.GetVariableList(CsvEngine: TCSVEngine);
var
  I:integer;
begin
  for i := 0 to FEngine.ColCount-1 do
  begin
    VarList.additem(Fengine.ColumnName[I],nil);
  end;


end;

procedure TfrmFilter.ToggleBox1Change(Sender: TObject);
begin

end;

end.

