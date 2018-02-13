@everywhere function sigmoid{T}(val::T)
    ewise(/, 1.0, (1.0 + ewise(exp,-val)))
end

# ---- neural network parameters are stored in JSON with type tags
import JSON

@everywhere function write_neural_network(parameters::Dict, fname::String)
    typed_parameters = Dict{String,Any}()
    for key in keys(parameters)
        value = parameters[key]
        type_string = string(typeof(value))
        typed_parameters[key] = Dict("value" => value, "type" => type_string)
    end
    json = JSON.json(typed_parameters)
    open(fname, "w") do f
        write(f, json)
    end
end

function load_neural_network(fname::String)
    json = open(fname, "r") do f
        readstring(f)
    end
    data = JSON.parse(json)
    parameters = Dict{String,Any}()
    for key in keys(data)
        value = data[key]["value"]
        type_string = data[key]["type"]
        parameters[key] = convert(eval(parse(type_string)), value)
    end
    return parameters 
end

import Base.convert

@everywhere function convert(::Type{Matrix{Float64}}, arr::Array{Any,1})
    # JSON stores the matrix in column major format
    num_cols = length(arr)
    num_rows = length(arr[1])
    mat = zeros(num_rows, num_cols)
    for i=1:num_rows
        for j=1:num_cols
            mat[i, j] = arr[j][i]
        end
    end
    mat
end

@everywhere function convert(::Type{Vector{Float64}}, arr::Array{Any,1})
    num_rows = length(arr)
    vec = zeros(num_rows)
    for i=1:num_rows
        vec[i] = arr[i]
    end
    vec
end

function testit()
    params = Dict()
    params["a"] = rand(2, 2)
    params["b"] = rand(2)
    params["c"] = rand()
    println("before:")
    println(params)
    write_neural_network(params, "test.json")
    loaded = load_neural_network("test.json")
    println("after:")
    println(loaded)
    @assert params == loaded
end

#testit()


# ---- generic amortized inference training procedure


@everywhere struct ADAMParameters
    alpha::Float64
    beta_1::Float64
    beta_2::Float64
    epsilon::Float64
end

function adam_optimize!(objective::Function, gradient::Function,
                         current_parameter_values::Dict, params::ADAMParameters, max_iter::Int)
    # gradient ascent
    # current_parameter_values is a dictionary mapping Strings to scalars or arrays
    m = Dict{Any,Any}()
    v = Dict{Any,Any}()
    for key in keys(current_parameter_values)
        m[key] = 0. * current_parameter_values[key]
        v[key] = 0. * current_parameter_values[key]
    end
    for t=2:max_iter
        g = gradient(current_parameter_values)
        for key in keys(current_parameter_values)
            m[key] = params.beta_1 * m[key] + (1. - params.beta_1) * g[key]
            v[key] = params.beta_2 * v[key] + (1. - params.beta_2) * (g[key] .* g[key])
            mhat = m[key] / (1. - params.beta_1^t)
            vhat = v[key] / (1. - params.beta_2^t)
            current_parameter_values[key] += params.alpha * mhat ./ (sqrt.(vhat + params.epsilon))
        end
        f = objective(current_parameter_values)
    	println("t: $t, f: $f")
    end
end

@everywhere struct TrainingParams
    minibatch_size::Int
    max_iter::Int
    num_eval::Int
    adam_params::ADAMParameters
end

@everywhere struct AmortizedInferenceScheme
	model_trace_generator::Function
	inference_program::ProbabilisticProgram
	inference_input_constructor::Function
	inference_constrainer::Function
end

