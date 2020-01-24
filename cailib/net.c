#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "net.h"

static double activation(double weighted_sum) {
    return 1.0f/(1.0f + exp(-weighted_sum));
}

static void net_print(NeuralNetwork_T *network) {
    for (size_t i = 0; i < network->layer_count; i++) {
        NetworkLayer_T *layer = &network->layers[i];
        printf("==> ");
        for (size_t j = 0; j < layer->neuron_count; j++) {
            printf("%.2f ", layer->neurons[j].value);
        }
        printf("\n");
        if (i < network->layer_count - 1) {
            for (size_t j = 0; j < layer->neuron_count; j++) {
                Neuron_T *neuron = &layer->neurons[j];
                printf("    \t[");
                for (size_t k = 0; k < neuron->axon_count; k++) {
                    printf("%.2f ", neuron->axons[k].weight); 
                }
                printf("]\n");
            }
        }
    }
}

NeuralNetwork_T *net_make(unsigned inputs, unsigned outputs, 
                          unsigned *hiddens, size_t hidden_count) {
    srand(time(NULL));

    NeuralNetwork_T *network = malloc(sizeof(NeuralNetwork_T));
    assert(network);
    
    network->inputs = inputs;
    network->outputs = outputs;
    network->hidden_count = hidden_count;
    network->layer_count = hidden_count + 2;
    
    /* network makes a copy of the inputted hidden values */
    network->hiddens = malloc(sizeof(unsigned)*hidden_count);
    assert(network->hiddens);
    memcpy(network->hiddens, hiddens, sizeof(unsigned)*hidden_count);

    /* network stores an array of the number of neurons in each layer */
    network->layer_counts = malloc(sizeof(unsigned)*network->layer_count);
    assert(network->layer_counts);
    network->layer_counts[0] = inputs;
    network->layer_counts[network->layer_count - 1] = outputs;
    for (size_t i = 1; i < network->layer_count - 1; i++) {
        network->layer_counts[i] = hiddens[i - 1];
    }

    /* init layers */
    network->layers = malloc(sizeof(NetworkLayer_T)*network->layer_count);
    assert(network->layers);
    network->input_layer = &network->layers[0];
    network->output_layer = &network->layers[network->layer_count - 1];
    for (size_t i = 0; i < network->layer_count; i++) {
        NetworkLayer_T *this_layer = &network->layers[i];
        this_layer->neuron_count = network->layer_counts[i];
        this_layer->neurons = malloc(sizeof(Neuron_T)*network->layer_counts[i]);
        assert(this_layer->neurons);
    }

    /* init neurons and their connections */
    for (size_t i = 0; i < network->layer_count; i++) {
        for (size_t j = 0; j < network->layer_counts[i]; j++) {
            Neuron_T *this_neuron = &network->layers[i].neurons[j];
            this_neuron->parent_layer = &network->layers[i];
            this_neuron->value = 0.0f; 
            if (i < network->layer_count - 1) {
                NetworkLayer_T *next_layer = &network->layers[i + 1];
                this_neuron->axons = malloc(sizeof(Axon_T)*next_layer->neuron_count);
                assert(this_neuron->axons);
                this_neuron->axon_count = next_layer->neuron_count; 
                for (size_t k = 0; k < next_layer->neuron_count; k++) {
                    this_neuron->axons[k].weight = (double)rand()/RAND_MAX;
                    this_neuron->axons[k].from = this_neuron;
                    this_neuron->axons[k].to = &next_layer->neurons[k];
                }
            } else {
                this_neuron->axon_count = 0;
                this_neuron->axons = NULL;
            }
        }
    }

    return network;
}

void net_free(NeuralNetwork_T **networkp) {
  assert(networkp && *networkp);

  NeuralNetwork_T *network = *networkp;

  for (size_t i = 0; i < network->layer_count; i++) {
    NetworkLayer_T *layer = &network->layers[i];
    for (size_t j = 0; j < layer->neuron_count; j++) {
      free(layer->neurons[j].axons);
    }
    free(layer->neurons);
  }

  free(network->layers);
  free(network->hiddens);
  free(network->layer_counts);
  free(network);

  *networkp = NULL;
}

void net_backprop(NeuralNetwork_T *network, double *expected) {
    
    double cost = 0.0f;

    /* calculate errors for output layer */
    for (size_t i = 0; i < network->outputs; i++) {
        Neuron_T *neuron = &network->output_layer->neurons[i];
        neuron->err = expected[i] - neuron->value;
        cost += 0.50f*neuron->err*neuron->err;
    }
    
    /* back propogate and calculate errors */
    for (size_t i = network->layer_count - 2; i > 0; i--) {
        NetworkLayer_T *layer = &network->layers[i];
        for (size_t j = 0; j < layer->neuron_count; j++) {
            Neuron_T *neuron = &layer->neurons[j];
            double my_err = 0.0f;
            for (size_t k = 0; k < neuron->axon_count; k++) {
                Axon_T *axon = &neuron->axons[k];
                my_err += axon->weight*axon->to->err; 
            }
            neuron->err = my_err;
        }
    }

    /* now correct the weights */
    for (size_t i = 1; i < network->layer_count; i++) {
        NetworkLayer_T *layer = &network->layers[i];
        for (size_t j = 0; j < layer->neuron_count; j++) {

        }
    }

}

double *net_feed_forward(NeuralNetwork_T *network, double *inputs, size_t input_count) {
    
    /* make sure the inputs are of the right size */
    assert(input_count == network->inputs);

    /* load the inputs into the first layer */
    for (size_t i = 0; i < network->inputs; i++) {
        network->layers[0].neurons[i].value = inputs[i];
    }

    double *outputs = malloc(sizeof(double)*network->outputs);
    assert(outputs);

    /* main feed forward function */
    for (size_t i = 1; i < network->layer_count; i++) {
        NetworkLayer_T *this_layer = &network->layers[i];
        NetworkLayer_T *prev_layer = &network->layers[i - 1];
        for (size_t j = 0; j < this_layer->neuron_count; j++) {
            Neuron_T *this_neuron = &this_layer->neurons[j];
            double weighted_sum = 0.0f;
            for (size_t k = 0; k < prev_layer->neuron_count; k++) {
                Neuron_T *prev_neuron = &prev_layer->neurons[k];
                weighted_sum += prev_neuron->value*prev_neuron->axons[j].weight;
            }
            this_neuron->value = activation(weighted_sum);
        }
    }

    /* load up output array */
    for (size_t i = 0; i < network->outputs; i++) {
        outputs[i] = network->output_layer->neurons[i].value;
    }

    return outputs;

}
