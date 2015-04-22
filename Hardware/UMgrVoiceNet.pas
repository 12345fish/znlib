{*******************************************************************************
  ����: dmzn@163.com 2015-04-21
  ����: ����������ϳ�������Ԫ
*******************************************************************************}
unit UMgrVoiceNet;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, IdComponent, IdTCPConnection, IdGlobal,
  IdTCPClient, IdSocketHandle, NativeXml, UWaitItem, USysLoger;

const
  cVoice_CMD_Head       = $FD;         //֡ͷ
  cVoice_CMD_Play       = $01;         //����
  cVoice_CMD_Stop       = $02;         //ֹͣ
  cVoice_CMD_Pause      = $03;         //��ͣ
  cVoice_CMD_Resume     = $04;         //����
  cVoice_CMD_QStatus    = $21;         //��ѯ
  cVoice_CMD_StandBy    = $22;         //����
  cVoice_CMD_Wakeup     = $FF;         //����

  cVoice_Code_GB2312    = $00;
  cVoice_Code_GBK       = $01;
  cVoice_Code_BIG5      = $02;
  cVoice_Code_Unicode   = $03;         //����

  cVoice_FrameInterval  = 10;          //֡���
  cVoice_ContentLen     = 4096;        //�ı�����

type
  TVoiceWord = record
   FH: Byte;
   FL: Byte;
  end;

  PVoiceBase = ^TVoiceBase;
  TVoiceBase = record
    FHead     : Byte;                  //֡ͷ
    FLength   : TVoiceWord;            //���ݳ���
    FCommand  : Byte;                  //������
    FParam    : Byte;                  //�������
  end;

  PVoiceText = ^TVoiceText;
  TVoiceText = record
    FBase     : TVoiceBase;
    FContent  : array[0..cVoice_ContentLen-1] of Char;

    FUsed     : Boolean;               //ʹ�ñ��
    FVoiceLast: Int64;                 //�ϴβ���
    FVoiceTime: Byte;                  //��������
  end;

  PVoiceCard = ^TVoiceCard;
  TVoiceCard = record
    FID     : string;                  //����ʶ
    FName   : string;                  //������
    FHost   : string;                  //����ַ
    FPort   : Integer;                 //���˿�
    FEnable : Boolean;                 //�Ƿ�����
    FContent: TList;                   //��������
    FResource: TList;                  //��Դ����
    FBuffer : TList;                   //���ͻ���
  end;

  PVoiceContent = ^TVoiceContent;
  TVoiceContent = record
    FID       : string;                //���ݱ�ʶ
    FObject   : string;                //�����ʶ
    FSleep    : Integer;               //������
    FText     : string;                //��������
    FTimes    : Integer;               //�ط�����
    FInterval : Integer;               //�ط����
    FRepeat   : Integer;               //�����ظ�
    FReInterval: Integer;              //���μ��
  end;

  PVoiceResource = ^TVoiceResource;
  TVoiceResource = record
    FKey      : string;                //������
    FValue    : string;                //��������
  end;

type
  TVoiceManager = class;
  TVoiceConnector = class(TThread)
  private
    FOwner: TVoiceManager;
    //ӵ����
    FBuffer: TList;
    //���ͻ���
    FWaiter: TWaitObject;
    //�ȴ�����
    FClient: TIdTCPClient;
    //�������
  protected
    procedure DoExuecte(const nCard: PVoiceCard);
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TVoiceManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TVoiceManager = class(TObject)
  private
    FCards: TList;
    //�������б�
    FDataPool: TList;
    //���ݻ���
    FVoicer: TVoiceConnector;
    //��������
    FSyncLock: TCriticalSection;
    //ͬ����
  protected
    procedure ClearBuffer(const nList: TList);
    //������
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ȡ����
    procedure StartVoice;
    procedure StopVoice;
    //��ͣ��ȡ
    procedure PlayVoice(const nText: string; const nCard: string = '';
      const nContent: string = '');
    //��������
  end;

var
  gNetVoiceHelper: TVoiceManager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TVoiceManager, '����ϳ�����', nEvent);
end;

constructor TVoiceManager.Create;
begin

end;

destructor TVoiceManager.Destroy;
begin

  inherited;
end;

procedure TVoiceManager.ClearBuffer(const nList: TList);
begin

end;

procedure TVoiceManager.StartVoice;
begin

end;

procedure TVoiceManager.StopVoice;
begin

end;

procedure TVoiceManager.PlayVoice(const nText, nCard, nContent: string);
begin

end;

procedure TVoiceManager.LoadConfig(const nFile: string);
begin

end;

//------------------------------------------------------------------------------
constructor TVoiceConnector.Create(AOwner: TVoiceManager);
begin

end;

destructor TVoiceConnector.Destroy;
begin

  inherited;
end;

procedure TVoiceConnector.WakupMe;
begin

end;

procedure TVoiceConnector.StopMe;
begin

end;

procedure TVoiceConnector.DoExuecte(const nCard: PVoiceCard);
begin

end;

procedure TVoiceConnector.Execute;
begin
  inherited;

end;

end.
