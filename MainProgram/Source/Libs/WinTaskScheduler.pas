unit WinTaskScheduler;

interface

uses
  Windows;

{$MINENUMSIZE 4}

type
  PLPWSTR  = ^LPWSTR;
  PPLPWSTR = ^PLPWSTR;

  HPROPSHEETPAGE = THandle;
  PHPROPSHEETPAGE = ^HPROPSHEETPAGE;

  LPSYSTEMTIME = ^SYSTEMTIME;
  PLPSYSTEMTIME = ^LPSYSTEMTIME;

  PHRESULT = ^HRESULT;

  PPBYTE = ^PBYTE;

  REFIID   = ^TGUID;
  REFCLSID = ^TGUID;

  PIUnknown = ^IUnknown;


// mstask.h
const
  TASK_SUNDAY      = $1;
  TASK_MONDAY      = $2;
  TASK_TUESDAY     = $4;
  TASK_WEDNESDAY   = $8;
  TASK_THURSDAY    = $10;
  TASK_FRIDAY      = $20;
  TASK_SATURDAY    = $40;
  TASK_FIRST_WEEK  = 1;
  TASK_SECOND_WEEK = 2;
  TASK_THIRD_WEEK  = 3;
  TASK_FOURTH_WEEK = 4;
  TASK_LAST_WEEK   = 5;
  TASK_JANUARY     = $1;
  TASK_FEBRUARY    = $2;
  TASK_MARCH       = $4;
  TASK_APRIL       = $8;
  TASK_MAY         = $10;
  TASK_JUNE        = $20;
  TASK_JULY        = $40;
  TASK_AUGUST      = $80;
  TASK_SEPTEMBER   = $100;
  TASK_OCTOBER     = $200;
  TASK_NOVEMBER    = $400;
  TASK_DECEMBER    = $800;

  TASK_FLAG_INTERACTIVE                  = $1;
  TASK_FLAG_DELETE_WHEN_DONE             = $2;
  TASK_FLAG_DISABLED                     = $4;
  TASK_FLAG_START_ONLY_IF_IDLE           = $10;
  TASK_FLAG_KILL_ON_IDLE_END             = $20;
  TASK_FLAG_DONT_START_IF_ON_BATTERIES   = $40;
  TASK_FLAG_KILL_IF_GOING_ON_BATTERIES   = $80;
  TASK_FLAG_RUN_ONLY_IF_DOCKED           = $100;
  TASK_FLAG_HIDDEN                       = $200;
  TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET = $400;
  TASK_FLAG_RESTART_ON_IDLE_RESUME       = $800;
  TASK_FLAG_SYSTEM_REQUIRED              = $1000;
  TASK_FLAG_RUN_ONLY_IF_LOGGED_ON        = $2000;

  TASK_TRIGGER_FLAG_HAS_END_DATE         = $1;
  TASK_TRIGGER_FLAG_KILL_AT_DURATION_END = $2;
  TASK_TRIGGER_FLAG_DISABLED             = $4;

  TASK_MAX_RUN_TIMES = 1440;

type
  _TASK_TRIGGER_TYPE =(
    TASK_TIME_TRIGGER_ONCE,
    TASK_TIME_TRIGGER_DAILY,
    TASK_TIME_TRIGGER_WEEKLY,
    TASK_TIME_TRIGGER_MONTHLYDATE,
    TASK_TIME_TRIGGER_MONTHLYDOW,
    TASK_EVENT_TRIGGER_ON_IDLE,
    TASK_EVENT_TRIGGER_AT_SYSTEMSTART,
    TASK_EVENT_TRIGGER_AT_LOGON);
  TASK_TRIGGER_TYPE = _TASK_TRIGGER_TYPE;
  PTASK_TRIGGER_TYPE = ^TASK_TRIGGER_TYPE;

  _DAILY = record
    DaysInterval: WORD;
  end;
  DAILY = _DAILY;

  _WEEKLY = record
    WeeksInterval:    WORD;
    rgfDaysOfTheWeek: WORD;
  end;
  WEEKLY = _WEEKLY;

  _MONTHLYDATE = record
    rgfDays:    DWORD;
    rgfMonths:  WORD;
  end;
  MONTHLYDATE = _MONTHLYDATE;

  _MONTHLYDOW = record
    wWhichWeek:        WORD;
    rgfDaysOfTheWeek:  WORD;
    rgfMonths:         WORD;
  end;
  MONTHLYDOW = _MONTHLYDOW;

  _TRIGGER_TYPE_UNION = record
  case Integer of
    0: (Daily:        DAILY);
    1: (Weekly:       WEEKLY);
    2: (MonthlyDate:  MONTHLYDATE);
    3: (MonthlyDOW:   MONTHLYDOW);
  end;
  TRIGGER_TYPE_UNION = _TRIGGER_TYPE_UNION;

  _TASK_TRIGGER = record
    cbTriggerSize:          WORD;
    Reserved1:              WORD;
    wBeginYear:             WORD;
    wBeginMonth:            WORD;
    wBeginDay:              WORD;
    wEndYear:               WORD;
    wEndMonth:              WORD;
    wEndDay:                WORD;
    wStartHour:             WORD;
    wStartMinute:           WORD;
    MinutesDuration:        DWORD;
    MinutesInterval:        DWORD;
    rgFlags:                DWORD;
    TriggerType:            TASK_TRIGGER_TYPE;
    Type_:                  TRIGGER_TYPE_UNION; // "Type" is reserved word in pascal
    Reserved2:              WORD;
    wRandomMinutesInterval: WORD;
  end;
  TASK_TRIGGER = _TASK_TRIGGER;
  PTASK_TRIGGER = ^TASK_TRIGGER;

