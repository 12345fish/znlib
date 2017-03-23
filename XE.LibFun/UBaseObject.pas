{*******************************************************************************
  ����: dmzn@163.com 2017-03-21
  ����: ע�����ϵͳ���������״̬

  ��ע:
  *.TCommonObjectBase.DataS,DataP����,����ʱ��Ҫ��LockPropertyData����,�����
    �̶߳�дʱ��������.
*******************************************************************************}
unit UBaseObject;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs;

type
  TObjectBase = class(TObject)
  private
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
    procedure LockPropertyData;
    procedure UnlockProperty;
    //ͬ������    
  end;

  TManagerBase = class
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
  end;

  TCommonObjectManager = class(TManagerBase)
  private  
    FObjects: TList;
    //�����б�
    FSyncLock: TCriticalSection;
    //ͬ������
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

procedure TObjectBase.LockPropertyData;
begin
  if not Assigned(FSyncLock) then   
    FSyncLock := TCriticalSection.Create;
  FSyncLock.Enter;
end;

procedure TObjectBase.UnlockProperty;
begin
  if Assigned(FSyncLock) then
    FSyncLock.Leave;
  //xxxxx
end;

procedure TObjectBase.GetStatus(const nList: TStrings);
begin

end;

//------------------------------------------------------------------------------
procedure TManagerBase.GetStatus(const nList: TStrings);
var nLen: Integer;
begin
  nLen := Trunc((85 - Length(ClassName)) / 2);
  nList.Add(StringOfChar('+', nLen) + ' ' + ClassName + ' ' +
            StringOfChar('+', nLen));
  //title
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

//------------------------------------------------------------------------------
constructor TCommonObjectManager.Create;
begin
  FObjects := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TCommonObjectManager.Destroy;
begin
  FObjects.Free;
  FSyncLock.Free;
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
    FreeAndNil(FManagers[nIdx].FManager);
    gMG.FObjectManager := nil;
  end;
end;

procedure TCommonObjectManager.AddObject(const nObj: TObject);
begin
  if not (nObj is TObjectBase) then
    raise Exception.Create(ClassName + ': Object Is Not Support.');
  //xxxxx

  FSyncLock.Enter;
  FObjects.Add(nObj);
  FSyncLock.Leave;
end;

procedure TCommonObjectManager.DelObject(const nObj: TObject);
var nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    nIdx := FObjects.IndexOf(nObj);
    if nIdx > -1 then
      FObjects.Delete(nIdx);
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

procedure TCommonObjectManager.GetStatus(const nList: TStrings);
var nIdx,nLen: Integer;
begin
  FSyncLock.Enter;
  try
    for nIdx:=0 to FObjects.Count - 1 do
    with TObjectBase(FObjects[nIdx]) do
    begin
      if nIdx <> 0 then
        nList.Add('');
      //xxxxx

      nLen := Trunc((85 - Length(ClassName)) / 2);
      nList.Add(StringOfChar('+', nLen) + ' ' + ClassName + ' ' +
                StringOfChar('+', nLen));
      GetStatus(nList);
    end;
  finally
    FSyncLock.Leave;
  end;
end;

initialization
  //nothing
finalization
  TCommonObjectManager.RegistMe(False);
end.
