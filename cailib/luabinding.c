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
static int luabinding_GetWeight(lua_State *L);
static int luabinding_Duplicate(lua_State *L);

static const struct {
  char *methodname;
  int (*cfunc)(lua_State *);
} methods[] = {
  {"FeedForward",   luabinding_FeedForward},
  {"TweakWeights",  luabinding_TweakWeights},
  {"GetDimensions", luabinding_GetDimensions},
  {"GetValue",      luabinding_GetValue},
  {"GetWeight",     luabinding_GetWeight},
  {"Duplicate",     luabinding_Duplicate}
};

static NeuralNetwork_T *network_get(lua_State *L, int index) {
  luaL_checktype(L, index, LUA_TUSERDATA);
  return *(NeuralNetwork_T **)lua_touserdata(L, index);
}

static void network_assert_layer(lua_State *L, NeuralNetwork_T *network, 
                                 int layer) {
  if (layer < 0 || layer >= network->layer_count) {
    lua_pushstring(L, "nnlib error: layer index out of bounds");
    lua_error(L);
  }
}

static void network_assert_neuron(lua_State *L, NeuralNetwork_T *network,
                                  int layer, int neuron_index) {
  network_assert_layer(L, network, layer);
  if (neuron_index < 0 || neuron_index >= network->layers[layer].neuron_count) {
    lua_pushstring(L, "nnlib error: neuron index out of bounds");
    lua_error(L);
  }
}

static void network_assert_axon(lua_State *L, NeuralNetwork_T *network,
                                int layer, int neuron_index,
                                int axon_index) {
  network_assert_neuron(L, network, layer, neuron_index);
  if (axon_index < 0 || axon_index >= network->layers[layer].neurons[neuron_index].axon_count) {
    lua_pushstring(L, "nnlib error: weight index out of bounds");
    lua_error(L);
  }
}

static int network_method_lookup(lua_State *L) {

  NeuralNetwork_T *network = network_get(L, 1);
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
 
  NeuralNetwork_T *network = network_get(L, 1);
  net_free(&network);
  return 0;

}

static int network_newindex(lua_State *L) {
  lua_pushstring(L, "nnlib error: cannot add values to network object");
  lua_error(L);
  return 0;
}

static void network_push_userdata(lua_State *L, NeuralNetwork_T *network) {

  NeuralNetwork_T **userdata = lua_newuserdata(L, sizeof(NeuralNetwork_T *));
  *userdata = network;

  /* setup the metatable */
  lua_newtable(L);
  lua_pushcfunction(L, network_method_lookup);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, network_newindex);
  lua_setfield(L, -2, "__newindex");
  lua_pushcfunction(L, network_garbagecollect);
  lua_setfield(L, -2, "__gc");
  lua_setmetatable(L, -2);

}

static int luabinding_Duplicate(lua_State *L) {
  
  NeuralNetwork_T *network = network_get(L, 1);
  NeuralNetwork_T *copy = net_copy(network);
  network_push_userdata(L, copy);

  return 1;

}

/* returns inputs, outputs, {hidden0, hidden1, ...} */
static int luabinding_GetDimensions(lua_State *L) {

  NeuralNetwork_T *network = network_get(L, 1);

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
  
  NeuralNetwork_T *network = network_get(L, 1);
  unsigned layer = luaL_checknumber(L, 2) - 1;
  unsigned index = luaL_checknumber(L, 3) - 1;
  
  network_assert_neuron(L, network, layer, index);
  lua_pushnumber(L, network->layers[layer].neurons[index].value);

  return 1; 
}

/* given a layer, neuron index and weight index, returns
 * the value of that weight
 *
 * example call: network:GetWeight(1, 2, 3)
 * in this case, the weight of the connection between
 * the second neuron in the input layer and the third
 * neuron in the next layer is returned */
static int luabinding_GetWeight(lua_State *L) {
  
  NeuralNetwork_T *network = network_get(L, 1);
  unsigned layer           = luaL_checknumber(L, 2) - 1;
  unsigned neuron_index    = luaL_checknumber(L, 3) - 1;
  unsigned weight_index    = luaL_checknumber(L, 4) - 1;

  network_assert_axon(L, network, layer, neuron_index, weight_index);
  lua_pushnumber(L, network->layers[layer].neurons[neuron_index].axons[weight_index].weight);

  return 1;

}

/* expects a Lua function as an argument.  the function is mapped
 * to each weight in the network, taking the current weight as
 * an argument.  updates the value of the weight with whatever
 * is returned */
static int luabinding_TweakWeights(lua_State *L) {

  NeuralNetwork_T *network = network_get(L, 1);
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

/* given an array of input values that is the same size as the
 * network's input layer, feeds the data forward and returns
 * the output as a table of numbers */
static int luabinding_FeedForward(lua_State *L) {

  NeuralNetwork_T *network = network_get(L, 1);
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
  for (size_t i = 0; i < network->outputs; i++) {
    lua_pushnumber(L, outputs[i]);
    lua_rawseti(L, -2, i + 1);
  }

  free(inputs);
  free(outputs);

  return 1;
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
  network_push_userdata(L, network);

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
