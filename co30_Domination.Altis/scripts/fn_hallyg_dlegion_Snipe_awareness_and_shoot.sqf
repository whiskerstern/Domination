//#define __DEBUG__
#define THIS_FILE "fn_hallyg_dlegion_Snipe_awareness_only.sqf"
#include "..\x_setup.sqf"

#define EYE_HEIGHT 1.53

params ["_unit", "_targetSide", "_distanceThreshold"];

//by HallyG, dlegion
private _isLOS = {
	params ["_looker", "_target", "_FOV"];

	if ([position _looker, getDir _looker, _FOV, position _target] call BIS_fnc_inAngleSector) then {
		_lineIntersections = lineIntersectsSurfaces [(AGLtoASL (_looker modelToWorldVisual (_looker selectionPosition "pilot"))), getPosASL _target, _target, _looker, true, 1,"GEOM","NONE"];
		if (count (_lineIntersections) > 0) exitWith {
			false
		};
		true
	} else {
		false
	};
};

//by Jezuro
private _sortArrayByDistance = {
	params ["_unitArray", "_fromPosition"];
	_unsorted = _unitArray;
	_sorted = [];
	_pos = _fromPosition;

	{
		_closest = _unsorted select 0;
		{if ((getPos _x distance _pos) < (getPos _closest distance _pos)) then {_closest = _x}} forEach _unsorted;
		_sorted pushBack _closest;
		_unsorted = _unsorted - [_closest]
	} forEach _unsorted;

	_sorted
};

//by sarogahtyp
private _isVisible = {
	params ["_unit", "_target"];
	_visibleThreshold = 0.015;
	_targetEye = eyepos _target;
	_unitEye = eyepos _unit;

	//vector origins are half meter away from looker and target (uses 0.5 of a normalized vector which by definition is 1 meter)
	_unit_in_dir = _unitEye vectorAdd ((_unitEye vectorFromTo _targetEye) vectorMultiply 0.5);
	_target_in_dir = _targetEye vectorAdd ((_targetEye vectorFromTo _unitEye) vectorMultiply 0.5);

	_visiblity = parseNumber str ([objNull, "VIEW"] checkVisibility [_target_in_dir, _unit_in_dir]);

	if (_visiblity > _visibleThreshold) then {
		true
	} else {
		false
	};
};

//in meters
_detectionRadius = 2000;

//sniper aware loop
while {true} do {
	sleep ((ceil random 5) max 3);
	
	_Dtargets = [];

	{
		if (alive _x && {_x isKindOf "CAManBase" && {!(vehicle _unit isKindOf "Air") && {side _x == _targetSide && {_x distance2D _unit < _detectionRadius}}}}) then {
			_unit reveal [_x, 4];
			_Dtargets pushBack _x;
		};
	} forEach (_unit nearEntities 1400);
	
	if (count _Dtargets > 0) then {
		_playersSortedByDistance = [_Dtargets, getPos _unit] call _sortArrayByDistance;
		_nearestTargetPlayer = _playersSortedByDistance select 0;
		
		
		
		
		_fired = false;
		{
			if (([_unit, _x] call _isVisible) || {[_unit, _x, 360] call _isLOS}) then {
				//to check if unit actually fired
				_ammoCount = _unit ammo primaryWeapon _unit;
				_unit doTarget _x;
				_unit doSuppressiveFire _x;
				//_unit forceWeaponFire [(currentWeapon _unit), "Single"];
				//sleep 7;
				if (_ammoCount > _unit ammo primaryWeapon _unit) then {
					//yes the unit actually fired
					_fired = true;
					_lastFired = time;
				};
			};
		} forEach ([_Dtargets, getPos _unit] call _sortArrayByDistance);
	
		sleep 1;
	
		if (_fired) then {
			//_unit setVehicleAmmo 1;
		} else {
				        	
			if (_nearestTargetPlayer distance2D _unit < _distanceThreshold) then {
				_unit doMove (position _nearestTargetPlayer);
			};
			
		};
	};
	
};