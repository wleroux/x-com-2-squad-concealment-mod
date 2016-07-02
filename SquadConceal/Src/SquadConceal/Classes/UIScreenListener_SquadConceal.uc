class UIScreenListener_SquadConceal extends UIScreenListener
	Config(SquadConceal);

enum ConcealmentMode
{
	eSquadConcealment,
	eIndividualConcealment,
	eSquandAndIndividualConcealment,
	eNone
};

enum MissionMode
{
	eAllMissions,
	eConcealedMissions
};

var config int TURNS_BEFORE_CONCEALMENT;
var config ConcealmentMode CONCEALMENT_MODE;
var config MissionMode MISSION_MODE;

function OnInit(UIScreen Screen)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	ThisObj = self;
	EventManager = class'X2EventManager'.static.GetEventManager();
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);
}

function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Player PlayerState;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;

	PlayerState = XComGameState_Player(EventSource);
	if( PlayerState.GetTeam() == eTeam_XCom )
	{
		// Do not trigger concealment if the mission did not start in concealment
		if( MISSION_MODE == eConcealedMissions )
		{
			MissionManager = `TACTICALMISSIONMGR;
			MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);
			if( !ActiveMissionSchedule.XComSquadStartsConcealed )
			{
				return ELR_NoInterrupt;
			}
		}

		// Trigger concealment only after the specified number of turns
		if( PlayerState.TurnsSinceEnemySeen >= TURNS_BEFORE_CONCEALMENT)
		{
			if( CONCEALMENT_MODE == eSquadConcealment )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ConcealWhenNotSeen");
				PlayerState.SetSquadConcealmentNewGameState(true, NewGameState);
				`TACTICALRULES.SubmitGameState(NewGameState);
			}
			else if ( CONCEALMENT_MODE == eIndividualConcealment )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ConcealWhenNotSeen");
				SetIndividualConcealment(true, NewGameState, PlayerState.ObjectID);
				`TACTICALRULES.SubmitGameState(NewGameState);
			}
			else if ( CONCEALMENT_MODE == eSquandAndIndividualConcealment )
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ConcealWhenNotSeen");
				SetIndividualConcealment(true, NewGameState, PlayerState.ObjectID);
				PlayerState.SetSquadConcealmentNewGameState(true, NewGameState);
				`TACTICALRULES.SubmitGameState(NewGameState);
			}
			else if ( CONCEALMENT_MODE == eNone )
			{
				// Do nothing.
			}
		}
	}

	return ELR_NoInterrupt;
}


function SetIndividualConcealment(bool bNewConceal, XComGameState NewGameState, int ObjectID)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, NewUnitState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.ControllingPlayer.ObjectID == ObjectID && UnitState.IsIndividuallyConcealed() != bNewConceal )
		{
			NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewUnitState.SetIndividualConcealment(bNewConceal, NewGameState);
			NewGameState.AddStateObject(NewUnitState);
		}
	}
}
