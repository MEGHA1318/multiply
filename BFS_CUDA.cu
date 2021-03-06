#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>


//This Function is used to check for errors in the program.

inline cudaError_t checkCuda(cudaError_t result)
{
#if defined(DEBUG) || defined(_DEBUG)
	if (result != cudaSuccess) {
		fprintf(stderr, "CUDA Runtime Error is : %s\n", cudaGetErrorString(result));
		exit(-1);
	}
#endif
	return result;
}

// will define the number of Vertices
#define vertices 10

// will define the number of Edges per Vertex
#define Edge_per_node 7


//Setting a value to infinity
#define infinity 50

_global__ void Initializing( int *mask_array, int Source) // CUDA kernel
{
	int id = blockIdx.x*blockDim.x + threadIdx.x; // Get global thread ID
	if (id < vertices)
	{
		if (id == Source)
		{
			mask_array[id] = 0;
		}
		else
		{
			mask_array[id] = 0;
		}
	}
}

__global__ void Minimum(int *mask_array, int *vertex_array,  int *edge_array,  int *min)
{
	int id = blockIdx.x*blockDim.x + threadIdx.x; // Get global thread ID
	if (id < vertices)
	{
		if (mask_array[id] != 1 )
		{
			atomicMin(&min[0]);
		}
	}
}

__global__ void Relax(int *mask_array, int *vertex_array, int *edge_array,  int *min)
{
	int id = blockIdx.x*blockDim.x + threadIdx.x; // Get global thread ID

	int m, n;

	if (id < vertices)
	{
		if (mask_array[id] != 1)
		{
			mask_array[id] = 1;
			for (m = id * Edge_per_node;m < id*Edge_per_node + Edge_per_node;m++)
			{
				n = edge_array[m];
				
			}
		}
	}
}


int main(int argc, char* argv[])
{

	size_t vertex_array_size = vertices * sizeof(int);

	size_t edge_array_size = vertices * Edge_per_node * sizeof(int);

	int *vertex_array = (int*)malloc(vertex_array_size);

	int *vertex_copy = (int*)malloc(vertex_array_size);

	int *edge_array = (int*)malloc(edge_array_size);

	int *mask_array = (int*)malloc(vertex_array_size);

	int i, j, k;

	printf("Initializing Verte Array...\n");

	for (i = 0;i < vertices;i++)
	{
		vertex_array[i] = i;
	}

	int temp;

	printf("Initializing Edge Array...\n");

	memcpy(vertex_copy, vertex_array, vertex_array_size);
	for (i = 0;i < vertices;i++)
	{
		for (j = vertices - 1;j > 0;j--)
		{
			k = rand() % (j + 1);
			temp = vertex_copy[j];
			vertex_copy[j] = vertex_copy[k];
			vertex_copy[k] = temp;
		}

		for (j = 0;j < Edge_per_node;j++)
		{
			if (vertex_copy[j] == i)
			{
				j = j + 1;
				edge_array[i*Edge_per_node + (j - 1)] = vertex_copy[j];
			}
			else
			{
				edge_array[i*Edge_per_node + j] = vertex_copy[j];
			}
		}

	}



	int *gpu_vertex_array;
	int *gpu_edge_array;
	int *gpu_mask_array;

	checkCuda(cudaMalloc(&gpu_vertex_array, vertex_array_size));
	checkCuda(cudaMalloc(&gpu_mask_array, vertex_array_size));
	checkCuda(cudaMalloc(&gpu_edge_array, edge_array_size));

	checkCuda(cudaMemcpy(gpu_vertex_array, vertex_array, vertex_array_size, cudaMemcpyHostToDevice));
	checkCuda(cudaMemcpy(gpu_mask_array, mask_array, vertex_array_size, cudaMemcpyHostToDevice));
	checkCuda(cudaMemcpy(gpu_edge_array, edge_array, edge_array_size, cudaMemcpyHostToDevice));

	int blockSize, gridSize;
	blockSize = 1024;
	gridSize = (int)ceil((float)vertices / blockSize); // Number of thread blocks in grid

	
	int *gpu_min;
	checkCuda(cudaMalloc((void**)&gpu_min, 2 * sizeof(int)));

	while (min[0] < infinity)
	{
		min[0] = infinity;
		checkCuda(cudaMemcpy(gpu_min, min, sizeof(int), cudaMemcpyHostToDevice));

		Minimum << <gridSize, blockSize >> > (gpu_mask_array, gpu_vertex_array, , gpu_edge_array, gpu_min);
		if (err != cudaSuccess) checkCuda(cudaMemcpy( vertex_array_size, cudaMemcpyDeviceToHost));
		{
			printf("Error: %s\n", cudaGetErrorString(err));
		}

		Relax << <gridSize, blockSize >> > (gpu_mask_array, gpu_vertex_array, gpu_edge_array, gpu_min);
		if (err != cudaSuccess) checkCuda(cudaMemcpy(vertex_array_size, cudaMemcpyDeviceToHost));
		{
			printf("Error: %s\n", cudaGetErrorString(err));
		}
		checkCuda(cudaMemcpy(vertex_array_size, cudaMemcpyDeviceToHost));

		

		checkCuda(cudaMemcpy(min, gpu_min, 2 * sizeof(int), cudaMemcpyDeviceToHost));
	}

	
	
	
	cudaFree(gpu_vertex_array);
	cudaFree(gpu_edge_array);
	cudaFree(gpu_mask_array);

	free(vertex_array);
	free(edge_array);
	free(mask_array);

	return 0;
}