function train(scheme::AmortizedInferenceScheme,
			   initial_inference_parameters::Dict{String,Any},
			   training_params::TrainingParams)

	# compute the gradient for a single sample
    function gradient_single_sample(i::Int, current_inference_parameters::Dict{String,Any},
                                    scheme::AmortizedInferenceScheme)

		# generate a model trace, which serves a training datum
        model_trace = scheme.model_trace_generator()
		
		# set the values of the inference parameters in the inference trace
        inference_trace = ProgramTrace()
        for key in keys(current_inference_parameters)
            parametrize!(inference_trace, key, current_inference_parameters[key])
        end

		# construct the input to hte infernce algorithm from the model trace
        input = scheme.inference_input_constructor(model_trace)

		# constrain the inference algorithm's output using the model trace
        scheme.inference_constrainer(model_trace, inference_trace)

		# execute the inference program
        @generate!(scheme.inference_program(input...), inference_trace)

		# get gradient of inference execution score with respect to inference paramters
        gradient = Dict{String,Any}()
        for key in keys(current_inference_parameters)
            gradient[key] = partial(inference_trace[key])
        end
        return gradient
    end

	# compute the gradient across the a minibatch
    function gradient(current_inference_parameters::Dict{String,Any})

		# parallelize across the minibatch
        gradients = pmap(gradient_single_sample,
						 1:training_params.minibatch_size,
						 [current_inference_parameters for _ in 1:training_params.minibatch_size],
                         [scheme for _ in 1:training_params.minibatch_size])
		
		# accumulate the gradient
        total_gradient = Dict{String,Any}()
        for key in keys(current_inference_parameters)
            for gradient in gradients
                total_gradient[key] = gradient[key]
            end
        end
        return total_gradient
    end

	# evaluate the score for a single sample
    function objective_single_sample(i::Int, inference_trace::Trace,
                                     scheme::AmortizedInferenceScheme)
        model_trace = scheme.model_trace_generator()
        scheme.inference_constrainer(model_trace, inference_trace)
        input = scheme.inference_input_constructor(model_trace)
        return @generate!(scheme.inference_program(input...), inference_trace)[1]
    end
	
	# evaluate the average score for a minibatch of samples
    function objective(current_inference_parameters::Dict{String,Any})

		# set the current values of the inference parameters
        inference_trace = ProgramTrace()
        for key in keys(current_inference_parameters)
            intervene!(inference_trace, key, current_inference_parameters[key])
        end
		
		# sum the scores across an evaluation minibatch
        return sum(pmap(objective_single_sample,
			 	   1:training_params.num_eval,
				   [inference_trace for _ in 1:training_params.num_eval],
                   [scheme for _ in 1:training_params.minibatch_size]))
    end

    # TODO add a stopping condition
	inference_parameters = deepcopy(initial_inference_parameters)
    # mutates inference_parameters
    adam_optimize!(objective, gradient, inference_parameters, training_params.adam_params,
				   training_params.max_iter)
    return inference_parameters

end


# ---- formalism for writing neural networks
#
# 1. the neural network parameters represented in the model program by their
#    initial values, which are labeled with the name of the parameters.
#
# 2. we need to identify certain parameters as those being optimized. to do
#    this, we need to make it so that gradients of the score with respect to these
#    parameters can be computed for a given run of the program. we also need a method for
# 	 setting the values of the parameters to the latest optimized values at each point in the
# 	 optimization, and after optimization is finished.
#
#    to set the parameters, we use intervene!(trace, params). this overrides
#    the default values that these parameters take in the program
#
#    to set the parameters, and make it so the score can be differentiated with
#    respect to them for a given run of the program, we use parametrize!(trace,
#    params)
#
# ---- formalism for amortized inference
# 
# 1. there is a generic amortized inference procedure given above, which utiliizes the 
#    the following abstract components:
#
#        a) model trace generator: something that generates training data. this
#        is likely to be function that returns a model trace stochastically
#        generated from a model program that may be constrained or intervened
#        (since the score of the model program is not used, these are
#        equivalent from the training perspective)
# 
#        b) inference input constructor: a procedure for generating the input
#        to the inference program given the model trace. the input can be the
#        data or context variables
#
#        c) inference constrainer: a procedure that constrains the inference
#        trace (typoically the outputs) to values taken from the model program
#
