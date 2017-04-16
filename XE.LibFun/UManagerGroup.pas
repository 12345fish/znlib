{*******************************************************************************
  ����: dmzn@163.com 2017-03-23
  ����: ͳһ������ֹ�������ȫ�ֱ���
*******************************************************************************}
unit UManagerGroup;

interface

uses
  System.Rtti, UBaseObject, UObjectPool, UMemDataPool;

type
  PManagerGroup = ^TManagerGroup;
  TManagerGroup = record
  public
    FSerialIDManager: TSerialIDManager;
    //��Ź�����
    FObjectManager: TCommonObjectManager;
    //���������
    FObjectPool: TObjectPoolManager;
    //���󻺳��
    FMemDataManager: TMemDataManager;
    //�ڴ������  
  public
    procedure RegistAll(const nReg: Boolean);
    //ע������
  end;

var
  gMG: TManagerGroup;
  //ȫ��ʹ��
  
implementation

//Date: 2017-03-23
//Parm: �Ƿ�ע��
//Desc: ɨ��Group������Manager,����Manager��ע�᷽��.
procedure TManagerGroup.RegistAll(const nReg: Boolean);
var nCtx: TRttiContext;
    nType: TRttiType;
    nRF: TRttiField;
    nMethod: TRttiMethod;
    nInstance: TRttiInstanceType;
begin    
  nCtx := TRttiContext.Create;
  try
    nType := nCtx.GetType(TypeInfo(TManagerGroup));
    for nRF in nType.GetFields do
     if nRF.FieldType.TypeKind = tkClass then   
      begin
        nInstance := nRF.FieldType.AsInstance; 
        nMethod := nInstance.GetMethod('RegistMe');
        
        if Assigned(nMethod) then
          nMethod.Invoke(nInstance.MetaclassType, [TValue.From(nReg)]);
        //call function
      end;    
  finally
    nCtx.Free;
  end;
end;

initialization
  FillChar(gMG, SizeOf(TManagerGroup), #0);
  gMG.RegistAll(True);
finalization
  gMG.RegistAll(False);
end.
