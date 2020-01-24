#ifndef NET_H
#define NET_H

#include <stdlib.h>

/* forward decls */
struct Neuron;
struct NetworkLayer;

typedef struct Axon {
    double weight;
    struct Neuron *from;
    struct Neuron *to;
} Axon_T;

typedef struct Neuron {
    double value;
    double err;
    size_t axon_count;
    Axon_T *axons;
    struct NetworkLayer *parent_layer;
} Neuron_T;

typedef struct NetworkLayer {
    size_t neuron_count;
    Neuron_T *neurons;
} NetworkLayer_T;

typedef struct NeuralNetwork {
    unsigned inputs;
    unsigned outputs;
    unsigned *hiddens;
    size_t   hidden_count;
    size_t   layer_count;
    unsigned *layer_counts;
    NetworkLayer_T *layers;
    NetworkLayer_T *input_layer;
    NetworkLayer_T *output_layer;
} NeuralNetwork_T;

NeuralNetwork_T *net_make(unsigned inputs, unsigned outputs, 
                          unsigned *hiddens, size_t hidden_count);
double *net_feed_forward(NeuralNetwork_T *network, double *inputs, size_t input_count);

#endif
