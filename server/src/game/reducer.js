import { List, Map } from 'immutable'

import {STATE_WAITING_PLAYERS
	   , STATE_PLAY
	   , STATE_ROUNDOVER
	   , DEFAULT_PLAYER
	   , update
       , STATE_COOLDOWN_OVER } from './core'

import { UPDATE
	   , ADD_PLAYER
	   , REMOVE_PLAYER
	   , SET_DIRECTION
       , CLEAR_POSITIONS
       , END_COOLDOWN } from './action_creators'
       

const DEFAULT_GAME = Map({
	players: [], 
    sequence: 0
})       


export default function reducer(state = DEFAULT_GAME, action) {
    switch(action.type) {
        case UPDATE:
            return update(action.delta, action.gamearea, state)
            
        case ADD_PLAYER:
            if (state.get('state') === STATE_WAITING_PLAYERS) {
                return state.setIn(['players', action.id], DEFAULT_PLAYER.set('color', action.color))
            }
            
            return state
			            
        case REMOVE_PLAYER:
			return state.deleteIn(['players'], action.id)
            
        case SET_DIRECTION:            
            if (!state.getIn(['players', action.id])) {
                return state
            }
            
            console.log('server seq-player seq ', (action.sequence-state.get('sequence')))
            
            return state
                    .setIn(['players', action.id, 'sequence'], action.sequence)
                    .setIn(['players', action.id, 'direction'], action.direction)
            
            
        case CLEAR_POSITIONS:
            const players = state.get('players').map(p => {
                return p.set('latestPositions', List())
                        .set('puncture', 0)
                        .set('sequence', -1)
            })
            
            return state.set('players', players)
            
        case END_COOLDOWN:
            return state.set('state', STATE_COOLDOWN_OVER)
            
        default:
            return state
            
    }
}