{*******************************************************************************
  ����: dmzn@163.com 2017-03-21
  ����: ע�����ϵͳ���������״̬

  ��ע:
  *.TObjectBase.DataS,DataP,Health����,����ʱ��Ҫ��SyncEnter����,������̲߳���
    ʱд������.
*******************************************************************************}
unit UBaseObject;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs, ULibFun;

type
  TObjectStatusHelper = class
  public  
    class procedure AddTitle(const nList: TStrings; const nClass: string);
    //��ӱ���   
    class function FixData(const nTitle: string;
      const nData: string): string; overload;
    class function FixData(const nTitle: string;
      const nData: Double): string; overload; 
    //��ʽ������    
  end;

  TObjectBase = class(TObject)
  strict private
    FSyncLock: TCriticalSection;
    //ͬ������
  public
    type
      TDataDim = 0..2;
      TDataS = array [TDataDim] of string;
      TDataP = array [TDataDim] of Pointer; 
      THealth = (hlHigh, hlNormal, hlLow, hlBad);
    var
      DataS: TDataS;
      DataP: TDataP;
      Health: THealth;
      //״̬����
            
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure GetStatus(const nList: TStrings); virtual;
    //����״̬
    procedure SyncEnter;
    procedure SyncLeave;
    //ͬ������    
  end;

  TManagerBase = class
  strict private
    FSyncLock: TCriticalSection;
    //ͬ������
  strict protected
    type
      TItem = record
        FClass: TClass;
        FManager: TObject;
      end;
    class var
      FManagers: array of TItem;
      //�������б�
  protected
    class function GetMe(const nClass: TClass): Integer;
    class procedure RegistMe(const nReg: Boolean = True); virtual; abstract;
    //ע�������  
    procedure GetStatus(const nList: TStrings); virtual;
    //����״̬
  public       
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure SyncEnter;
    procedure SyncLeave;
    //ͬ������ 
  end;

  TCommonObjectManager = class(TManagerBase)
  private  
    FObjects: TList;
    //�����б�
  public       
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    class procedure RegistMe(const nReg: Boolean); override;
    //ע�������
    procedure AddObject(const nObj: TObject);
    procedure DelObject(const nObj: TObject);
    //���ɾ��
    procedure GetStatus(const nList: TStrings); override;
    //��ȡ״̬
  end;

implementation

uses
  UManagerGroup;

//Date: 2017-04-14
//Parm: �б�;����
//Desc: ���һ����ı��⵽�б�
class procedure TObjectStatusHelper.AddTitle(const nList: TStrings;
  const nClass: string);
var nLen: Integer;
begin
  if nList.Count > 0 then     
      nList.Add('');
  //xxxxx
  
  nLen := Trunc((85 - Length(nClass)) / 2);
  nList.Add(StringOfChar('+', nLen) + ' ' + nClass + ' ' +
            StringOfChar('+', nLen));
  //title
end;

//Date: 2017-04-10
//Parm: ǰ׺����;����
//Desc: ��ʽ������,��ʽΪ: nTitle(����) nData
class function TObjectStatusHelper.FixData(const nTitle, nData: string): string;
begin
  Result := ULibFun.TStringHelper.FixWidth(nTitle, 32) + nData;
end;

class function TObjectStatusHelper.FixData(const nTitle: string;
  const nData: Double): string;
begin
  Result := FixData(nTitle, nData.ToString);
end;

//------------------------------------------------------------------------------
constructor TObjectBase.Create;
begin
  FSyncLock := nil;
  Health := hlNormal;
  
  if Assigned(gMG.FObjectManager) then
    gMG.FObjectManager.AddObject(Self);
  //xxxxx
end;

destructor TObjectBase.Destroy;
begin
  if Assigned(gMG.FObjectManager) then
    gMG.FObjectManager.DelObject(Self);
  //xxxxx
  
  FSyncLock.Free;
  inherited;
end;