const
  IID_ITaskTrigger: TGUID = '{148BD52B-A2AB-11CE-B11F-00AA00530503}';

type
  PITaskTrigger = ^ITaskTrigger;
  ITaskTrigger = interface(IUnknown)
  ['{148BD52B-A2AB-11CE-B11F-00AA00530503}']
    Function SetTrigger(const pTrigger: PTASK_TRIGGER): HRESULT; stdcall;
    Function GetTrigger(pTrigger: PTASK_TRIGGER): HRESULT; stdcall;
    Function GetTriggerString(ppwszTrigger: PLPWSTR): HRESULT; stdcall;
  end;


const
  IID_IScheduledWorkItem: TGUID = '{a6b952f0-a4b1-11d0-997d-00aa006887ec}';

type
  IScheduledWorkItem = interface(IUnknown)
  ['{a6b952f0-a4b1-11d0-997d-00aa006887ec}']
    Function CreateTrigger(piNewTrigger: PWORD; ppTrigger: PITaskTrigger): HRESULT; stdcall;
    Function DeleteTrigger(iTrigger: WORD): HRESULT; stdcall;
    Function GetTriggerCount(plCount: PWORD): HRESULT; stdcall;
    Function GetTrigger(iTrigger: WORD; ppTrigger: PITaskTrigger): HRESULT; stdcall;
    Function GetTriggerString(iTrigger: WORD; ppwszTrigger: PLPWSTR): HRESULT; stdcall;
    Function GetRunTimes(pstBegin: LPSYSTEMTIME; pstEnd: LPSYSTEMTIME; pCount: PWORD; rgstTaskTimes: PLPSYSTEMTIME): HRESULT; stdcall;
    Function GetNextRunTime(pstNextRun: PSYSTEMTIME): HRESULT; stdcall;
    Function SetIdleWait(wIdleMinutes: WORD; wDeadlineMinutes: WORD): HRESULT; stdcall;
    Function GetIdleWait(pwIdleMinutes: PWORD; pwDeadlineMinutes: PWORD): HRESULT; stdcall;
    Function Run: HRESULT; stdcall;
    Function Terminate: HRESULT; stdcall;
    Function EditWorkItem(hParent: HWND; dwReserved: DWORD): HRESULT; stdcall;
    Function GetMostRecentRunTime(pstLastRun: PSYSTEMTIME): HRESULT; stdcall;
    Function GetStatus(phrStatus: PHRESULT): HRESULT; stdcall;
    Function GetExitCode(pdwExitCode: PDWORD): HRESULT; stdcall;
    Function SetComment(pwszComment: LPCWSTR): HRESULT; stdcall;
    Function GetComment(ppwszComment: PLPWSTR): HRESULT; stdcall;
    Function SetCreator(pwszCreator: LPCWSTR): HRESULT; stdcall;
    Function GetCreator(ppwszCreator: PLPWSTR): HRESULT; stdcall;
    Function SetWorkItemData(cBytes: WORD; rgbData: BYTE): HRESULT; stdcall;  // rgbData is actually and array of bytes
    Function GetWorkItemData(pcBytes: PWORD; ppBytes: PPBYTE): HRESULT; stdcall;
    Function SetErrorRetryCount(wRetryCount: WORD): HRESULT; stdcall;
    Function GetErrorRetryCount(pwRetryCount: PWORD): HRESULT; stdcall;
    Function SetErrorRetryInterval(wRetryInterval: WORD): HRESULT; stdcall;
    Function GetErrorRetryInterval(pwRetryInterval: PWORD): HRESULT; stdcall;
    Function SetFlags(dwFlags: DWORD): HRESULT; stdcall;
    Function GetFlags(pdwFlags: PDWORD): HRESULT; stdcall;
    Function SetAccountInformation(pwszAccountName: LPCWSTR;pwszPassword: LPCWSTR): HRESULT; stdcall;
    Function GetAccountInformation(ppwszAccountName: PLPWSTR): HRESULT; stdcall;
  end;


