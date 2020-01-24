#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include "net.h"

/* functions exposed to Love2D */
static int luabinding_CreateNetwork(lua_State *L);
static int luabinding_FeedForward(lua_State *L);
static int luabinding_TweakWeights(lua_State *L);
static int luabinding_GetDimensions(lua_State *L);
static int luabinding_GetValue(lua_State *L);

static const struct {
  char *methodname;
  int (*cfunc)(lua_State *);
} methods[] = {
  {"FeedForward",   luabinding_FeedForward},
  {"TweakWeights",  luabinding_TweakWeights},
  {"GetDimensions", luabinding_GetDimensions},
  {"GetValue",      luabinding_GetValue}
};

static NeuralNetwork_T *get_network(lua_State *L, int index) {
    luaL_checktype(L, index, LUA_TUSERDATA);
    return *(NeuralNetwork_T **)lua_touserdata(L, index);
}

/* returns inputs, outputs, {hidden0, hidden1, ...} */
static int luabinding_GetDimensions(lua_State *L) {

  NeuralNetwork_T *network = get_network(L, 1);

  lua_pushinteger(L, network->inputs);
  lua_pushinteger(L, network->outputs);
  lua_newtable(L);
  for (size_t i = 0; i < network->hidden_count; i++) {
    lua_pushinteger(L, network->hiddens[i]);
    lua_rawseti(L, -2, i + 1);
  }

  return 3;

}

/* given a layer and a neuron index, returns that neuron's value */
static int luabinding_GetValue(lua_State *L) {
  
  NeuralNetwork_T *network = get_network(L, 1);
  unsigned layer = luaL_checknumber(L, 2) - 1;
  unsigned index = luaL_checknumber(L, 3) - 1;

  if (layer < 0 || layer >= network->layer_count) {
    lua_pushstring(L, "nnlib error: layer out of bounds");
    lua_error(L);
  }

  if (index < 0 || index >= network->layers[layer].neuron_count) {
    lua_pushstring(L, "nnlib error: neuron index out of bounds");
    lua_error(L);
  }

  lua_pushnumber(L, network->layers[layer].neurons[index].value);

  return 1; 
}

static int luabinding_TweakWeights(lua_State *L) {

  NeuralNetwork_T *network = get_network(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);

  /* apply the lua function to each weight */
  for (size_t i = 0; i < network->layer_count - 1; i++) {
    for (size_t j = 0; j < network->layer_counts[i]; j++) {
      Neuron_T *neuron = &network->layers[i].neurons[j];
      for (size_t k = 0; k < neuron->axon_count; k++) {
        Axon_T *axon = &neuron->axons[k];
        lua_pushvalue(L, 2);
        lua_pushnumber(L, axon->weight);
        lua_call(L, 1, 1);
        axon->weight = (double)lua_tonumber(L, -1);
        lua_pop(L, 1);
      }
    }
  }

  return 0;

}

static int luabinding_FeedForward(lua_State *L) {

  NeuralNetwork_T *network = get_network(L, 1);
  luaL_checktype(L, 2, LUA_TTABLE);

  if (lua_objlen(L, 2) != network->inputs) {
    lua_pushstring(L, "nnlib error: Invalid number of inputs to network.");
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

  NeuralNetwork_T *network = get_network(L, 1);
  const char *key = luaL_checkstring(L, 2); 
  
  for (size_t i = 0; i < sizeof(methods)/sizeof(methods[0]); i++) {
    if (!strcmp(key, methods[i].methodname)) {
      lua_pushcfunction(L, methods[i].cfunc);
      return 1;
    }
  }

  return 0;
}

static int network_garbagecollect(lua_State *L) {
 
  NeuralNetwork_T *network = get_network(L, 1);
  net_free(&network);
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
  hidden_count = lua_objlen(L, 3);
  
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
  lua_pushcfunction(L, network_garbagecollect);
  lua_setfield(L, -2, "__gc");
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
