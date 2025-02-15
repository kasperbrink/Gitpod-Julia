using Pkg; Pkg.activate("my_MLJ_env", shared=true)
using Pkg
Pkg.activate("MLJ_tour", shared=true)
Pkg.add("MLJ")
Pkg.add("MLJIteration")
Pkg.add("EvoTrees")

using MLJ
Booster = @load EvoTreeRegressor # loads code defining a model type
booster = Booster(max_depth=2)   # specify hyper-parameter at construction
booster.nrounds=50 
using MLJIteration
iterated_booster = IteratedModel(model=booster,
                                 resampling=Holdout(fraction_train=0.8),
                                 controls=[Step(2), NumberSinceBest(3), NumberLimit(300)],
                                 measure=l1,
                                 retrain=true)

pipe = @pipeline ContinuousEncoder iterated_booster

max_depth_range = range(pipe,
                        :(deterministic_iterated_model.model.max_depth),
                        lower = 1,
                        upper = 10)

self_tuning_pipe = TunedModel(model=pipe,
                        tuning=RandomSearch(),
                        ranges = max_depth_range,
                        resampling=CV(nfolds=3, rng=456),
                        measure=l1,
                        acceleration=CPUThreads(),
                        n=50)
X, y = @load_reduced_ames;
mach = machine(self_tuning_pipe, X, y)
evaluate!(mach,
                 measures=[l1, l2],
                 resampling=CV(nfolds=5, rng=123),
                 acceleration=CPUThreads(),
                 verbosity=2)