procedure TObjectBase.SyncEnter;
begin
  if not Assigned(FSyncLock) then   
    FSyncLock := TCriticalSection.Create;
  FSyncLock.Enter;
end;

procedure TObjectBase.SyncLeave;
begin
  if Assigned(FSyncLock) then
    FSyncLock.Leave;
  //xxxxx
end;

//Desc: ��ӱ�����
procedure TObjectBase.GetStatus(const nList: TStrings);
begin
  TObjectStatusHelper.AddTitle(nList, ClassName);
end;

//------------------------------------------------------------------------------
constructor TManagerBase.Create;
begin
  inherited;
  FSyncLock := nil;
end;

destructor TManagerBase.Destroy;
begin
  FSyncLock.Free;
  inherited;
end;

procedure TManagerBase.SyncEnter;
begin
  if not Assigned(FSyncLock) then   
    FSyncLock := TCriticalSection.Create;
  FSyncLock.Enter;
end;

procedure TManagerBase.SyncLeave;
begin
  if Assigned(FSyncLock) then
    FSyncLock.Leave;
  //xxxxx
end;

//Date: 2017-03-23
//Parm: ���
//Desc: ����nClass�ڹ������б��е�λ��
class function TManagerBase.GetMe(const nClass: TClass): Integer;
var nIdx: Integer;
begin
  for nIdx := Low(FManagers) to High(FManagers) do
  if FManagers[nIdx].FClass = nClass then
  begin
    Result := nIdx;
    Exit;
  end;
    
  Result := Length(FManagers); 
  nIdx := Result; 
  SetLength(FManagers, nIdx + 1);

  with FManagers[nIdx] do
  begin
    FClass := nClass;
    FManager := nil;
  end;    
end;

//Desc: ��ӱ�����
procedure TManagerBase.GetStatus(const nList: TStrings);
begin
  TObjectStatusHelper.AddTitle(nList, ClassName);
end;

//------------------------------------------------------------------------------
constructor TCommonObjectManager.Create;
begin
  inherited;
  FObjects := TList.Create;
end;

destructor TCommonObjectManager.Destroy;
begin
  FObjects.Free;
  inherited;
end;

//Date: 2017-03-23
//Parm: �Ƿ�ע��
//Desc: ��ϵͳע�����������
class procedure TCommonObjectManager.RegistMe(const nReg: Boolean);
var nIdx: Integer;
begin
  nIdx := GetMe(TCommonObjectManager);
  if nReg then
  begin     
    if not Assigned(FManagers[nIdx].FManager) then
      FManagers[nIdx].FManager := TCommonObjectManager.Create;
    gMG.FObjectManager := FManagers[nIdx].FManager as TCommonObjectManager; 
  end else
  begin
    gMG.FObjectManager := nil;
    FreeAndNil(FManagers[nIdx].FManager);    
  end;
end;

procedure TCommonObjectManager.AddObject(const nObj: TObject);
begin
  if not (nObj is TObjectBase) then
    raise Exception.Create(ClassName + ': Object Is Not Support.');
  //xxxxx

  SyncEnter;
  FObjects.Add(nObj);
  SyncLeave;
end;

procedure TCommonObjectManager.DelObject(const nObj: TObject);
var nIdx: Integer;
begin
  SyncEnter;
  try
    nIdx := FObjects.IndexOf(nObj);
    if nIdx > -1 then
      FObjects.Delete(nIdx);
    //xxxxx
  finally
    SyncLeave;
  end;
end;

procedure TCommonObjectManager.GetStatus(const nList: TStrings);
var nIdx,nLen: Integer;
begin
  SyncEnter;
  try
    for nIdx:=0 to FObjects.Count - 1 do
    with TObjectBase(FObjects[nIdx]) do
    begin
      TObjectStatusHelper.AddTitle(nList, ClassName);
      GetStatus(nList);
    end;
  finally
    SyncLeave;
  end;
end;

initialization
  //nothing
finalization
  TCommonObjectManager.RegistMe(False);
end.
