#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include "net.h"

static int luabinding_CreateNetwork(lua_State *L);
static int luabinding_FeedForward(lua_State *L);

static NeuralNetwork_T *get_network(lua_State *L, int index) {
    luaL_checktype(L, index, LUA_TUSERDATA);
    return *(NeuralNetwork_T **)lua_touserdata(L, index);
}

static int luabinding_FeedForward(lua_State *L) {

    NeuralNetwork_T *network = get_network(L, 1);
    luaL_checktype(L, 2, LUA_TTABLE);

    if (lua_rawlen(L, 2) != network->inputs) {
        lua_pushstring(L, "Error: Invalid number of inputs to network.");
        lua_error(L);
    }

    /* load a C array from the lua table input values */
    double *inputs, *input_read;
    inputs = input_read = malloc(sizeof(double)*network->inputs);
    assert(inputs);
    lua_pushnil(L);
    while (lua_next(L, 2) != 0) {
        *input_read++ = lua_tonumber(L, -1);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);

    /* call feed forward */
    double *outputs = net_feed_forward(network, inputs, network->inputs);
    lua_newtable(L);
    for (size_t i = 0; i < network->inputs; i++) {
        lua_pushnumber(L, outputs[i]);
        lua_rawseti(L, -2, i + 1);
    }

    free(inputs);
    free(outputs);

    return 1;
}

static int network_method_lookup(lua_State *L) {

    const char *key;
    NeuralNetwork_T *network;
    
    network = get_network(L, 1);
    key = luaL_checkstring(L, 2); 
    
    if (!strcmp(key, "FeedForward")) {
        lua_pushcfunction(L, luabinding_FeedForward);
        return 1;
    }

    return 0;
}

static int luabinding_CreateNetwork(lua_State *L) {
    
    unsigned inputs, outputs;
    unsigned *hiddens, *hidden_read;
    size_t hidden_count;

    /* read lua arguments */
    inputs = luaL_checknumber(L, 1);
    outputs = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TTABLE);
    hidden_count = lua_rawlen(L, 3);
    
    hiddens = malloc(sizeof(unsigned)*hidden_count);
    assert(hiddens);
    hidden_read = hiddens;
    
    lua_pushnil(L);
    while (lua_next(L, 3) != 0) {
        *hidden_read++ = lua_tointeger(L, -1);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);

    /* lua gets a userdata value that is actually a pointer to out network struct */
    NeuralNetwork_T *network = net_make(inputs, outputs, hiddens, hidden_count);
    NeuralNetwork_T **userdata = lua_newuserdata(L, sizeof(NeuralNetwork_T *));
    *userdata = network;

    /* setup the metatable */
    lua_newtable(L);
    lua_pushcfunction(L, network_method_lookup);
    lua_setfield(L, -2, "__index");
    lua_setmetatable(L, -2);

    /* the network library makes a copy of the hidden 
     * layer counts, so free the one we just allocated */
    free(hiddens);
    
    return 1;
}

int luaopen_nnlib(lua_State *L) {
    lua_newtable(L);
    lua_pushstring(L, "CreateNetwork");
    lua_pushcfunction(L, luabinding_CreateNetwork);
    lua_settable(L, -3);
    return 1;
}