const
  IID_ITask: TGUID = '{148BD524-A2AB-11CE-B11F-00AA00530503}';

type
  ITask = interface(IScheduledWorkItem)
  ['{148BD524-A2AB-11CE-B11F-00AA00530503}']
    Function SetApplicationName(pwszApplicationName: LPCWSTR): HRESULT; stdcall;
    Function GetApplicationName(ppwszApplicationName: PLPWSTR): HRESULT; stdcall;
    Function SetParameters(pwszParameters: LPCWSTR): HRESULT; stdcall;
    Function GetParameters(ppwszParameters: PLPWSTR): HRESULT; stdcall;
    Function SetWorkingDirectory(pwszWorkingDirectory: LPCWSTR): HRESULT; stdcall;
    Function GetWorkingDirectory(ppwszWorkingDirectory: PLPWSTR): HRESULT; stdcall;
    Function SetPriority(dwPriority: DWORD): HRESULT; stdcall;
    Function GetPriority(pdwPriority: PDWORD): HRESULT; stdcall;
    Function SetTaskFlags(dwFlags: DWORD): HRESULT; stdcall;
    Function GetTaskFlags(pdwFlags: PDWORD): HRESULT; stdcall;
    Function SetMaxRunTime(dwMaxRunTime: DWORD): HRESULT; stdcall;
    Function GetMaxRunTime(pdwMaxRunTime: PDWORD): HRESULT; stdcall;
  end;


const
  IID_IEnumWorkItems: TGUID = '{148BD528-A2AB-11CE-B11F-00AA00530503}';

type
  PIEnumWorkItems = ^IEnumWorkItems;
  IEnumWorkItems = interface(IUnknown)
  ['{148BD528-A2AB-11CE-B11F-00AA00530503}']
    Function Next(celt: ULONG; rgpwszNames: PPLPWSTR; pceltFetched: PULONG): HRESULT; stdcall;
    Function Skip(celt: ULONG): HRESULT; stdcall;
    Function Reset: HRESULT; stdcall;
    Function Clone(ppEnumWorkItems: PIEnumWorkItems): HRESULT; stdcall;
  end;


const
  IID_ITaskScheduler:     TGUID = '{148BD527-A2AB-11CE-B11F-00AA00530503}';

type
  ITaskScheduler = interface(IUnknown)
  ['{148BD527-A2AB-11CE-B11F-00AA00530503}']
    Function SetTargetComputer(pwszComputer: LPCWSTR): HRESULT; stdcall;
    Function GetTargetComputer(ppwszComputer: PLPWSTR): HRESULT; stdcall;
    Function Enum(ppEnumTasks: PIEnumWorkItems): HRESULT; stdcall;
    Function Activate(pwszName: LPCWSTR; riid: REFIID; ppunk: PIUnknown): HRESULT; stdcall;
    Function Delete(pwszName: LPCWSTR): HRESULT; stdcall;
    Function NewWorkItem(pwszTaskName: LPCWSTR; rclsid: REFCLSID; riid: REFIID; ppunk: PIUnknown): HRESULT; stdcall;
    Function AddWorkItem(pwszTaskName: LPCWSTR; pWorkItem: IScheduledWorkItem): HRESULT; stdcall;
    Function IsOfType(pwszName: LPCWSTR; riid: REFIID): HRESULT; stdcall;
  end;


const
  CLSID_CTask:          TGUID = '{148BD520-A2AB-11CE-B11F-00AA00530503}';
  CLSID_CTaskScheduler: TGUID = '{148BD52A-A2AB-11CE-B11F-00AA00530503}';


type
  _TASKPAGE = (
    TASKPAGE_TASK,
    TASKPAGE_SCHEDULE,
    TASKPAGE_SETTINGS);

  TASKPAGE = _TASKPAGE;

const
  IID_IProvideTaskPage: TGUID = '{4086658a-cbbb-11cf-b604-00c04fd8d565}';

type
  IProvideTaskPage = interface(IUnknown)
  ['{4086658a-cbbb-11cf-b604-00c04fd8d565}']
    Function GetPage(tpType: TASKPAGE; fPersistChanges: BOOL; phPage: PHPROPSHEETPAGE): HRESULT; stdcall;
  end;


type
  ISchedulingAgent = ITaskScheduler;
  IEnumTasks = IEnumWorkItems;

const
  IID_IPersistFile:       TGUID = '{0000010b-0000-0000-C000-000000000046}';
  IID_ISchedulingAgent:   TGUID = '{148BD527-A2AB-11CE-B11F-00AA00530503}';
  CLSID_CSchedulingAgent: TGUID = '{148BD52A-A2AB-11CE-B11F-00AA00530503}';

implementation

end.
